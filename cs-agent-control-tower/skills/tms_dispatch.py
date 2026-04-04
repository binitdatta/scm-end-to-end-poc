"""
skills/tms_dispatch.py
Semi-autonomous: creates a delivery load and drives the TMS lifecycle:
  CREATED → ASSIGNED → IN_TRANSIT

Records transit events autonomously.
HITL gate always fires before POD confirmation — legal document.
After human approves, confirms POD for all store deliveries.
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
    shipment_external_id = context.get("shipment_id")     or params.get("shipment_external_id", "shp-001")
    shipment_number      = context.get("shipment_number") or params.get("shipment_number",      "SHP-AGENT")
    order_external_id    = context.get("order_id")        or params.get("order_external_id",    "ord-001")
    order_number         = context.get("order_number")    or params.get("order_number",         "ORD-AGENT")
    campaign_external_id = context.get("campaign_external_id", "camp-001-uuid")
    campaign_code        = context.get("campaign_code",        "SUMMER25-TOY")
    sku                  = context.get("order_sku")  or params.get("sku",   "TOY-MIXED-001")
    description          = params.get("description",  "Mixed Figures - Spring Promotion")
    total_units          = context.get("order_qty")  or params.get("total_units", 500)
    region_code          = params.get("region_code",  "US-MIDWEST")
    distribution_dc      = params.get("distribution_dc", "DC-CHICAGO")
    carrier              = context.get("carrier") or params.get("carrier", "FedEx Freight")
    store_lines          = params.get("store_lines") or _default_store_lines(sku, total_units)
    pro_number           = f"PRO-AGENT-{shipment_number[-6:]}" if shipment_number else "PRO-AGENT-001"

    try:
        # 1. Create load
        load_resp = api.tms_create_load(
            shipment_external_id=shipment_external_id,
            shipment_number=shipment_number,
            order_external_id=order_external_id,
            order_number=order_number,
            campaign_external_id=campaign_external_id,
            campaign_code=campaign_code,
            region_code=region_code,
            distribution_dc=distribution_dc,
            carrier=carrier,
            pro_number=pro_number,
            sku=sku,
            description=description,
            total_units=total_units,
            store_lines=store_lines,
        )
        load_data        = load_resp.get("data", load_resp)
        load_id          = load_data.get("externalId")
        load_number      = load_data.get("loadNumber")
        store_deliveries = load_data.get("storeDeliveries", [])
        context["load_id"]     = load_id
        context["load_number"] = load_number
        logger.info("Load %s created", load_id)

        # 2. Assign driver
        api.tms_assign_driver(load_id)
        logger.info("Load %s assigned", load_id)

        # 3. Mark in transit
        api.tms_mark_in_transit(load_id)
        logger.info("Load %s in transit", load_id)

        # 4. Transit milestones
        try:
            api.tms_record_transit_event(load_id, "DEPARTED_DC",     distribution_dc,  "Departed distribution center")
            api.tms_record_transit_event(load_id, "IN_TRANSIT",      "En route",       "Load in transit to region")
            api.tms_record_transit_event(load_id, "OUT_FOR_DELIVERY", region_code,     "Out for delivery to stores")
        except Exception as te:
            logger.warning("Transit event recording failed (non-fatal): %s", te)

        publisher.publish("scm.tms.load.out_for_delivery", {
            "load_id":     load_id,
            "load_number": load_number,
            "shipment_id": shipment_external_id,
            "region_code": region_code,
            "store_count": len(store_deliveries),
        })

        # 5. HITL gate — always required before POD
        gate_id = hitl.request_approval(
            skill="tms_dispatch",
            action=(
                f"Confirm Proof of Delivery for load {load_number} "
                f"— {len(store_deliveries)} stores"
            ),
            recommendation=(
                f"Load {load_number} is out for delivery to "
                f"{len(store_deliveries)} stores in {region_code}. "
                f"Please verify physical delivery and confirm POD."
            ),
            confidence=1.0,
            payload={
                "load_id":          load_id,
                "load_number":      load_number,
                "shipment_id":      shipment_external_id,
                "region_code":      region_code,
                "store_deliveries": store_deliveries,
                "total_units":      total_units,
            },
        )

        decision_entry = hitl.await_decision(gate_id)
        if decision_entry["decision"] != "approve":
            return StepResult(
                skill="tms_dispatch",
                status=StepStatus.SKIPPED,
                payload={"load_id": load_id},
                error="POD not confirmed by human operator.",
            )

        # 6. Confirm POD for all store deliveries
        pod_results = []
        for delivery in store_deliveries:
            try:
                pod = api.tms_confirm_pod(
                    load_external_id=load_id,
                    store_delivery_external_id=delivery["externalId"],
                    store_number=delivery.get("storeNumber", "STR-0001"),
                    quantity=delivery.get("quantity", total_units // max(len(store_deliveries), 1)),
                )
                pod_results.append(pod.get("data", pod))
                logger.info("POD confirmed for store %s", delivery.get("storeNumber"))
            except Exception as pe:
                logger.warning("POD failed for store %s: %s", delivery.get("storeNumber"), pe)

        publisher.publish("scm.tms.pod.confirmed", {
            "load_id":          load_id,
            "load_number":      load_number,
            "region_code":      region_code,
            "stores_confirmed": len(pod_results),
            "total_units":      total_units,
            "campaign_code":    campaign_code,
        })

        context["pod_confirmed"]    = True
        context["stores_pod_count"] = len(pod_results)
        logger.info("Load %s — POD confirmed for %d stores", load_id, len(pod_results))

        return StepResult(
            skill="tms_dispatch",
            status=StepStatus.DONE,
            payload={"load": load_data, "pod_results": pod_results},
        )

    except Exception as exc:
        logger.error("tms_dispatch failed: %s", exc)
        return StepResult(
            skill="tms_dispatch",
            status=StepStatus.FAILED,
            payload={},
            error=str(exc),
        )


def _default_store_lines(sku: str, total_qty: int) -> list[dict]:
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