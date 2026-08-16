"""
observability/audit_routes.py

The Audit Trail page — cost per user, per day, per month, plus the raw
recent LLM/HTTP call detail — for Security and Finance to review without
needing shell/SQLite access.

Registered in app.py via: app.register_blueprint(audit_bp)
"""

from __future__ import annotations

from flask import Blueprint, jsonify, render_template, request

from . import db

bp = Blueprint("audit", __name__, url_prefix="/audit")


def _q_args():
    return {
        "from_date": request.args.get("from") or None,
        "to_date":   request.args.get("to") or None,
        "user_id":   request.args.get("user_id") or None,
    }


@bp.get("")
def audit_page():
    return render_template("audit.html")


@bp.get("/api/summary")
def api_summary():
    args = _q_args()
    return jsonify(db.summary(args["from_date"], args["to_date"], args["user_id"]))


@bp.get("/api/by-user")
def api_by_user():
    args = _q_args()
    return jsonify(db.cost_by_user(args["from_date"], args["to_date"]))


@bp.get("/api/by-day")
def api_by_day():
    args = _q_args()
    return jsonify(db.cost_by_day(args["from_date"], args["to_date"], args["user_id"]))


@bp.get("/api/by-month")
def api_by_month():
    args = _q_args()
    return jsonify(db.cost_by_month(args["from_date"], args["to_date"], args["user_id"]))


@bp.get("/api/llm-calls")
def api_llm_calls():
    args = _q_args()
    limit = min(int(request.args.get("limit", 50)), 500)
    return jsonify(db.recent_llm_calls(limit, args["user_id"], args["from_date"], args["to_date"]))


@bp.get("/api/http-calls")
def api_http_calls():
    args = _q_args()
    limit = min(int(request.args.get("limit", 50)), 500)
    return jsonify(db.recent_http_calls(limit, args["user_id"], args["from_date"], args["to_date"]))
