"""
messaging/consumer.py
Background thread that subscribes to scm.# and hitl.# events.
Incoming events are stored in a simple in-memory deque so the
orchestrator can pull them during a run or the UI can stream them.
"""

from __future__ import annotations

import json
import logging
import os
import threading
from collections import deque
from typing import Callable, Any

import pika

logger = logging.getLogger(__name__)

EXCHANGE = os.getenv("RABBITMQ_EXCHANGE", "scm.events")
_event_queue: deque[dict[str, Any]] = deque(maxlen=500)
_handlers: list[Callable[[str, dict[str, Any]], None]] = []
_consumer_thread: threading.Thread | None = None


def register_handler(fn: Callable[[str, dict[str, Any]], None]) -> None:
    """Register a callback invoked for every received message."""
    _handlers.append(fn)


def get_recent_events(n: int = 50) -> list[dict[str, Any]]:
    return list(_event_queue)[-n:]


def _on_message(ch, method, _props, body: bytes) -> None:
    try:
        payload = json.loads(body)
        routing_key = method.routing_key
        _event_queue.append({"routing_key": routing_key, "payload": payload})
        for handler in _handlers:
            try:
                handler(routing_key, payload)
            except Exception as e:
                logger.warning("Event handler error: %s", e)
        ch.basic_ack(delivery_tag=method.delivery_tag)
    except Exception as e:
        logger.error("Failed to process message: %s", e)
        ch.basic_nack(delivery_tag=method.delivery_tag, requeue=False)


def _run_consumer() -> None:
    while True:
        try:
            params = pika.ConnectionParameters(
                host=os.getenv("RABBITMQ_HOST", "localhost"),
                port=int(os.getenv("RABBITMQ_PORT", "5672")),
                virtual_host=os.getenv("RABBITMQ_VHOST", "/"),
                credentials=pika.PlainCredentials(
                    os.getenv("RABBITMQ_USER", "guest"),
                    os.getenv("RABBITMQ_PASS", "guest"),
                ),
                heartbeat=60,
            )
            conn = pika.BlockingConnection(params)
            ch = conn.channel()
            ch.exchange_declare(exchange=EXCHANGE, exchange_type="topic", durable=True)

            # Agent inbox — all SCM domain events
            q1 = ch.queue_declare(queue="agent_inbox", durable=True)
            ch.queue_bind(exchange=EXCHANGE, queue=q1.method.queue, routing_key="scm.#")

            # HITL alerts
            q2 = ch.queue_declare(queue="hitl_alerts", durable=True)
            ch.queue_bind(exchange=EXCHANGE, queue=q2.method.queue, routing_key="hitl.#")

            ch.basic_qos(prefetch_count=10)
            ch.basic_consume(queue=q1.method.queue, on_message_callback=_on_message)
            ch.basic_consume(queue=q2.method.queue, on_message_callback=_on_message)

            logger.info("RabbitMQ consumer started")
            ch.start_consuming()
        except Exception as exc:
            logger.warning("RabbitMQ consumer disconnected (%s), retrying in 5s…", exc)
            import time; time.sleep(5)


def start_consumer() -> None:
    global _consumer_thread
    if _consumer_thread is None or not _consumer_thread.is_alive():
        _consumer_thread = threading.Thread(target=_run_consumer, daemon=True, name="rmq-consumer")
        _consumer_thread.start()
