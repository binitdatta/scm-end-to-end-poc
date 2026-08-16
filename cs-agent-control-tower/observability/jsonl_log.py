"""
observability/jsonl_log.py

Appends one JSON object per line to a daily-rotated log file, separate
from the human-readable app log configured in app.py's logging.basicConfig.
This is the durable raw record — every HTTP call and every LLM call,
full request/response — independent of whatever happens to SQLite.

Rotation is daily (TimedRotatingFileHandler), matching typical log-
shipping conventions. Retention defaults to 90 days; override with
AUDIT_LOG_RETENTION_DAYS.
"""

from __future__ import annotations

import json
import logging
import logging.handlers
import os
import threading
from datetime import datetime, timezone
from typing import Any

_LOG_DIR = os.getenv("AUDIT_LOG_DIR", "./logs")
_RETENTION_DAYS = int(os.getenv("AUDIT_LOG_RETENTION_DAYS", "90"))

_lock = threading.Lock()
_loggers: dict[str, logging.Logger] = {}


class _JsonLineFormatter(logging.Formatter):
    def format(self, record: logging.LogRecord) -> str:
        # record.msg is already a JSON-serializable dict at call sites below
        return json.dumps(record.msg, default=str, separators=(",", ":"))


def _get_logger(name: str) -> logging.Logger:
    if name in _loggers:
        return _loggers[name]
    with _lock:
        if name in _loggers:
            return _loggers[name]
        os.makedirs(_LOG_DIR, exist_ok=True)
        path = os.path.join(_LOG_DIR, f"{name}.jsonl")
        handler = logging.handlers.TimedRotatingFileHandler(
            path, when="midnight", backupCount=_RETENTION_DAYS, utc=True
        )
        handler.setFormatter(_JsonLineFormatter())
        logger = logging.getLogger(f"audit.{name}")
        logger.setLevel(logging.INFO)
        logger.addHandler(handler)
        logger.propagate = False  # keep out of the main app log
        _loggers[name] = logger
        return logger


def now_iso() -> str:
    return datetime.now(timezone.utc).isoformat(timespec="milliseconds")


def write(stream: str, record: dict[str, Any]) -> None:
    """stream is 'llm_calls' or 'http_calls' — matches the two SQLite tables
    and produces logs/llm_calls.jsonl / logs/http_calls.jsonl."""
    _get_logger(stream).info(record)
