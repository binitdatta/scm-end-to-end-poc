"""
app.py
Flask entry point for the SCM Agentic AI Control Tower.
"""

from __future__ import annotations

import json
import logging
import os
import queue
import threading
import uuid
from typing import Any

from dotenv import load_dotenv
load_dotenv()

from flask import Flask, Response, jsonify, render_template, request, stream_with_context
from flask_cors import CORS
from prometheus_client import generate_latest, CONTENT_TYPE_LATEST

from hitl.approval_routes import bp as hitl_bp
from messaging.consumer import start_consumer, get_recent_events
from orchestrator.graph import build_graph
from orchestrator.state import RunStatus
from api_clients.scm_client import health_check_all
from observability import context as obs_context
from observability.audit_routes import bp as audit_bp

logging.basicConfig(
    level=os.getenv("LOG_LEVEL", "INFO"),
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s",
)
logger = logging.getLogger(__name__)

app = Flask(__name__, template_folder="ui/templates", static_folder="ui/static")
app.secret_key = os.getenv("FLASK_SECRET_KEY", "dev-secret")
CORS(app)
app.register_blueprint(hitl_bp)
app.register_blueprint(audit_bp)

_runs: dict[str, dict[str, Any]] = {}
_runs_lock = threading.Lock()


@app.before_request
def _set_user_context():
    """Every request (including the ones the browser fires on page load
    to kick off a run) carries an X-User-Id header. No auth system exists
    yet — this is a simple identity header, not a verified credential —
    but it's enough to attribute cost/audit records to a person instead
    of everything showing up as one anonymous blob."""
    user_id = request.headers.get("X-User-Id", "anonymous").strip() or "anonymous"
    obs_context.current_user_id.set(user_id)


def _get_run(run_id: str) -> dict | None:
    with _runs_lock:
        return _runs.get(run_id)


def _upsert_run(run_id: str, data: dict) -> None:
    with _runs_lock:
        if run_id not in _runs:
            _runs[run_id] = {"log_queue": queue.Queue(), "state": {}}
        _runs[run_id]["state"].update(data)


def _push_log(run_id: str, line: str) -> None:
    entry = _get_run(run_id)
    if entry:
        entry["log_queue"].put(line)


def _run_agent(run_id: str, goal: str, user_id: str) -> None:
    # ContextVars do NOT propagate into a new thread automatically — this
    # thread needs its own .set() calls using the values captured on the
    # Flask request thread before this thread was spawned (see start_run).
    obs_context.current_user_id.set(user_id)
    obs_context.current_run_id.set(run_id)

    _push_log(run_id, f"[START] Run {run_id} — goal: {goal}")
    _upsert_run(run_id, {"status": "planning", "goal": goal,
                          "plan": [], "steps": [], "context": {},
                          "current_step_index": 0, "log": [], "report": ""})
    try:
        graph = build_graph()
        initial_state = {
            "run_id":  run_id,
            "goal":    goal,
            "plan":    [],
            "steps":   [],
            "context": {},
            "status":  "planning",
            "log":     [],
            "report":  "",
            "error":   None,
        }

        for chunk in graph.stream(initial_state):
            # __final__ chunk carries the completed runner state
            if "__final__" in chunk:
                _upsert_run(run_id, chunk["__final__"])
                continue
            # All other chunks carry a single log line
            for node_output in chunk.values():
                if isinstance(node_output, dict):
                    for line in node_output.get("log", []):
                        _push_log(run_id, line)
                    # Update state with anything other than log
                    state_update = {k: v for k, v in node_output.items() if k != "log"}
                    if state_update:
                        _upsert_run(run_id, state_update)

        _upsert_run(run_id, {"status": "completed"})
        _push_log(run_id, "[COMPLETE] Agent run finished.")

    except Exception as exc:
        logger.exception("Agent run %s failed: %s", run_id, exc)
        _upsert_run(run_id, {"status": "failed", "error": str(exc)})
        _push_log(run_id, f"[ERROR] {exc}")
    finally:
        entry = _get_run(run_id)
        if entry:
            entry["log_queue"].put(None)


@app.get("/")
def index():
    return render_template("console.html")


@app.post("/agent/run")
def start_run():
    body = request.get_json(force=True, silent=True) or {}
    goal = (body.get("goal") or "").strip()
    if not goal:
        return jsonify({"error": "goal is required"}), 400
    run_id = str(uuid.uuid4())
    user_id = obs_context.get_user_id()  # already set by _set_user_context above
    _upsert_run(run_id, {"run_id": run_id, "goal": goal, "status": "pending"})
    t = threading.Thread(target=_run_agent, args=(run_id, goal, user_id),
                         daemon=True, name=f"agent-{run_id[:8]}")
    t.start()
    return jsonify({"run_id": run_id, "status": "started"}), 202


@app.get("/agent/stream/<run_id>")
def stream_run(run_id: str):
    entry = _get_run(run_id)
    if not entry:
        return jsonify({"error": "run not found"}), 404

    def generate():
        log_q: queue.Queue = entry["log_queue"]
        while True:
            try:
                line = log_q.get(timeout=30)
                if line is None:
                    state = entry.get("state", {})
                    yield f"data: {json.dumps({'type': 'done', 'state': _serialise(state)})}\n\n"
                    break
                yield f"data: {json.dumps({'type': 'log', 'line': line})}\n\n"
            except queue.Empty:
                yield "data: {\"type\": \"ping\"}\n\n"

    return Response(stream_with_context(generate()), mimetype="text/event-stream",
                    headers={"Cache-Control": "no-cache", "X-Accel-Buffering": "no"})


@app.get("/agent/status/<run_id>")
def run_status(run_id: str):
    entry = _get_run(run_id)
    if not entry:
        return jsonify({"error": "run not found"}), 404
    return jsonify(_serialise(entry.get("state", {})))


@app.get("/agent/runs")
def list_runs():
    with _runs_lock:
        return jsonify([
            {"run_id": v["state"].get("run_id", k),
             "goal":   v["state"].get("goal", ""),
             "status": str(v["state"].get("status", "unknown"))}
            for k, v in _runs.items()
        ])


@app.get("/events/recent")
def recent_events():
    return jsonify(get_recent_events(50))


@app.get("/services/health")
def services_health():
    return jsonify(health_check_all())


@app.get("/health")
def health():
    return jsonify({"status": "ok", "service": "cs-agent-control-tower"})


@app.get("/metrics")
def metrics_endpoint():
    """Prometheus scrape target. See observability/metrics.py for what's
    exposed here — separate from the /audit page's per-call detail."""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)


def _serialise(state: dict) -> dict:
    out: dict[str, Any] = {}
    for k, v in state.items():
        if k == "log_queue":
            continue
        out[k] = _s(v)
    return out


def _s(item: Any) -> Any:
    if isinstance(item, list):
        return [_s(i) for i in item]
    if isinstance(item, dict):
        return {dk: _s(dv) for dk, dv in item.items()}
    if hasattr(item, "__dataclass_fields__"):
        return {f: _s(getattr(item, f)) for f in item.__dataclass_fields__}
    if hasattr(item, "value"):
        return item.value
    return item


if __name__ == "__main__":
    start_consumer()
    port  = int(os.getenv("FLASK_PORT", "9000"))
    debug = os.getenv("FLASK_DEBUG", "false").lower() == "true"
    logger.info("SCM Agent Control Tower starting on port %d", port)
    app.run(host="0.0.0.0", port=port, debug=debug, threaded=True, use_reloader=False)
