"""
BI Service — helper functions to query the BI database for dashboard views.
"""
import json
from datetime import datetime, timedelta
from models.bi_models import ErpEvent, CampaignSummary, DeliveryTracking, ChatHistory


def get_event_feed(limit: int = 50) -> list[dict]:
    events = (
        ErpEvent.query
        .order_by(ErpEvent.received_at.desc())
        .limit(limit)
        .all()
    )
    return [e.to_dict() for e in events]


def get_campaign_summary(campaign_code: str = "SUMMER25-TOY") -> dict | None:
    row = CampaignSummary.query.filter_by(campaign_code=campaign_code).first()
    return row.to_dict() if row else None


def get_all_campaign_summaries() -> list[dict]:
    rows = CampaignSummary.query.order_by(CampaignSummary.campaign_code).all()
    return [r.to_dict() for r in rows]


def get_delivery_tracking(campaign_code: str = "SUMMER25-TOY") -> list[dict]:
    rows = (
        DeliveryTracking.query
        .filter_by(campaign_code=campaign_code)
        .order_by(DeliveryTracking.pod_confirmed_at.desc())
        .all()
    )
    return [r.to_dict() for r in rows]


def get_event_stats() -> dict:
    """Summary counts grouped by service and event type."""
    from models.bi_models import db
    from sqlalchemy import func

    by_service = (
        db.session.query(ErpEvent.service, func.count(ErpEvent.id))
        .group_by(ErpEvent.service)
        .all()
    )
    total = ErpEvent.query.count()
    last  = ErpEvent.query.order_by(ErpEvent.received_at.desc()).first()

    return {
        "total_events": total,
        "by_service":   {svc: cnt for svc, cnt in by_service},
        "last_event_at": last.received_at.isoformat() if last else None,
    }


def get_recent_chat(limit: int = 20) -> list[dict]:
    rows = (
        ChatHistory.query
        .order_by(ChatHistory.created_at.desc())
        .limit(limit)
        .all()
    )
    return [r.to_dict() for r in rows]


def save_chat(user_question: str, result: dict, session_id: str = None):
    from models.bi_models import db
    record = ChatHistory(
        user_question  = user_question,
        ai_response    = result.get("answer", ""),
        service_called = result.get("service"),
        api_endpoint   = result.get("endpoint"),
        api_payload    = json.dumps(result.get("api_payload"), default=str) if result.get("api_payload") else None,
        raw_api_json   = json.dumps(result.get("raw_json"),   default=str) if result.get("raw_json")   else None,
        session_id     = session_id,
    )
    db.session.add(record)
    db.session.commit()
    return record
