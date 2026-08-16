"""
observability/llm_logger.py

Single choke point for every Anthropic API call made anywhere in this
app. planner.py and narrator.py call `log_llm_call(...)` instead of
`client.messages.create(...)` directly — same arguments, same return
value (the raw anthropic Message), so no other call-site logic changes.

Every call is recorded three ways:
  1. logs/llm_calls.jsonl — full request + full response, one line per call
  2. audit.db (llm_calls table) — same data, queryable for the Audit Trail page
  3. Prometheus counters/histograms — for scraping/alerting, not per-call detail

If the Anthropic call raises, the exception is re-raised unchanged after
logging what's known (no tokens/cost, but caller/model/error/duration are
still captured) — callers' existing try/except blocks keep working exactly
as before.
"""

from __future__ import annotations

import json
import time
from typing import Any

import anthropic

from . import context, db, jsonl_log, metrics
from .pricing import calc_cost_usd

# Anthropic request/response bodies can be large (long system prompts,
# big context dumps). Full bodies go to JSONL (disk is cheap); SQLite
# keeps a possibly-truncated copy so the audit DB doesn't bloat — the
# Audit Trail UI links back to "see full record" territory by re-reading
# JSONL for anything truncated, but in practice these payloads are small
# enough (a few KB) that truncation rarely triggers.
_SQLITE_BODY_CHAR_LIMIT = 50_000


def _serialize_content(content: Any) -> Any:
    """Anthropic message.content is a list of ContentBlock objects
    (TextBlock, ToolUseBlock, etc.) — not directly JSON-serializable."""
    if isinstance(content, list):
        out = []
        for block in content:
            if hasattr(block, "model_dump"):
                out.append(block.model_dump())
            elif hasattr(block, "text"):
                out.append({"type": "text", "text": block.text})
            else:
                out.append(str(block))
        return out
    return content


def _truncate(s: str, limit: int) -> str:
    if len(s) <= limit:
        return s
    return s[:limit] + f"...[truncated, {len(s)} chars total]"


def log_llm_call(
    client: anthropic.Anthropic,
    *,
    caller: str,
    model: str,
    max_tokens: int,
    messages: list[dict[str, Any]],
    system: str | None = None,
    **extra_kwargs: Any,
):
    """Drop-in wrapper around client.messages.create(). Returns the same
    anthropic.types.Message object create() would return; raises the same
    exceptions. `caller` is a short label (e.g. "planner.plan") identifying
    which function made the call, for the per-call-type breakdown."""
    user_id = context.get_user_id()
    run_id = context.get_run_id()
    start = time.perf_counter()

    status = "success"
    error: str | None = None
    message = None

    try:
        message = client.messages.create(
            model=model, max_tokens=max_tokens, system=system,
            messages=messages, **extra_kwargs,
        )
        return message
    except Exception as exc:
        status = "error"
        error = str(exc)
        raise
    finally:
        duration_ms = (time.perf_counter() - start) * 1000
        input_tokens = message.usage.input_tokens if message else 0
        output_tokens = message.usage.output_tokens if message else 0
        cost_usd = calc_cost_usd(model, input_tokens, output_tokens) if message else 0.0

        request_payload = {
            "system": system, "messages": messages,
            "max_tokens": max_tokens, **extra_kwargs,
        }
        response_payload = (
            {"content": _serialize_content(message.content), "stop_reason": message.stop_reason}
            if message else None
        )

        request_json = json.dumps(request_payload, default=str)
        response_json = json.dumps(response_payload, default=str) if response_payload else None

        record = {
            "ts": jsonl_log.now_iso(),
            "run_id": run_id,
            "user_id": user_id,
            "caller": caller,
            "model": model,
            "input_tokens": input_tokens,
            "output_tokens": output_tokens,
            "cost_usd": cost_usd,
            "duration_ms": round(duration_ms, 2),
            "status": status,
            "error": error,
            "request_json": request_json,
            "response_json": response_json,
        }
        jsonl_log.write("llm_calls", record)

        sqlite_record = dict(record)
        sqlite_record["request_json"] = _truncate(request_json, _SQLITE_BODY_CHAR_LIMIT)
        if response_json:
            sqlite_record["response_json"] = _truncate(response_json, _SQLITE_BODY_CHAR_LIMIT)
        db.insert_llm_call(sqlite_record)

        metrics.record_llm_call(
            caller=caller, model=model, status=status,
            input_tokens=input_tokens, output_tokens=output_tokens,
            cost_usd=cost_usd, duration_s=duration_ms / 1000,
        )
