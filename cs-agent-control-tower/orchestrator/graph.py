"""
orchestrator/graph.py

Replaces LangGraph StateGraph with a plain Python execution loop.

LangGraph 0.2.70 StateGraph(dict) has two issues that broke this app:
1. current_step_index from node_next_step does not reliably propagate
   to conditional edge functions when state is untyped (dict schema).
2. graph.stream() emits an __end__ chunk containing the full merged
   log, causing every log line to appear twice in the UI.

A plain Python loop is simpler, more predictable, and correct.
HITL blocking via threading.Event works identically — the loop just
waits inside the skill call until the human approves.
"""

from __future__ import annotations

import logging
from typing import Any

import yaml

from reasoning import planner, narrator

logger = logging.getLogger(__name__)

_policy: dict[str, Any] = {}


def _load_policy() -> dict[str, Any]:
    global _policy
    if not _policy:
        try:
            with open("config/agent_policy.yml") as f:
                _policy = yaml.safe_load(f)
        except Exception as e:
            logger.warning("Could not load agent_policy.yml: %s", e)
            _policy = {}
    return _policy


_SKILL_MODULES: dict[str, str] = {
    "campaign_launcher":  "skills.campaign_launcher",
    "vendor_rfq":         "skills.vendor_rfq",
    "po_lifecycle":       "skills.po_lifecycle",
    "inbound_receiving":  "skills.inbound_receiving",
    "order_fulfillment":  "skills.order_fulfillment",
    "wms_outbound":       "skills.wms_outbound",
    "tms_dispatch":       "skills.tms_dispatch",
    "anomaly_detector":   "skills.anomaly_detector",
    "nl_query":           "skills.nl_query",
}


def _dispatch_skill(skill_name: str, params: dict,
                    context: dict, policy: dict) -> dict:
    import importlib
    module_path = _SKILL_MODULES.get(skill_name)
    if not module_path:
        return {"skill": skill_name, "status": "failed",
                "error": f"Unknown skill: {skill_name}",
                "payload": {}, "confidence": 0.0}
    try:
        mod    = importlib.import_module(module_path)
        result = mod.run(params, context, policy)
        return {
            "skill":      result.skill,
            "status":     result.status.value if hasattr(result.status, "value") else str(result.status),
            "payload":    result.payload or {},
            "error":      result.error,
            "confidence": result.confidence,
        }
    except Exception as exc:
        logger.error("Skill %s raised: %s", skill_name, exc)
        return {"skill": skill_name, "status": "failed",
                "error": str(exc), "payload": {}, "confidence": 0.0}


class AgentRunner:
    """
    Plain Python execution engine. Replaces LangGraph StateGraph.
    Yields log lines as it runs so the SSE stream stays live.
    """

    def __init__(self, state: dict):
        self.state = state

    def run(self):
        """
        Generator — yields individual log line strings as the agent executes.
        The caller (app.py) iterates this and pushes each line to the SSE queue.
        Terminates when all steps are done or an unrecoverable error occurs.
        """
        goal = self.state.get("goal", "")
        yield f"[PLAN] Decomposing goal: {goal}"

        # ── Step 1: Plan ───────────────────────────────────────────────────
        try:
            result  = planner.plan(goal)
            plan    = result.get("steps", [])
            summary = result.get("plan_summary", "")
            self.state["plan"]   = plan
            self.state["status"] = "running"
            yield f"[PLAN] {summary} — {len(plan)} steps identified"
        except Exception as exc:
            self.state["status"] = "failed"
            self.state["error"]  = str(exc)
            yield f"[ERROR] Planning failed: {exc}"
            return

        if not plan:
            yield "[ERROR] Claude returned an empty plan."
            self.state["status"] = "failed"
            return

        # ── Step 2: Execute each step in order ─────────────────────────────
        policy  = _load_policy()
        context = self.state.get("context") or {}
        steps   = []

        for i, step_def in enumerate(plan):
            skill  = step_def.get("skill", "")
            params = step_def.get("params") or {}
            yield f"[EXEC] Step {i + 1}/{len(plan)}: {skill}"

            result = _dispatch_skill(skill, params, context, policy)
            steps.append(result)
            self.state["steps"]   = steps
            self.state["context"] = context

            status = result.get("status", "failed")
            if status == "failed":
                yield f"[FAIL] {skill}: {result.get('error')}"
            elif status == "skipped":
                yield f"[SKIP] {skill}: {result.get('error') or 'skipped'}"
            else:
                yield f"[DONE] {skill} completed successfully"

        # ── Step 3: Narrate ────────────────────────────────────────────────
        yield "[NARRATE] Generating run report…"
        try:
            report = narrator.narrate(
                goal=goal,
                steps=steps,
                context=context,
            )
            self.state["report"] = report
        except Exception as exc:
            self.state["report"] = f"Narrative generation failed: {exc}"

        self.state["status"] = "completed"
        yield "[DONE] Run complete."


def build_graph(checkpointer=None):
    """
    Returns an AgentRunner factory. Signature kept compatible with app.py.
    The returned object has a .stream(initial_state) method that yields
    chunks in the same format app.py expects: {"node_name": {"log": [line]}}.
    """
    return _GraphShim()


class _GraphShim:
    """
    Drop-in replacement for a compiled LangGraph graph.
    Exposes .stream(initial_state) yielding one chunk per log line
    so app.py needs zero changes.
    """

    def stream(self, initial_state: dict):
        runner = AgentRunner(initial_state)
        for line in runner.run():
            # Yield in the same chunk format app.py already handles
            yield {"execute_step": {"log": [line]}}
        # Final state chunk
        yield {"__final__": runner.state}