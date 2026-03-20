"""
cs-control-tower — Configuration
Reads all settings from .env via python-dotenv.
"""
import os
from dotenv import load_dotenv

load_dotenv()


class Config:
    # Flask
    SECRET_KEY = os.getenv("FLASK_SECRET_KEY", "dev-secret-change-me")
    DEBUG = os.getenv("FLASK_DEBUG", "false").lower() == "true"

    # Anthropic
    ANTHROPIC_API_KEY = os.getenv("ANTHROPIC_API_KEY", "")
    ANTHROPIC_MODEL = "claude-sonnet-4-20250514"

    # SQLAlchemy — SQLite by default, zero setup
    SQLALCHEMY_DATABASE_URI = os.getenv("DATABASE_URL", "sqlite:///control_tower_bi.db")
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # RabbitMQ
    RABBITMQ_HOST = os.getenv("RABBITMQ_HOST", "localhost")
    RABBITMQ_PORT = int(os.getenv("RABBITMQ_PORT", "5672"))
    RABBITMQ_USER = os.getenv("RABBITMQ_USER", "guest")
    RABBITMQ_PASS = os.getenv("RABBITMQ_PASS", "guest")
    RABBITMQ_VHOST = os.getenv("RABBITMQ_VHOST", "/")
    RABBITMQ_EXCHANGE = "erp.topic.exchange"
    RABBITMQ_QUEUE = "control-tower-bi"
    RABBITMQ_ROUTING_KEY = "erp.#"

    # Downstream service base URLs
    SERVICE_URLS = {
        "crm":           os.getenv("CRM_URL",           "http://localhost:8081"),
        "vendor":        os.getenv("VENDOR_URL",         "http://localhost:8082"),
        "procurement":   os.getenv("PROCUREMENT_URL",    "http://localhost:8083"),
        "wms-inbound":   os.getenv("WMS_INBOUND_URL",    "http://localhost:8084"),
        "oms":           os.getenv("OMS_URL",            "http://localhost:8085"),
        "wms-outbound":  os.getenv("WMS_OUTBOUND_URL",   "http://localhost:8086"),
        "tms":           os.getenv("TMS_URL",            "http://localhost:8087"),
    }

    # Campaign constant (used across chat prompts)
    CAMPAIGN_CODE = "SUMMER25-TOY"
