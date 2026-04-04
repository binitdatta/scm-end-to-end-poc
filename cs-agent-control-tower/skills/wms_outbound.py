"""
skills/wms_outbound.py
Autonomous: creates a pick wave and drives the full outbound lifecycle:
  Wave:     CREATED → ASSIGNED → PICKING → COMPLETED
  Shipment: CREATED → PACKED → MANIFESTED → DISPATCHED

Store carton lines are built from the OMS order allocation stored in context.
Publishes scm.wms.outbound.shipment.dispatched on completion.
"""

from __future__ import annotations

import logging
from typing import Any

from api_clients import scm_client as api
from messaging import publisher
from orchestrator.state import StepResult, StepStatus

logger = logging.getLogger(__name__)


def run(params: dict[str, Any], context: dict[str, Any], policy: dict) -> StepResult:
    # ── Pull context from upstream skills ──────────────────────────────────
    order_external_id    = context.get("order_id")     or params.get("order_external_id",    "ord-001-uuid")
    order_number         = context.get("order_number") or params.get("order_number",          "ORD-AGENT")
    campaign_external_id = context.get("campaign_external_id", "camp-001-uuid")
    campaign_code        = context.get("campaign_code",        "SUMMER25-TOY")
    sku                  = context.get("order_sku")  or params.get("sku",   "TOY-MIXED-001")
    description          = params.get("description",  "Mixed Figures — Spring Promotion")
    total_qty            = context.get("order_qty")  or params.get("total_qty", 500)
    region_code          = params.get("region_code",  "US-MIDWEST")
    distribution_dc      = params.get("distribution_dc", "DC-CHICAGO")
    carrier              = params.get("carrier",      "FedEx Freight")

    # Store lines — built from OMS allocation or sensible default
    store_lines = params.get("store_lines") or _default_store_lines(sku, total_qty)

    try:
        # ── 1. Create pick wave ────────────────────────────────────────────
        wave_resp = api.wms_outbound_create_wave(
            order_external_id=order_external_id,
            order_number=order_number,
            campaign_external_id=campaign_external_id,
            campaign_code=campaign_code,
            region_code=region_code,
            sku=sku,
            description=description,
            total_qty=total_qty,
            distribution_dc=distribution_dc,
        )
        wave_data = wave_resp.get("data", wave_resp)
        wave_id   = wave_data.get("externalId")
        context["wave_id"]     = wave_id
        context["wave_number"] = wave_data.get("waveNumber")
        logger.info("Pick wave %s created (CREATED)", wave_id)

        # ── 2. Assign wave ─────────────────────────────────────────────────
        api.wms_outbound_assign_wave(wave_id)
        logger.info("Pick wave %s assigned (ASSIGNED)", wave_id)

        # ── 3. Start picking ───────────────────────────────────────────────
        api.wms_outbound_start_wave(wave_id)
        logger.info("Pick wave %s picking started (PICKING)", wave_id)

        # ── 4. Complete wave ───────────────────────────────────────────────
        api.wms_outbound_complete_wave(wave_id, total_qty)
        logger.info("Pick wave %s completed (COMPLETED)", wave_id)

        # ── 5. Create shipment ─────────────────────────────────────────────
        shipment_resp = api.wms_outbound_create_shipment(
            wave_external_id=wave_id,
            campaign_code=campaign_code,
            region_code=region_code,
            sku=sku,
            distribution_dc=distribution_dc,
            carrier=carrier,
            store_lines=store_lines,
        )
        shipment_data = shipment_resp.get("data", shipment_resp)
        shipment_id   = shipment_data.get("externalId")
        context["shipment_id"]     = shipment_id
        context["shipment_number"] = shipment_data.get("shipmentNumber")
        context["carrier"]         = carrier
        logger.info("Shipment %s created (CREATED)", shipment_id)

        # ── 6. Pack ────────────────────────────────────────────────────────
        api.wms_outbound_pack_shipment(shipment_id)
        logger.info("Shipment %s packed (PACKED)", shipment_id)

        # ── 7. Manifest ────────────────────────────────────────────────────
        api.wms_outbound_manifest_shipment(shipment_id, carrier)
        logger.info("Shipment %s manifested (MANIFESTED)", shipment_id)

        # ── 8. Dispatch ────────────────────────────────────────────────────
        final      = api.wms_outbound_dispatch_shipment(shipment_id)
        final_data = final.get("data", final)
        logger.info("Shipment %s dispatched (DISPATCHED)", shipment_id)

        publisher.publish("scm.wms.outbound.shipment.dispatched", {
            "shipment_id":     shipment_id,
            "shipment_number": context["shipment_number"],
            "wave_id":         wave_id,
            "order_id":        order_external_id,
            "carrier":         carrier,
            "total_units":     total_qty,
            "campaign_code":   campaign_code,
        })

        return StepResult(
            skill="wms_outbound",
            status=StepStatus.DONE,
            payload={
                "wave":     wave_data,
                "shipment": final_data,
            },
        )

    except Exception as exc:
        logger.error("wms_outbound failed: %s", exc)
        return StepResult(
            skill="wms_outbound",
            status=StepStatus.FAILED,
            payload={},
            error=str(exc),
        )


def _default_store_lines(sku: str, total_qty: int) -> list[dict]:
    """Default 4 Midwest stores splitting total quantity evenly."""
    per_store = total_qty // 4
    stores = [
        ("str-001-uuid", "STR-0001", "Burger Bliss Chicago Downtown",  "Chicago",      "IL"),
        ("str-002-uuid", "STR-0002", "Burger Bliss Naperville",         "Naperville",   "IL"),
        ("str-003-uuid", "STR-0003", "Burger Bliss Milwaukee",          "Milwaukee",    "WI"),
        ("str-004-uuid", "STR-0004", "Burger Bliss Indianapolis",       "Indianapolis", "IN"),
    ]
    return [
        {
            "storeExternalId": s[0],
            "storeNumber":     s[1],
            "storeName":       s[2],
            "city":            s[3],
            "stateCode":       s[4],
            "sku":             sku,
            "quantity":        per_store,
        }
        for s in stores
    ]