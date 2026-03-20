"""
BI (Business Intelligence) database models.
These are denormalised read-models populated by the RabbitMQ subscriber.
SQLite by default — zero additional setup required.
"""
from datetime import datetime
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()


class ErpEvent(db.Model):
    """
    Raw event log — every RabbitMQ message received is stored here.
    This is the single source of truth for the BI layer.
    """
    __tablename__ = "erp_events"

    id            = db.Column(db.Integer,  primary_key=True, autoincrement=True)
    routing_key   = db.Column(db.String(120), nullable=False, index=True)
    service       = db.Column(db.String(40),  nullable=False, index=True)
    event_type    = db.Column(db.String(80),  nullable=True,  index=True)
    campaign_code = db.Column(db.String(50),  nullable=True,  index=True)
    region_code   = db.Column(db.String(30),  nullable=True)
    payload_json  = db.Column(db.Text,        nullable=False)
    received_at   = db.Column(db.DateTime,    default=datetime.utcnow, index=True)

    def to_dict(self):
        return {
            "id":            self.id,
            "routing_key":   self.routing_key,
            "service":       self.service,
            "event_type":    self.event_type,
            "campaign_code": self.campaign_code,
            "region_code":   self.region_code,
            "received_at":   self.received_at.isoformat() if self.received_at else None,
        }


class CampaignSummary(db.Model):
    """
    Denormalised campaign-level BI rollup.
    Updated each time a relevant event arrives via RabbitMQ.
    """
    __tablename__ = "campaign_summaries"

    id                    = db.Column(db.Integer,  primary_key=True, autoincrement=True)
    campaign_code         = db.Column(db.String(50), nullable=False, unique=True, index=True)
    campaign_status       = db.Column(db.String(30), nullable=True)
    total_pos             = db.Column(db.Integer, default=0)
    total_units_ordered   = db.Column(db.Integer, default=0)
    total_units_received  = db.Column(db.Integer, default=0)
    total_orders          = db.Column(db.Integer, default=0)
    total_units_allocated = db.Column(db.Integer, default=0)
    total_shipments       = db.Column(db.Integer, default=0)
    total_units_shipped   = db.Column(db.Integer, default=0)
    total_loads           = db.Column(db.Integer, default=0)
    total_units_delivered = db.Column(db.Integer, default=0)
    stores_delivered      = db.Column(db.Integer, default=0)
    last_event_at         = db.Column(db.DateTime, nullable=True)
    updated_at            = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow)

    def to_dict(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}


class DeliveryTracking(db.Model):
    """
    Per-region delivery tracking — populated from TMS pod-confirmed events.
    """
    __tablename__ = "delivery_tracking"

    id              = db.Column(db.Integer,  primary_key=True, autoincrement=True)
    campaign_code   = db.Column(db.String(50), nullable=False, index=True)
    region_code     = db.Column(db.String(30), nullable=False, index=True)
    load_number     = db.Column(db.String(50), nullable=True)
    carrier_name    = db.Column(db.String(100), nullable=True)
    pro_number      = db.Column(db.String(100), nullable=True)
    sku             = db.Column(db.String(50),  nullable=True)
    total_units     = db.Column(db.Integer, default=0)
    delivered_units = db.Column(db.Integer, default=0)
    stores_count    = db.Column(db.Integer, default=0)
    load_status     = db.Column(db.String(30), nullable=True)
    pod_confirmed_at = db.Column(db.DateTime, nullable=True)
    updated_at      = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {c.name: getattr(self, c.name) for c in self.__table__.columns}


class ChatHistory(db.Model):
    """
    Stores all AI chat interactions for history display.
    """
    __tablename__ = "chat_history"

    id              = db.Column(db.Integer, primary_key=True, autoincrement=True)
    user_question   = db.Column(db.Text, nullable=False)
    ai_response     = db.Column(db.Text, nullable=False)
    service_called  = db.Column(db.String(50),  nullable=True)
    api_endpoint    = db.Column(db.String(200), nullable=True)
    api_payload     = db.Column(db.Text, nullable=True)
    raw_api_json    = db.Column(db.Text, nullable=True)
    session_id      = db.Column(db.String(64), nullable=True, index=True)
    created_at      = db.Column(db.DateTime, default=datetime.utcnow)

    def to_dict(self):
        return {
            "id":             self.id,
            "user_question":  self.user_question,
            "ai_response":    self.ai_response,
            "service_called": self.service_called,
            "api_endpoint":   self.api_endpoint,
            "created_at":     self.created_at.isoformat() if self.created_at else None,
        }
