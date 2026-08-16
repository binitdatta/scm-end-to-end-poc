"""
observability/http_logger.py

Single choke point for every HTTP call this app makes to the downstream
Spring Boot SCM services. api_clients/scm_client.py's _get/_post/_put
call `logged_request(...)` instead of `requests.get/post/put(...)`
directly — same raise-on-non-2xx behavior, same returned Response object,
so scm_client's ~40 endpoint functions don't need to change at all.

Logged the same three ways as llm_logger.py: JSONL, SQLite, Prometheus.
"""

from __future__ import annotations

import json
import time
from typing import Any

import requests

from . import context, db, jsonl_log, metrics

_SQLITE_BODY_CHAR_LIMIT = 50_000


def _truncate(s: str, limit: int) -> str:
    if len(s) <= limit:
        return s
    return s[:limit] + f"...[truncated, {len(s)} chars total]"


def _safe_response_body(resp: requests.Response | None) -> str | None:
    if resp is None:
        return None
    try:
        return json.dumps(resp.json(), default=str)
    except ValueError:
        # Not JSON (error page, empty body, etc.) — capture raw text instead
        return resp.text[:_SQLITE_BODY_CHAR_LIMIT] if resp.text else None


def logged_request(method: str, service: str, url: str, *,
                    timeout: int, json_body: dict[str, Any] | None = None) -> requests.Response:
    """Performs the HTTP call, raises on non-2xx (same contract as the
    requests calls it replaces), and logs the call regardless of outcome."""
    user_id = context.get_user_id()
    run_id = context.get_run_id()
    start = time.perf_counter()

    status_code: int | None = None
    error: str | None = None
    resp: requests.Response | None = None

    try:
        resp = requests.request(method, url, json=json_body, timeout=timeout)
        status_code = resp.status_code
        resp.raise_for_status()
        return resp
    except requests.exceptions.RequestException as exc:
        error = str(exc)
        if resp is not None:
            status_code = resp.status_code
        raise
    finally:
        duration_ms = (time.perf_counter() - start) * 1000
        record = {
            "ts": jsonl_log.now_iso(),
            "run_id": run_id,
            "user_id": user_id,
            "service": service,
            "method": method,
            "url": url,
            "status_code": status_code,
            "duration_ms": round(duration_ms, 2),
            "error": error,
            "request_json": json.dumps(json_body, default=str) if json_body is not None else None,
            "response_json": _safe_response_body(resp),
        }
        jsonl_log.write("http_calls", record)

        sqlite_record = dict(record)
        if sqlite_record["response_json"]:
            sqlite_record["response_json"] = _truncate(sqlite_record["response_json"], _SQLITE_BODY_CHAR_LIMIT)
        db.insert_http_call(sqlite_record)

        metrics.record_http_call(
            service=service, method=method, status_code=status_code,
            duration_s=duration_ms / 1000,
        )
