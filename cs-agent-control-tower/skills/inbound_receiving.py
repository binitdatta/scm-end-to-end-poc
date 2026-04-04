"""
skills/inbound_receiving.py
Fully autonomous: creates ASN and drives the full lifecycle:
  CREATED → SCHEDULED → IN_TRANSIT → ARRIVED → RECEIVED → PUTAWAY_COMPLETED

Publishes scm.wms.inbound.putaway.complete on finish.
Anomaly check on received quantity discrepancies.
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
    po_external_id     = context.get("po_id")     or params.get("po_external_id",    "po-001-uuid")
    po_number          = context.get("po_number")  or params.get("po_number",         "PO-AGENT")
    vendor_external_id = context.get("awarded_vendor_id") or params.get("vendor_external_id", "vnd-002-uuid")
    campaign_ext_id    = context.get("campaign_external_id", "camp-001-uuid")
    campaign_code      = context.get("campaign_code",        "SUMMER25-TOY")
    expected_qty       = params.get("expected_qty", 500)
    received_qty       = params.get("received_qty", expected_qty)
    sku                = params.get("sku",          "TOY-MIXED-001")
    description        = params.get("description", "Mixed Figures — Agent Inbound")
    zone               = params.get("zone",  "ZONE-A")
    aisle              = params.get("aisle", "AISLE-3")
    bin_loc            = params.get("bin",   "BIN-001")

    # Look up vendor details
    try:
        vendors_resp = api.vendor_list_vendors()
        vendors      = vendors_resp if isinstance(vendors_resp, list) \
                       else vendors_resp.get("data", [])
        vendor       = next(
            (v for v in vendors if v.get("externalId") == vendor_external_id), {}
        )
    except Exception:
        vendor = {}

    vendor_code    = vendor.get("vendorCode",  "VND-VN-001")
    vendor_name    = vendor.get("vendorName",  "Ho Chi Minh Playthings Ltd.")
    vendor_country = vendor.get("country",     "VIETNAM")

    try:
        # ── 1. Create ASN ──────────────────────────────────────────────────
        asn_resp = api.wms_inbound_create_asn(
            po_external_id=po_external_id,
            po_number=po_number,
            campaign_external_id=campaign_ext_id,
            campaign_code=campaign_code,
            vendor_external_id=vendor_external_id,
            vendor_code=vendor_code,
            vendor_name=vendor_name,
            vendor_country=vendor_country,
            sku=sku,
            description=description,
            expected_qty=expected_qty,
        )
        asn_data = asn_resp.get("data", asn_resp)
        asn_id   = asn_data.get("externalId")
        context["asn_id"]     = asn_id
        context["asn_number"] = asn_data.get("asnNumber")
        logger.info("ASN %s created (CREATED)", asn_id)

        # ── 2. Schedule dock ───────────────────────────────────────────────
        api.wms_inbound_schedule(asn_id)
        logger.info("ASN %s scheduled (SCHEDULED)", asn_id)

        # ── 3. Mark in transit ─────────────────────────────────────────────
        api.wms_inbound_mark_in_transit(asn_id)
        logger.info("ASN %s in transit (IN_TRANSIT)", asn_id)

        # ── 4. Mark arrived ────────────────────────────────────────────────
        api.wms_inbound_mark_arrived(asn_id)
        logger.info("ASN %s arrived (ARRIVED)", asn_id)

        # ── 5. Receive shipment ────────────────────────────────────────────
        recv_resp = api.wms_inbound_receive(asn_id, received_qty)
        recv_data = recv_resp.get("data", recv_resp)
        accepted  = recv_data.get("acceptedQuantity", received_qty)
        variance  = recv_data.get("varianceQuantity", 0)
        logger.info("ASN %s received — accepted=%d variance=%d", asn_id, accepted, variance)

        if variance != 0:
            publisher.publish("scm.wms.inbound.discrepancy", {
                "asn_id":   asn_id,
                "expected": expected_qty,
                "received": received_qty,
                "variance": variance,
            })

        # ── 6. Putaway ─────────────────────────────────────────────────────
        putaway_resp = api.wms_inbound_putaway(
            asn_id, sku=sku, quantity=accepted,
            zone=zone, aisle=aisle, bin_loc=bin_loc,
        )
        putaway_data = putaway_resp.get("data", putaway_resp)
        logger.info("ASN %s putaway complete (PUTAWAY_COMPLETED)", asn_id)

        publisher.publish("scm.wms.inbound.putaway.complete", {
            "asn_id":       asn_id,
            "po_id":        po_external_id,
            "sku":          sku,
            "qty_putaway":  accepted,
            "zone":         zone,
            "aisle":        aisle,
            "bin":          bin_loc,
            "campaign_code": campaign_code,
        })

        context["inbound_sku"]      = sku
        context["inbound_qty"]      = accepted
        context["inbound_zone"]     = zone
        context["inbound_bin"]      = bin_loc

        return StepResult(
            skill="inbound_receiving",
            status=StepStatus.DONE,
            payload={
                "asn":     asn_data,
                "receipt": recv_data,
                "putaway": putaway_data,
                "variance": variance,
            },
        )

    except Exception as exc:
        logger.error("inbound_receiving failed: %s", exc)
        return StepResult(
            skill="inbound_receiving",
            status=StepStatus.FAILED,
            payload={},
            error=str(exc),
        )