"""
hitl/gate.py
Human-in-the-Loop gate.

Flow:
  1. Skill calls request_approval() → returns a gate_id, stores request
  2. Flask SSE pushes the pending request to the operator console
  3. Operator clicks Approve/Reject → approval_routes.py calls resolve()
  4. Orchestrator polls await_decision() which blocks until resolved
"""

from __future__ import annotations

import logging
import threading
import time
import uuid
from typing import Any

logger = logging.getLogger(__name__)

# gate_id → {"request": HITLRequest-like dict, "event": threading.Event, "decision": str|None}
_pending: dict[str, dict[str, Any]] = {}
_lock = threading.Lock()

# SSE subscribers waiting for HITL events
_sse_subscribers: list[Any] = []


def request_approval(
    skill: str,
    action: str,
    recommendation: str,
    confidence: float,
    payload: dict[str, Any],
) -> str:
    """Register a HITL request. Returns gate_id."""
    gate_id = str(uuid.uuid4())
    evt = threading.Event()
    with _lock:
        _pending[gate_id] = {
            "gate_id": gate_id,
            "skill": skill,
            "action": action,
            "recommendation": recommendation,
            "confidence": confidence,
            "payload": payload,
            "decision": None,
            "override_payload": None,
            "event": evt,
        }
    logger.info("HITL gate opened: %s for skill=%s action=%s", gate_id, skill, action)
    _notify_sse(gate_id)
    return gate_id


def resolve(gate_id: str, decision: str, override_payload: dict | None = None) -> bool:
    """Called by the Flask approval route. decision = 'approve'|'reject'|'override'."""
    with _lock:
        if gate_id not in _pending:
            return False
        entry = _pending[gate_id]
        entry["decision"] = decision
        entry["override_payload"] = override_payload
        entry["event"].set()
    logger.info("HITL gate %s resolved with decision=%s", gate_id, decision)
    return True


def await_decision(gate_id: str, timeout: float = 0) -> dict[str, Any]:
    """Block until the human resolves the gate. timeout=0 means wait forever."""
    with _lock:
        entry = _pending.get(gate_id)
    if entry is None:
        raise KeyError(f"Unknown gate_id: {gate_id}")

    evt: threading.Event = entry["event"]
    if timeout > 0:
        evt.wait(timeout=timeout)
    else:
        evt.wait()  # wait indefinitely

    with _lock:
        return dict(entry)


def get_pending() -> list[dict[str, Any]]:
    """Return all unresolved HITL requests (without threading internals)."""
    with _lock:
        return [
            {k: v for k, v in entry.items() if k != "event"}
            for entry in _pending.values()
            if entry["decision"] is None
        ]


def get_all() -> list[dict[str, Any]]:
    with _lock:
        return [
            {k: v for k, v in entry.items() if k != "event"}
            for entry in _pending.values()
        ]


def _notify_sse(gate_id: str) -> None:
    # Push gate_id to any waiting SSE consumers
    dead = []
    for q in _sse_subscribers:
        try:
            q.put({"type": "hitl_request", "gate_id": gate_id})
        except Exception:
            dead.append(q)
    for q in dead:
        _sse_subscribers.remove(q)


def subscribe_sse(q: Any) -> None:
    _sse_subscribers.append(q)


def unsubscribe_sse(q: Any) -> None:
    try:
        _sse_subscribers.remove(q)
    except ValueError:
        pass
