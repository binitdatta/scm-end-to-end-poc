"""
hitl/approval_routes.py
Flask Blueprint exposing the approve / reject / override endpoints
that the operator console calls when reviewing a HITL gate.
"""

from __future__ import annotations

from flask import Blueprint, jsonify, request

from hitl import gate

bp = Blueprint("hitl", __name__, url_prefix="/hitl")


@bp.get("/pending")
def get_pending():
    """Return all currently open HITL gates."""
    return jsonify(gate.get_pending())


@bp.get("/all")
def get_all():
    """Return all gates (resolved + unresolved)."""
    return jsonify(gate.get_all())


@bp.post("/resolve/<gate_id>")
def resolve(gate_id: str):
    """
    Body: { "decision": "approve"|"reject"|"override",
            "override_payload": {...} }   ← optional
    """
    body     = request.get_json(force=True, silent=True) or {}
    decision = body.get("decision", "approve")
    override = body.get("override_payload")

    ok = gate.resolve(gate_id, decision, override)
    if not ok:
        return jsonify({"error": f"Unknown gate_id: {gate_id}"}), 404

    return jsonify({"gate_id": gate_id, "decision": decision, "ok": True})
