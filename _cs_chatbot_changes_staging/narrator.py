"""
reasoning/narrator.py
After a run completes (or partially completes), Claude narrates what happened
in plain English — suitable for a stakeholder summary or audit log.
"""

from __future__ import annotations

import json
import logging
import os
from typing import Any

import anthropic

from observability.llm_logger import log_llm_call

logger = logging.getLogger(__name__)

_client: anthropic.Anthropic | None = None


def _get_client() -> anthropic.Anthropic:
    global _client
    if _client is None:
        _client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])
    return _client


NARRATOR_SYSTEM = """
You are the narrator for an autonomous SCM agent run.
Write a concise, professional plain-English summary of what happened during
the agent run. Highlight:
- What was executed autonomously
- What required human approval and what the human decided
- Any anomalies or failures
- The overall supply chain health outcome

Tone: factual, confident, suitable for a VP-level stakeholder audience.
Keep it under 300 words. Use bullet points for key outcomes.
"""


def narrate(goal: str, steps: list[dict[str, Any]], context: dict[str, Any]) -> str:
    client = _get_client()
    prompt = f"""
Goal: {goal}

Steps executed:
{json.dumps(steps, indent=2)}

Final context:
{json.dumps(context, indent=2)}

Write the run narrative.
"""
    message = log_llm_call(
        client,
        caller="narrator.narrate",
        model="claude-sonnet-4-6",
        max_tokens=600,
        system=NARRATOR_SYSTEM,
        messages=[{"role": "user", "content": prompt}],
    )
    return message.content[0].text.strip()


ANOMALY_SYSTEM = """
You are an anomaly detector for a supply chain system.
Given a list of recent API responses or system states, identify anything
unexpected: wrong statuses, missing fields, unusual quantities, broken sequences.
Return JSON:
{
  "anomalies": [
    {"severity": "high|medium|low", "description": "...", "recommendation": "..."}
  ],
  "overall_health": "healthy|degraded|critical"
}
Return ONLY valid JSON.
"""


def detect_anomalies(observations: list[dict[str, Any]]) -> dict[str, Any]:
    client = _get_client()
    prompt = f"Observations:\n{json.dumps(observations, indent=2)}"
    message = log_llm_call(
        client,
        caller="narrator.detect_anomalies",
        model="claude-sonnet-4-6",
        max_tokens=600,
        system=ANOMALY_SYSTEM,
        messages=[{"role": "user", "content": prompt}],
    )
    raw = message.content[0].text.strip()
    if raw.startswith("```"):
        raw = raw.split("\n", 1)[1].rsplit("```", 1)[0].strip()
    return json.loads(raw)
