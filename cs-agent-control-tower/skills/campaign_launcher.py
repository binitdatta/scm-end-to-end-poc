"""
skills/campaign_launcher.py
Autonomous skill: creates and launches a CRM campaign.
Pauses for HITL only if the budget exceeds the policy threshold.
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
    name      = params.get("name", "Spring Promotion Campaign")
    region    = params.get("target_region", "MIDWEST")
    budget    = float(params.get("budget", 25000))
    threshold = float(policy.get("hitl", {}).get("financial_threshold_usd", 5000))

    # ── Confidence check ───────────────────────────────────────────────────
    conf_result = planner.evaluate_confidence(
        f"Create and launch CRM campaign '{name}' with budget ${budget}",
        context,
    )
    confidence = conf_result.get("confidence", 1.0)

    # ── HITL gate if budget exceeds threshold ──────────────────────────────
    if budget > threshold:
        gate_id = hitl.request_approval(
            skill="campaign_launcher",
            action=f"Launch campaign '{name}' with budget ${budget:,.0f}",
            recommendation=(
                f"Claude recommends launching. Confidence: {confidence:.0%}. "
                f"Budget ${budget:,.0f} exceeds threshold ${threshold:,.0f}."
            ),
            confidence=confidence,
            payload={"name": name, "region": region, "budget": budget},
        )
        logger.info("HITL gate opened for campaign (gate_id=%s), waiting…", gate_id)
        decision_entry = hitl.await_decision(gate_id)
        if decision_entry["decision"] != "approve":
            return StepResult(
                skill="campaign_launcher",
                status=StepStatus.SKIPPED,
                payload={},
                error="Human rejected campaign launch.",
            )

    # ── Execute autonomously ───────────────────────────────────────────────
    try:
        campaign_resp = api.crm_create_campaign(name, region, budget)
        campaign_data = campaign_resp.get("data", campaign_resp)
        campaign_id   = campaign_data.get("externalId")
        campaign_code = campaign_data.get("campaignCode")

        launched      = api.crm_launch_campaign(campaign_id)
        launched_data = launched.get("data", launched)

        publisher.publish("scm.crm.campaign.launched", {
            "campaign_id":   campaign_id,
            "campaign_code": campaign_code,
            "name":          name,
            "region":        region,
            "budget":        budget,
        })

        # Store both id and code in context for downstream skills
        context["campaign_id"]          = campaign_id
        context["campaign_external_id"] = campaign_id
        context["campaign_code"]        = campaign_code
        context["campaign_name"]        = name

        logger.info("Campaign %s (%s) launched successfully", campaign_id, campaign_code)

        return StepResult(
            skill="campaign_launcher",
            status=StepStatus.DONE,
            payload={"campaign": campaign_data, "launched": launched_data},
            confidence=confidence,
        )

    except Exception as exc:
        logger.error("campaign_launcher failed: %s", exc)
        return StepResult(
            skill="campaign_launcher",
            status=StepStatus.FAILED,
            payload={},
            error=str(exc),
        )