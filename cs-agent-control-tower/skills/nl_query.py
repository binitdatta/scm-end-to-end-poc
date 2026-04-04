"""
skills/nl_query.py
AI-powered: translates a natural-language question into REST API calls,
executes them, and returns a narrative answer — the evolved chatbot skill.
"""

from __future__ import annotations

import json
import logging
import os
from typing import Any

import anthropic

from api_clients import scm_client as api
from orchestrator.state import StepResult, StepStatus

logger = logging.getLogger(__name__)

SYSTEM = """
You are an SCM data query agent. Given a natural-language question, determine
which of the following data sources to query and what to compute:

Available data fetchers (call by name):
  - crm_list_campaigns
  - vendor_list_vendors
  - wms_inbound_list_inventory
  - oms_list_regions

Steps:
1. Decide which fetchers to call (can be multiple).
2. Return a JSON plan:
   {"fetchers": ["name1", "name2"], "computation": "what to do with the data"}
Return ONLY valid JSON for the plan.
"""

NARRATE_SYSTEM = """
You are an SCM analyst. Given a question and raw data from multiple API sources,
produce a concise, plain-English answer. Be specific — include numbers, names,
and statuses where available. Keep the answer under 150 words.
"""

_FETCHER_MAP = {
    "crm_list_campaigns":       api.crm_list_campaigns,
    "vendor_list_vendors":      api.vendor_list_vendors,
    "wms_inbound_list_inventory": api.wms_inbound_list_inventory,
    "oms_list_regions":         api.oms_list_regions,
}


def run(params: dict[str, Any], context: dict[str, Any], policy: dict) -> StepResult:
    question = params.get("question", "What is the current inventory level?")
    client = anthropic.Anthropic(api_key=os.environ["ANTHROPIC_API_KEY"])

    try:
        # Step 1: Claude plans which APIs to call
        plan_msg = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=300,
            system=SYSTEM,
            messages=[{"role": "user", "content": f"Question: {question}"}],
        )
        raw = plan_msg.content[0].text.strip()
        if raw.startswith("```"):
            raw = raw.split("\n", 1)[1].rsplit("```", 1)[0].strip()
        plan = json.loads(raw)

        # Step 2: Execute the fetchers
        gathered: dict[str, Any] = {}
        for fetcher_name in plan.get("fetchers", []):
            fn = _FETCHER_MAP.get(fetcher_name)
            if fn:
                try:
                    gathered[fetcher_name] = fn()
                except Exception as e:
                    gathered[fetcher_name] = {"error": str(e)}

        # Step 3: Claude narrates the answer
        narrate_msg = client.messages.create(
            model="claude-sonnet-4-20250514",
            max_tokens=300,
            system=NARRATE_SYSTEM,
            messages=[{
                "role": "user",
                "content": f"Question: {question}\n\nData:\n{json.dumps(gathered, indent=2)}"
            }],
        )
        answer = narrate_msg.content[0].text.strip()

        context["nl_query_answer"] = answer
        logger.info("NL query answered: %s…", answer[:80])

        return StepResult(
            skill="nl_query",
            status=StepStatus.DONE,
            payload={"question": question, "answer": answer, "data": gathered},
            confidence=0.9,
        )
    except Exception as exc:
        logger.error("nl_query failed: %s", exc)
        return StepResult(skill="nl_query", status=StepStatus.FAILED,
                          payload={}, error=str(exc))
