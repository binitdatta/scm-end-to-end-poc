"""
reasoning/planner.py
Uses Claude (tool-use / structured output) to decompose a natural-language
goal into an ordered list of skill invocations with parameters.
"""

from __future__ import annotations

import json
import logging
import os
from typing import Any

import anthropic

logger = logging.getLogger(__name__)

_client: anthropic.Anthropic | None = None


def _get_client() -> anthropic.Anthropic:
    global _client
    if _client is None:
        _client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    return _client


PLAN_SYSTEM = """
You are the planning brain of an autonomous SCM (Supply Chain Management) agent.

Available skills:
- campaign_launcher    : Create and launch a CRM marketing campaign
- vendor_rfq           : Send RFQs to vendors and score incoming quotes
- po_lifecycle         : Create a Purchase Order, add lines, approve it
- inbound_receiving    : Create ASN, receive goods, putaway into inventory
- order_fulfillment    : Create store order, allocate, confirm
- wms_outbound         : Create pick wave, pick, create shipment, dispatch
- tms_dispatch         : Create load, assign carrier, confirm POD
- anomaly_detector     : Inspect current state and flag anomalies
- nl_query             : Answer a natural-language question about SCM data

Rules:
1. Decompose the goal into the minimum number of skills needed.
2. Order them logically (e.g. you cannot receive goods before creating a PO).
3. For each skill include a short "rationale" and any "params" you can infer.
4. Mark "hitl_candidate: true" for irreversible or high-value actions.
5. Return ONLY valid JSON — no markdown, no prose.

JSON format:
{
  "plan_summary": "one sentence",
  "steps": [
    {
      "step": 1,
      "skill": "skill_name",
      "rationale": "why this step",
      "params": {},
      "hitl_candidate": false
    }
  ]
}
"""


def plan(goal: str) -> dict[str, Any]:
    """Ask Claude to decompose the goal into a skill execution plan."""
    client = _get_client()
    logger.info("Planning goal: %s", goal)

    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=1500,
        system=PLAN_SYSTEM,
        messages=[{"role": "user", "content": f"Goal: {goal}"}],
    )

    raw = message.content[0].text.strip()
    # Strip accidental markdown fences
    if raw.startswith("```"):
        raw = raw.split("\n", 1)[1].rsplit("```", 1)[0].strip()

    result = json.loads(raw)
    logger.info("Plan has %d steps", len(result.get("steps", [])))
    return result


CONFIDENCE_SYSTEM = """
You are the confidence evaluator for an autonomous SCM agent.
Given the current context and the action about to be taken, return a JSON
object with:
  - "confidence": float 0.0-1.0
  - "reasoning": one sentence explanation
  - "risks": list of short risk strings (can be empty)
Return ONLY valid JSON.
"""


def evaluate_confidence(action: str, context: dict[str, Any]) -> dict[str, Any]:
    """Ask Claude to score confidence for the next action."""
    client = _get_client()
    prompt = f"""
Action: {action}
Current context: {json.dumps(context, indent=2)}

Rate confidence for executing this action autonomously.
"""
    message = client.messages.create(
        model="claude-sonnet-4-20250514",
        max_tokens=300,
        system=CONFIDENCE_SYSTEM,
        messages=[{"role": "user", "content": prompt}],
    )
    raw = message.content[0].text.strip()
    if raw.startswith("```"):
        raw = raw.split("\n", 1)[1].rsplit("```", 1)[0].strip()
    return json.loads(raw)
