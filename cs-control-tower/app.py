"""
cs-control-tower — Flask Application
Port 5000 | Python 3.12

Pages:
  /              → Home / landing page + service health
  /architecture  → Educational: system design, event flow, component roles
  /explorer      → Live supply chain data browser (all 7 services)
  /chat          → AI Natural Language chat interface
  /events        → RabbitMQ BI event feed
  /bi            → BI analytics dashboard

API Routes:
  POST /api/chat           → NL question → AI answer
  GET  /api/health         → All service health
  GET  /api/events         → Recent BI events (JSON)
  GET  /api/bi/summary     → Campaign summary (JSON)
  GET  /api/explorer/<svc> → Proxy GET to downstream service
"""
import json
import logging
import uuid

from flask import Flask, render_template, request, jsonify, session

from config import Config
from models.bi_models import db
from services.api_client import all_health, get as svc_get
from services.anthropic_service import answer_question
from services.bi_service import (
    get_event_feed, get_campaign_summary, get_all_campaign_summaries,
    get_delivery_tracking, get_event_stats, get_recent_chat, save_chat
)

logging.basicConfig(level=logging.INFO, format="%(asctime)s %(levelname)s %(name)s — %(message)s")
logger = logging.getLogger(__name__)


def create_app() -> Flask:
    app = Flask(__name__)
    app.config.from_object(Config)

    # Init SQLAlchemy
    db.init_app(app)
    with app.app_context():
        db.create_all()
        logger.info("BI database tables created/verified")

    # Start RabbitMQ subscriber (non-blocking daemon thread)
    try:
        from services.rabbitmq_subscriber import start_subscriber
        start_subscriber(app)
    except Exception as e:
        logger.warning("RabbitMQ subscriber could not start: %s", e)

    # ── Page Routes ────────────────────────────────────────────────────────────

    @app.route("/")
    def home():
        health = all_health()
        up     = sum(1 for v in health.values() if v == "UP")
        summary = get_campaign_summary()
        stats   = get_event_stats()
        return render_template("pages/home.html",
                               health=health, up_count=up,
                               total_count=len(health),
                               summary=summary, stats=stats)

    @app.route("/architecture")
    def architecture():
        return render_template("pages/architecture.html")

    @app.route("/explorer")
    def explorer():
        health = all_health()
        return render_template("pages/explorer.html", health=health)

    @app.route("/chat")
    def chat():
        if "session_id" not in session:
            session["session_id"] = str(uuid.uuid4())
        history = get_recent_chat(20)
        api_key_set = bool(Config.ANTHROPIC_API_KEY)
        return render_template("pages/chat.html",
                               history=history,
                               api_key_set=api_key_set)

    @app.route("/events")
    def events_page():
        events = get_event_feed(100)
        stats  = get_event_stats()
        return render_template("pages/events.html", events=events, stats=stats)

    @app.route("/bi")
    def bi_page():
        summaries = get_all_campaign_summaries()
        deliveries = get_delivery_tracking()
        stats = get_event_stats()
        return render_template("pages/bi.html",
                               summaries=summaries,
                               deliveries=deliveries,
                               stats=stats)

    # ── API Routes ─────────────────────────────────────────────────────────────

    @app.post("/api/chat")
    def api_chat():
        data     = request.get_json(silent=True) or {}
        question = (data.get("question") or "").strip()
        if not question:
            return jsonify({"error": "question is required"}), 400

        session_id = session.get("session_id", str(uuid.uuid4()))
        result = answer_question(question)
        save_chat(question, result, session_id)

        return jsonify({
            "answer":      result["answer"],
            "service":     result.get("service"),
            "endpoint":    result.get("endpoint"),
            "intent":      result.get("intent"),
            "raw_json":    result.get("raw_json"),
            "api_payload": result.get("api_payload"),
        })

    @app.get("/api/health")
    def api_health():
        return jsonify(all_health())

    @app.get("/api/events")
    def api_events():
        limit = int(request.args.get("limit", 50))
        return jsonify(get_event_feed(limit))

    @app.get("/api/bi/summary")
    def api_bi_summary():
        return jsonify({
            "campaign": get_campaign_summary(),
            "deliveries": get_delivery_tracking(),
            "stats": get_event_stats(),
        })

    @app.get("/api/explorer/<service>")
    def api_explorer(service: str):
        path = request.args.get("path", "/api/v1/")
        data = svc_get(service, path)
        return jsonify(data)

    return app


if __name__ == "__main__":
    application = create_app()
    application.run(host="0.0.0.0", port=5000, debug=Config.DEBUG)
