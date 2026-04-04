"""
skills/order_fulfillment.py
Autonomous: seeds OMS inventory from WMS putaway context, then drives
the full store order lifecycle:
  DRAFT → SUBMITTED → ALLOCATED → PICKING

HITL gate fires if available inventory is insufficient for the order.
WMS Outbound and TMS skills handle PICKING → SHIPPED → DELIVERED.
"""

from __future__ import annotations

import logging
from typing import Any

from api_clients import scm_client as api
from hitl import gate as hitl
from messaging import publisher
from orchestrator.state import StepResult, StepStatus

logger = logging.getLogger(__name__)


def run(params: dict[str, Any], context: dict[str, Any], policy: dict) -> StepResult:
    # ── Pull context from upstream skills ──────────────────────────────────
    campaign_external_id = context.get("campaign_external_id", "camp-001-uuid")
    campaign_code        = context.get("campaign_code",        "SUMMER25-TOY")
    sku                  = context.get("inbound_sku")  or params.get("sku",  "TOY-MIXED-001")
    description          = params.get("description",   "Mixed Figures — Spring Promotion")
    qty                  = params.get("qty",           500)
    region_code          = params.get("region_code",   "US-MIDWEST")
    min_safety_stock     = params.get("min_safety_stock", 50)

    # Zone/bin from inbound context for inventory seeding
    zone    = context.get("inbound_zone", "ZONE-A")
    aisle   = context.get("inbound_aisle", "AISLE-3")
    bin_loc = context.get("inbound_bin",  "BIN-001")
    inbound_qty = context.get("inbound_qty", qty)

    try:
        # ── 1. Seed OMS inventory from WMS putaway ─────────────────────────
        # OMS maintains its own inventory view — must be updated after putaway
        api.oms_update_inventory(
            sku=sku,
            campaign_code=campaign_code,
            campaign_external_id=campaign_external_id,
            quantity=inbound_qty,
            zone=zone,
            aisle=aisle,
            bin_loc=bin_loc,
        )
        logger.info("OMS inventory seeded: sku=%s qty=%d", sku, inbound_qty)

        # ── 2. Safety stock check ──────────────────────────────────────────
        if inbound_qty < qty + min_safety_stock:
            gate_id = hitl.request_approval(
                skill="order_fulfillment",
                action=f"Fulfill order for {qty} units of {sku}",
                recommendation=(
                    f"WARNING: Available stock is {inbound_qty} units. "
                    f"Order needs {qty} plus safety stock {min_safety_stock}. "
                    f"Proceed anyway?"
                ),
                confidence=0.4,
                payload={
                    "sku":             sku,
                    "qty":             qty,
                    "available_stock": inbound_qty,
                },
            )
            decision_entry = hitl.await_decision(gate_id)
            if decision_entry["decision"] != "approve":
                return StepResult(
                    skill="order_fulfillment",
                    status=StepStatus.SKIPPED,
                    payload={"available_stock": inbound_qty},
                    error="Insufficient stock — human halted fulfillment.",
                )

        # ── 3. Create store order (DRAFT) ──────────────────────────────────
        order_resp = api.oms_create_order(
            region_code=region_code,
            campaign_code=campaign_code,
            campaign_external_id=campaign_external_id,
            sku=sku,
            description=description,
            quantity=qty,
        )
        order_data = order_resp.get("data", order_resp)
        order_id   = order_data.get("externalId")
        context["order_id"]     = order_id
        context["order_number"] = order_data.get("orderNumber")
        context["order_sku"]    = sku
        context["order_qty"]    = qty
        logger.info("Store order %s created (DRAFT)", order_id)

        # ── 4. Submit (DRAFT → SUBMITTED) ──────────────────────────────────
        api.oms_submit_order(order_id)
        logger.info("Store order %s submitted", order_id)

        # ── 5. Allocate (SUBMITTED → ALLOCATED) ────────────────────────────
        alloc_resp = api.oms_allocate_order(order_id)
        alloc_data = alloc_resp.get("data", alloc_resp)
        qty_allocated = alloc_data.get("quantityAllocated", qty)
        store_count   = len(alloc_data.get("orderLines", []))
        logger.info("Store order %s allocated — %d units across %d stores",
                    order_id, qty_allocated, store_count)

        # ── 6. Mark picking (ALLOCATED → PICKING) ──────────────────────────
        api.oms_mark_picking(order_id)
        logger.info("Store order %s picking started", order_id)

        publisher.publish("scm.oms.order.picking", {
            "order_id":      order_id,
            "order_number":  context["order_number"],
            "sku":           sku,
            "qty_allocated": qty_allocated,
            "store_count":   store_count,
            "region_code":   region_code,
            "campaign_code": campaign_code,
        })

        return StepResult(
            skill="order_fulfillment",
            status=StepStatus.DONE,
            payload={
                "order":         alloc_data,
                "qty_allocated": qty_allocated,
                "store_count":   store_count,
            },
        )

    except Exception as exc:
        logger.error("order_fulfillment failed: %s", exc)
        return StepResult(
            skill="order_fulfillment",
            status=StepStatus.FAILED,
            payload={},
            error=str(exc),
        )