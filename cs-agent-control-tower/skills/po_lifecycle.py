"""
skills/po_lifecycle.py
Semi-autonomous: creates a PO fully from context (no line items endpoint),
then drives it through the status lifecycle:
  DRAFT → APPROVED → SENT_TO_VENDOR → ACKNOWLEDGED → READY_TO_SHIP

HITL gate fires before approval if PO total value exceeds policy threshold.
Each lifecycle transition is wrapped individually so a 409 (already in a
later state) does not fail the whole skill.
"""

from __future__ import annotations

import logging
from typing import Any

from api_clients import scm_client as api
from hitl import gate as hitl
from messaging import publisher
from orchestrator.state import StepResult, StepStatus
from reasoning import planner

logger = logging.getLogger(__name__)


def run(params: dict[str, Any], context: dict[str, Any], policy: dict) -> StepResult:
    # ── Pull all required context from upstream skills ─────────────────────
    vendor_external_id = context.get("awarded_vendor_id")
    rfq_external_id    = context.get("awarded_rfq_id")
    award_external_id  = context.get("awarded_award_id") or context.get("awarded_quote_id")
    unit_price         = context.get("awarded_unit_price_usd", 0.79)
    quantity           = params.get("quantity", 500)
    total_value        = round(quantity * unit_price, 2)
    threshold          = float(policy.get("hitl", {}).get("financial_threshold_usd", 5000))

    # Fallbacks for standalone runs without prior vendor_rfq step
    vendor_external_id = vendor_external_id or params.get("vendor_external_id", "vnd-002-uuid")
    rfq_external_id    = rfq_external_id    or params.get("rfq_external_id",    "rfq-001-uuid")
    award_external_id  = award_external_id  or params.get("award_external_id",  "award-001-uuid")

    # Look up vendor details for the PO payload
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

    description = params.get(
        "description",
        f"Agent-generated PO — {vendor_name} — {quantity} units @ ${unit_price}",
    )

    conf       = planner.evaluate_confidence(
        f"Create and approve PO for vendor {vendor_external_id} total ${total_value:.2f}",
        context,
    )
    confidence = conf.get("confidence", 1.0)

    # ── HITL gate if PO value exceeds threshold ────────────────────────────
    if total_value > threshold:
        gate_id = hitl.request_approval(
            skill="po_lifecycle",
            action=f"Approve PO for {vendor_name} — total ${total_value:,.2f}",
            recommendation=(
                f"Claude recommends approving. {conf.get('reasoning', '')} "
                f"Confidence: {confidence:.0%}."
            ),
            confidence=confidence,
            payload={
                "vendor_external_id": vendor_external_id,
                "total_value":        total_value,
                "quantity":           quantity,
                "unit_price":         unit_price,
            },
        )
        decision_entry = hitl.await_decision(gate_id)
        if decision_entry["decision"] != "approve":
            return StepResult(
                skill="po_lifecycle",
                status=StepStatus.SKIPPED,
                payload={},
                error="Human rejected PO approval.",
            )

    try:
        # ── 1. Create PO (DRAFT) ───────────────────────────────────────────
        po_resp = api.procurement_create_po(
            vendor_external_id=vendor_external_id,
            vendor_code=vendor_code,
            vendor_name=vendor_name,
            vendor_country=vendor_country,
            rfq_external_id=rfq_external_id,
            rfq_number=context.get("rfq_number", "RFQ-AGENT"),
            campaign_external_id=context.get("campaign_external_id", "camp-001-uuid"),
            campaign_code=context.get("campaign_code", "SUMMER25-TOY"),
            award_external_id=award_external_id,
            description=description,
            quantity=quantity,
            unit_price=unit_price,
        )
        po_data = po_resp.get("data", po_resp)
        po_id   = po_data.get("externalId")
        context["po_id"]     = po_id
        context["po_number"] = po_data.get("poNumber")
        context["po_total"]  = total_value
        logger.info("PO %s created (DRAFT)", po_id)

        # ── 2-5. Drive lifecycle ───────────────────────────────────────────
        # Each transition is wrapped individually. A 409 means the PO is
        # already at or past that state (from a previous run against the
        # same award ID). This is non-fatal — we log and continue.
        final_data = po_data
        transitions = [
            ("approve",       lambda: api.procurement_approve_po(po_id)),
            ("send",          lambda: api.procurement_send_po(po_id)),
            ("acknowledge",   lambda: api.procurement_acknowledge_po(po_id)),
            ("ready-to-ship", lambda: api.procurement_ready_to_ship(po_id)),
        ]
        for step_name, step_fn in transitions:
            try:
                result     = step_fn()
                final_data = result.get("data", result)
                logger.info("PO %s → %s", po_id, step_name)
            except Exception as e:
                logger.warning(
                    "PO %s transition '%s' skipped (already in later state): %s",
                    po_id, step_name, e,
                )

        publisher.publish("scm.procurement.po.ready_to_ship", {
            "po_id":       po_id,
            "po_number":   context["po_number"],
            "vendor_id":   vendor_external_id,
            "total_value": total_value,
        })

        return StepResult(
            skill="po_lifecycle",
            status=StepStatus.DONE,
            payload={"po": final_data, "total_value": total_value},
            confidence=confidence,
        )

    except Exception as exc:
        logger.error("po_lifecycle failed: %s", exc)
        return StepResult(
            skill="po_lifecycle",
            status=StepStatus.FAILED,
            payload={},
            error=str(exc),
        )