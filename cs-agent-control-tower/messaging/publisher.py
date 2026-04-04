"""
messaging/publisher.py
Publishes domain events and HITL alerts to RabbitMQ.
Uses a lazy-init connection so the app starts even if RabbitMQ is offline.
"""

from __future__ import annotations

import json
import logging
import os
import threading
from typing import Any

import pika

logger = logging.getLogger(__name__)

_lock = threading.Lock()
_connection: pika.BlockingConnection | None = None
_channel: pika.adapters.blocking_connection.BlockingChannel | None = None

EXCHANGE = os.getenv("RABBITMQ_EXCHANGE", "scm.events")


def _connect() -> pika.adapters.blocking_connection.BlockingChannel:
    global _connection, _channel
    with _lock:
        if _channel is None or _channel.is_closed:
            params = pika.ConnectionParameters(
                host=os.getenv("RABBITMQ_HOST", "localhost"),
                port=int(os.getenv("RABBITMQ_PORT", "5672")),
                virtual_host=os.getenv("RABBITMQ_VHOST", "/"),
                credentials=pika.PlainCredentials(
                    os.getenv("RABBITMQ_USER", "guest"),
                    os.getenv("RABBITMQ_PASS", "guest"),
                ),
                heartbeat=60,
                blocked_connection_timeout=30,
            )
            _connection = pika.BlockingConnection(params)
            _channel = _connection.channel()
            _channel.exchange_declare(
                exchange=EXCHANGE,
                exchange_type="topic",
                durable=True,
            )
            logger.info("RabbitMQ publisher connected to exchange '%s'", EXCHANGE)
    return _channel


def publish(routing_key: str, payload: dict[str, Any]) -> None:
    """Publish a JSON event. Silently logs on failure so the agent keeps running."""
    try:
        ch = _connect()
        ch.basic_publish(
            exchange=EXCHANGE,
            routing_key=routing_key,
            body=json.dumps(payload),
            properties=pika.BasicProperties(
                content_type="application/json",
                delivery_mode=2,   # persistent
            ),
        )
        logger.debug("Published [%s] %s", routing_key, payload)
    except Exception as exc:
        logger.warning("RabbitMQ publish failed (%s): %s", routing_key, exc)
