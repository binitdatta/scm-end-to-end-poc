"""
RabbitMQ Subscriber — listens to erp.# on the shared topic exchange
and populates the BI database with every event received.

Runs in a background thread started by app.py on startup.
Gracefully handles connection failures (retries every 10 seconds).
"""
import json
import logging
import threading
import time
from datetime import datetime

import pika

from config import Config

logger = logging.getLogger(__name__)

_stop_event = threading.Event()


def _get_service(routing_key: str) -> str:
    """Derive service name from routing key: erp.crm.campaign.launched → crm"""
    parts = routing_key.split(".")
    return parts[1] if len(parts) > 1 else "unknown"


def _get_event_type(routing_key: str) -> str:
    """erp.tms.delivery.pod-confirmed → DELIVERY_POD_CONFIRMED"""
    parts = routing_key.split(".")
    return "_".join(parts[2:]).upper() if len(parts) > 2 else routing_key.upper()


def _upsert_campaign_summary(app, routing_key: str, body: dict):
    """Update the denormalised CampaignSummary row for this event."""
    from models.bi_models import db, CampaignSummary

    campaign_code = (
        body.get("campaignCode")
        or body.get("campaign_code")
        or Config.CAMPAIGN_CODE
    )

    with app.app_context():
        summary = CampaignSummary.query.filter_by(campaign_code=campaign_code).first()
        if not summary:
            summary = CampaignSummary(campaign_code=campaign_code)
            db.session.add(summary)

        rk = routing_key.lower()
        if "campaign.launched" in rk:
            summary.campaign_status = "ACTIVE"
        elif "po." in rk:
            summary.total_pos = (summary.total_pos or 0) + 1
            qty = body.get("totalUnits") or body.get("totalQuantity") or 0
            summary.total_units_ordered = (summary.total_units_ordered or 0) + qty
        elif "putaway.completed" in rk:
            qty = body.get("receivedQuantity") or body.get("totalUnitsReceived") or 0
            summary.total_units_received = (summary.total_units_received or 0) + qty
        elif "store-order.allocated" in rk:
            summary.total_orders = (summary.total_orders or 0) + 1
            qty = body.get("quantityAllocated") or 0
            summary.total_units_allocated = (summary.total_units_allocated or 0) + qty
        elif "shipment.dispatched" in rk:
            summary.total_shipments = (summary.total_shipments or 0) + 1
            qty = body.get("totalUnits") or 0
            summary.total_units_shipped = (summary.total_units_shipped or 0) + qty
        elif "pod-confirmed" in rk:
            summary.total_loads = (summary.total_loads or 0) + 1
            qty = body.get("totalUnitsDelivered") or body.get("totalUnits") or 0
            summary.total_units_delivered = (summary.total_units_delivered or 0) + qty
            stores = body.get("totalStoresDelivered") or 0
            summary.stores_delivered = (summary.stores_delivered or 0) + stores

        summary.last_event_at = datetime.utcnow()
        db.session.commit()


def _upsert_delivery_tracking(app, body: dict):
    """Upsert a DeliveryTracking row on pod-confirmed events."""
    from models.bi_models import db, DeliveryTracking

    load_number = body.get("loadNumber")
    if not load_number:
        return

    with app.app_context():
        row = DeliveryTracking.query.filter_by(load_number=load_number).first()
        if not row:
            row = DeliveryTracking(
                campaign_code=body.get("campaignCode", Config.CAMPAIGN_CODE),
                region_code=body.get("regionCode", ""),
                load_number=load_number,
            )
            db.session.add(row)

        row.carrier_name    = body.get("carrierName")
        row.pro_number      = body.get("proNumber")
        row.sku             = body.get("sku")
        row.total_units     = body.get("totalUnits", 0)
        row.delivered_units = body.get("totalUnitsDelivered", 0)
        row.stores_count    = body.get("totalStoresDelivered", 0)
        row.load_status     = body.get("loadStatus", "COMPLETED")
        row.pod_confirmed_at = datetime.utcnow()
        row.updated_at       = datetime.utcnow()
        db.session.commit()


def _on_message(app, ch, method, properties, body_bytes):
    """Callback fired for every RabbitMQ message."""
    routing_key = method.routing_key
    try:
        body = json.loads(body_bytes.decode("utf-8"))
    except Exception:
        body = {}

    logger.info("RabbitMQ received: %s", routing_key)

    # 1. Store raw event
    from models.bi_models import db, ErpEvent
    with app.app_context():
        event = ErpEvent(
            routing_key   = routing_key,
            service       = _get_service(routing_key),
            event_type    = _get_event_type(routing_key),
            campaign_code = body.get("campaignCode") or body.get("campaign_code"),
            region_code   = body.get("regionCode"),
            payload_json  = json.dumps(body, default=str),
        )
        db.session.add(event)
        db.session.commit()

    # 2. Update campaign summary
    try:
        _upsert_campaign_summary(app, routing_key, body)
    except Exception as e:
        logger.error("Campaign summary update failed: %s", e)

    # 3. POD tracking
    if "pod-confirmed" in routing_key.lower():
        try:
            _upsert_delivery_tracking(app, body)
        except Exception as e:
            logger.error("Delivery tracking update failed: %s", e)

    ch.basic_ack(delivery_tag=method.delivery_tag)


def _subscribe_loop(app):
    """Blocking loop — reconnects on failure."""
    while not _stop_event.is_set():
        try:
            creds = pika.PlainCredentials(Config.RABBITMQ_USER, Config.RABBITMQ_PASS)
            params = pika.ConnectionParameters(
                host=Config.RABBITMQ_HOST,
                port=Config.RABBITMQ_PORT,
                virtual_host=Config.RABBITMQ_VHOST,
                credentials=creds,
                heartbeat=60,
                blocked_connection_timeout=30,
            )
            connection = pika.BlockingConnection(params)
            channel    = connection.channel()

            channel.exchange_declare(
                exchange=Config.RABBITMQ_EXCHANGE,
                exchange_type="topic",
                durable=True,
            )
            channel.queue_declare(queue=Config.RABBITMQ_QUEUE, durable=True)
            channel.queue_bind(
                exchange=Config.RABBITMQ_EXCHANGE,
                queue=Config.RABBITMQ_QUEUE,
                routing_key=Config.RABBITMQ_ROUTING_KEY,
            )
            channel.basic_qos(prefetch_count=10)
            channel.basic_consume(
                queue=Config.RABBITMQ_QUEUE,
                on_message_callback=lambda ch, m, p, b: _on_message(app, ch, m, p, b),
            )

            logger.info("RabbitMQ subscriber connected. Listening on erp.#")
            channel.start_consuming()

        except pika.exceptions.AMQPConnectionError:
            logger.warning("RabbitMQ not available — retrying in 10s")
        except Exception as e:
            logger.error("RabbitMQ subscriber error: %s", e)

        if not _stop_event.is_set():
            time.sleep(10)


def start_subscriber(app):
    """Start the subscriber in a daemon thread."""
    t = threading.Thread(target=_subscribe_loop, args=(app,), daemon=True, name="rabbitmq-subscriber")
    t.start()
    logger.info("RabbitMQ subscriber thread started")
    return t


def stop_subscriber():
    _stop_event.set()
