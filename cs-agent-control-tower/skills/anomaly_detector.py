"""
skills/anomaly_detector.py
AI-powered: pulls current state from all 7 APIs, asks Claude to find
anomalies, and raises a HITL gate if any are high-severity.
"""

from __future__ import annotations

import logging
from typing import Any

from api_clients import scm_client as api
from hitl import gate as hitl
from messaging import publisher
from orchestrator.state import StepResult, StepStatus
from reasoning import narrator

logger = logging.getLogger(__name__)


def _collect_observations(context: dict[str, Any]) -> list[dict[str, Any]]:
    observations = []

    def _try(label: str, fn, *args):
        try:
            result = fn(*args)
            observations.append({"source": label, "data": result, "error": None})
        except Exception as exc:
            observations.append({"source": label, "data": None, "error": str(exc)})

    _try("crm.campaigns",    api.crm_list_campaigns)
    _try("vendor.vendors",   api.vendor_list_vendors)
    _try("wms.inventory",    api.wms_inbound_list_inventory)
    _try("oms.regions",      api.oms_list_regions)

    # Attach current context so Claude can cross-reference IDs
    observations.append({"source": "agent.context", "data": context, "error": None})
    return observations


def run(params: dict[str, Any], context: dict[str, Any], policy: dict) -> StepResult:
    try:
        observations = _collect_observations(context)
        result = narrator.detect_anomalies(observations)

        anomalies      = result.get("anomalies", [])
        overall_health = result.get("overall_health", "healthy")

        high_severity = [a for a in anomalies if a.get("severity") == "high"]

        publisher.publish("scm.agent.anomaly_scan.complete", {
            "overall_health": overall_health,
            "anomaly_count": len(anomalies),
            "high_severity_count": len(high_severity),
        })

        # Raise HITL gate if any high-severity anomalies found
        if high_severity:
            recommendations = "; ".join(
                a.get("recommendation", a.get("description", "")) for a in high_severity
            )
            gate_id = hitl.request_approval(
                skill="anomaly_detector",
                action="High-severity anomalies detected — review required",
                recommendation=f"Found {len(high_severity)} high-severity anomaly(ies). "
                               f"Recommendations: {recommendations}",
                confidence=0.95,
                payload={"anomalies": anomalies, "overall_health": overall_health},
            )
            decision_entry = hitl.await_decision(gate_id)
            context["anomaly_decision"] = decision_entry["decision"]

        context["anomaly_scan"] = {
            "overall_health": overall_health,
            "anomaly_count": len(anomalies),
        }

        logger.info("Anomaly scan: health=%s anomalies=%d", overall_health, len(anomalies))
        return StepResult(
            skill="anomaly_detector",
            status=StepStatus.DONE,
            payload={"anomalies": anomalies, "overall_health": overall_health},
            confidence=0.95,
        )
    except Exception as exc:
        logger.error("anomaly_detector failed: %s", exc)
        return StepResult(skill="anomaly_detector", status=StepStatus.FAILED,
                          payload={}, error=str(exc))
