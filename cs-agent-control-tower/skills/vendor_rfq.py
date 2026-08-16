"""
skills/vendor_rfq.py
Semi-autonomous: sends RFQs and scores quotes autonomously via Claude,
but always pauses before awarding a contract (irreversible financial action).

RFQ lifecycle:
  1. Create RFQ        → status: DRAFT
  2. Open RFQ          → status: OPEN  (required before quotes can be submitted)
  3. Submit quotes     → one per vendor
  4. Claude scores     → picks best quote
  5. HITL gate         → human approves/rejects/overrides
  6. Award contract    → status: AWARDED
"""

from __future__ import annotations

import json
import logging
import os
from typing import Any

import anthropic

from api_clients import scm_client as api
from hitl import gate as hitl
from messaging import publisher
from orchestrator.state import StepResult, StepStatus

logger = logging.getLogger(__name__)


def _score_quotes(quotes: list[dict], context: dict) -> dict:
    """Ask Claude to pick the best quote."""
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    prompt = f"""
You are evaluating vendor quotes for a procurement decision.
Quotes: {json.dumps(quotes, indent=2)}
Context: {json.dumps(context, indent=2)}

Pick the best quote. Consider unit cost, lead time, and vendor reliability.
Use the externalId field as the quote identifier.

Return JSON:
{{
  "recommended_quote_id": "<externalId of best quote>",
  "recommended_vendor_id": "<vendorExternalId of best quote>",
  "rationale": "...",
  "confidence": 0.0-1.0,
  "score_breakdown": [{{"quote_id": "...", "score": ..., "notes": "..."}}]
}}
Return ONLY valid JSON.
"""
    msg = client.messages.create(
        model="claude-sonnet-4-6",
        max_tokens=600,
        messages=[{"role": "user", "content": prompt}],
    )
    raw = msg.content[0].text.strip()
    if raw.startswith("```"):
        raw = raw.split("\n", 1)[1].rsplit("```", 1)[0].strip()
    return json.loads(raw)


def run(params: dict[str, Any], context: dict[str, Any], policy: dict) -> StepResult:
    rfq_title   = params.get("rfq_title", "Q2 Supply RFQ")
    description = params.get("description", "Bulk supply for spring promotion")
    deadline    = params.get("deadline", "2025-06-30")

    try:
        # ── 1. Create RFQ ──────────────────────────────────────────────────
        rfq_resp = api.vendor_create_rfq(
            rfq_title, description, deadline,
            campaign_external_id=context.get("campaign_external_id", "camp-001-uuid"),
            campaign_code=context.get("campaign_code", "SUMMER25-TOY"),
        )
        rfq_data = rfq_resp.get("data", rfq_resp)
        rfq_id   = rfq_data.get("externalId")
        context["rfq_id"] = rfq_id
        logger.info("RFQ %s created (status: DRAFT)", rfq_id)

        # ── 2. Open RFQ (DRAFT → OPEN) ─────────────────────────────────────
        api.vendor_open_rfq(rfq_id)
        logger.info("RFQ %s opened (status: OPEN)", rfq_id)

        # ── 3. Fetch vendors and submit quotes ─────────────────────────────
        vendors_resp = api.vendor_list_vendors()
        vendors = vendors_resp if isinstance(vendors_resp, list) else vendors_resp.get("data", [])

        active_vendors = [v for v in vendors if v.get("status") == "ACTIVE"][:3]

        unit_prices = [0.82, 0.79, 0.88]
        leads       = [45, 38, 55]

        quotes = []
        for i, vendor in enumerate(active_vendors):
            vid = vendor.get("externalId") or vendor.get("id")
            try:
                q_resp = api.vendor_submit_quote(
                    rfq_id, vid, unit_prices[i], leads[i],
                    quantity=rfq_data.get("quantityRequired", 500),
                )
                q = q_resp.get("data", q_resp)
                q["vendorName"]      = vendor.get("vendorName", f"Vendor {vid}")
                q["scorecardRating"] = vendor.get("scorecardRating", 0)
                quotes.append(q)
                logger.info("Quote submitted by vendor %s for RFQ %s", vid, rfq_id)
            except Exception as qe:
                logger.warning("Quote submission failed for vendor %s: %s", vid, qe)

        if not quotes:
            raise RuntimeError("No quotes were successfully submitted for RFQ %s" % rfq_id)

        publisher.publish("scm.vendor.quotes.received", {
            "rfq_id": rfq_id, "quote_count": len(quotes)
        })

        # ── 4. Claude scores the quotes ────────────────────────────────────
        scoring        = _score_quotes(quotes, context)
        best_quote_id  = scoring["recommended_quote_id"]
        best_vendor_id = scoring["recommended_vendor_id"]
        rationale      = scoring["rationale"]
        confidence     = scoring.get("confidence", 0.9)
        logger.info("Claude recommends quote %s (confidence: %.0f%%)", best_quote_id, confidence * 100)

        # ── 5. HITL gate — always required before contract award ───────────
        gate_id = hitl.request_approval(
            skill="vendor_rfq",
            action=f"Award contract on RFQ {rfq_id} to vendor {best_vendor_id}",
            recommendation=f"{rationale} | Confidence: {confidence:.0%}",
            confidence=confidence,
            payload={
                "rfq_id":                rfq_id,
                "recommended_quote_id":  best_quote_id,
                "recommended_vendor_id": best_vendor_id,
                "quotes":                quotes,
                "score_breakdown":       scoring.get("score_breakdown", []),
            },
        )

        decision_entry = hitl.await_decision(gate_id)
        decision       = decision_entry["decision"]

        if decision == "reject":
            return StepResult(
                skill="vendor_rfq",
                status=StepStatus.SKIPPED,
                payload={"rfq_id": rfq_id, "quotes": quotes},
                error="Human rejected contract award.",
            )

        if decision == "override" and decision_entry.get("override_payload"):
            ov             = decision_entry["override_payload"]
            best_quote_id  = ov.get("quote_id",  best_quote_id)
            best_vendor_id = ov.get("vendor_id", best_vendor_id)
            logger.info("Human overrode quote selection: quote=%s vendor=%s",
                        best_quote_id, best_vendor_id)

        # ── 6. Award the contract ──────────────────────────────────────────
        awarded_resp = api.vendor_award_contract(
            rfq_id, best_quote_id,
            vendor_external_id=best_vendor_id,
            quantity=rfq_data.get("quantityRequired", 500),
        )
        awarded = awarded_resp.get("data", awarded_resp)

        publisher.publish("scm.vendor.contract.awarded", {
            "rfq_id":    rfq_id,
            "quote_id":  best_quote_id,
            "vendor_id": best_vendor_id,
        })

        context["awarded_vendor_id"]      = best_vendor_id
        context["awarded_quote_id"]       = best_quote_id
        context["awarded_rfq_id"]         = rfq_id
        context["awarded_award_id"]       = awarded.get("externalId")  # award object's own ID
        context["awarded_unit_price_usd"] = next(
            (q.get("quotedUnitCostUsd") for q in quotes
             if q.get("externalId") == best_quote_id), None
        )

        logger.info("Contract awarded on RFQ %s to vendor %s", rfq_id, best_vendor_id)

        return StepResult(
            skill="vendor_rfq",
            status=StepStatus.DONE,
            payload={"rfq_id": rfq_id, "awarded": awarded, "scoring": scoring},
            confidence=confidence,
        )

    except Exception as exc:
        logger.error("vendor_rfq failed: %s", exc)
        return StepResult(
            skill="vendor_rfq",
            status=StepStatus.FAILED,
            payload={},
            error=str(exc),
        )