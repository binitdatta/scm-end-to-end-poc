"""
observability/db.py

SQLite-backed audit store. Two tables: llm_calls and http_calls.
Every write also goes to a JSONL file (see jsonl_log.py) — SQLite is the
queryable copy used by the Audit Trail page and its aggregation endpoints,
the JSONL files are the durable, append-only raw record (and the more
natural fit for log-shipping into something like Splunk/ELK later).

Uses one connection per call rather than a long-lived shared connection.
At this app's call volume (agent runs, not a high-QPS web service) the
per-call connection overhead is negligible, and it sidesteps SQLite's
"database is locked" issues that show up with a shared connection across
threads. WAL mode is enabled so audit-page reads never block a write from
an in-flight agent run.
"""

from __future__ import annotations

import os
import sqlite3
import threading
from contextlib import contextmanager
from typing import Any, Iterator

_DB_PATH = os.getenv("AUDIT_DB_PATH", "./audit.db")
_init_lock = threading.Lock()
_initialized = False

_SCHEMA = """
CREATE TABLE IF NOT EXISTS llm_calls (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    ts             TEXT    NOT NULL,
    run_id         TEXT,
    user_id        TEXT    NOT NULL,
    caller         TEXT    NOT NULL,
    model          TEXT    NOT NULL,
    input_tokens   INTEGER,
    output_tokens  INTEGER,
    cost_usd       REAL,
    duration_ms    REAL,
    status         TEXT    NOT NULL,
    error          TEXT,
    request_json   TEXT,
    response_json  TEXT
);
CREATE INDEX IF NOT EXISTS idx_llm_ts       ON llm_calls(ts);
CREATE INDEX IF NOT EXISTS idx_llm_user     ON llm_calls(user_id);
CREATE INDEX IF NOT EXISTS idx_llm_run      ON llm_calls(run_id);

CREATE TABLE IF NOT EXISTS http_calls (
    id             INTEGER PRIMARY KEY AUTOINCREMENT,
    ts             TEXT    NOT NULL,
    run_id         TEXT,
    user_id        TEXT    NOT NULL,
    service        TEXT    NOT NULL,
    method         TEXT    NOT NULL,
    url            TEXT    NOT NULL,
    status_code    INTEGER,
    duration_ms    REAL,
    error          TEXT,
    request_json   TEXT,
    response_json  TEXT
);
CREATE INDEX IF NOT EXISTS idx_http_ts      ON http_calls(ts);
CREATE INDEX IF NOT EXISTS idx_http_user    ON http_calls(user_id);
CREATE INDEX IF NOT EXISTS idx_http_run     ON http_calls(run_id);
"""


def _ensure_initialized() -> None:
    global _initialized
    if _initialized:
        return
    with _init_lock:
        if _initialized:
            return
        conn = sqlite3.connect(_DB_PATH)
        try:
            conn.execute("PRAGMA journal_mode=WAL;")
            conn.executescript(_SCHEMA)
            conn.commit()
        finally:
            conn.close()
        _initialized = True


@contextmanager
def _connect() -> Iterator[sqlite3.Connection]:
    _ensure_initialized()
    conn = sqlite3.connect(_DB_PATH, timeout=10)
    conn.row_factory = sqlite3.Row
    try:
        yield conn
    finally:
        conn.close()


def insert_llm_call(record: dict[str, Any]) -> None:
    with _connect() as conn:
        conn.execute(
            """INSERT INTO llm_calls
               (ts, run_id, user_id, caller, model, input_tokens, output_tokens,
                cost_usd, duration_ms, status, error, request_json, response_json)
               VALUES (:ts, :run_id, :user_id, :caller, :model, :input_tokens,
                       :output_tokens, :cost_usd, :duration_ms, :status, :error,
                       :request_json, :response_json)""",
            record,
        )
        conn.commit()


def insert_http_call(record: dict[str, Any]) -> None:
    with _connect() as conn:
        conn.execute(
            """INSERT INTO http_calls
               (ts, run_id, user_id, service, method, url, status_code,
                duration_ms, error, request_json, response_json)
               VALUES (:ts, :run_id, :user_id, :service, :method, :url,
                       :status_code, :duration_ms, :error, :request_json, :response_json)""",
            record,
        )
        conn.commit()


# ---------------------------------------------------------------------------
# Query helpers for the Audit Trail page
# ---------------------------------------------------------------------------

def _date_filter_clause(from_date: str | None, to_date: str | None) -> tuple[str, list]:
    clauses, params = [], []
    if from_date:
        clauses.append("ts >= ?")
        params.append(from_date)
    if to_date:
        clauses.append("ts <= ?")
        params.append(to_date + "T23:59:59")
    return (" AND " + " AND ".join(clauses)) if clauses else "", params


def summary(from_date: str | None = None, to_date: str | None = None,
            user_id: str | None = None) -> dict[str, Any]:
    where, params = _date_filter_clause(from_date, to_date)
    user_clause = ""
    if user_id:
        user_clause = " AND user_id = ?"
        params.append(user_id)

    with _connect() as conn:
        llm_row = conn.execute(
            f"""SELECT COUNT(*) AS n, COALESCE(SUM(cost_usd),0) AS cost,
                       COALESCE(SUM(input_tokens),0) AS in_tok,
                       COALESCE(SUM(output_tokens),0) AS out_tok
                FROM llm_calls WHERE 1=1 {where} {user_clause}""",
            params,
        ).fetchone()
        http_row = conn.execute(
            f"""SELECT COUNT(*) AS n,
                       SUM(CASE WHEN status_code >= 400 OR status_code IS NULL THEN 1 ELSE 0 END) AS failed
                FROM http_calls WHERE 1=1 {where} {user_clause}""",
            params,
        ).fetchone()
    return {
        "llm_call_count":   llm_row["n"],
        "llm_cost_usd":     round(llm_row["cost"], 4),
        "input_tokens":     llm_row["in_tok"],
        "output_tokens":    llm_row["out_tok"],
        "http_call_count":  http_row["n"],
        "http_failed_count": http_row["failed"] or 0,
    }


def cost_by_user(from_date: str | None = None, to_date: str | None = None) -> list[dict]:
    where, params = _date_filter_clause(from_date, to_date)
    with _connect() as conn:
        rows = conn.execute(
            f"""SELECT user_id, COUNT(*) AS calls, COALESCE(SUM(cost_usd),0) AS cost,
                       COALESCE(SUM(input_tokens),0) AS in_tok,
                       COALESCE(SUM(output_tokens),0) AS out_tok
                FROM llm_calls WHERE 1=1 {where}
                GROUP BY user_id ORDER BY cost DESC""",
            params,
        ).fetchall()
    return [dict(r) for r in rows]


def cost_by_day(from_date: str | None = None, to_date: str | None = None,
                user_id: str | None = None) -> list[dict]:
    where, params = _date_filter_clause(from_date, to_date)
    user_clause = ""
    if user_id:
        user_clause = " AND user_id = ?"
        params.append(user_id)
    with _connect() as conn:
        rows = conn.execute(
            f"""SELECT substr(ts, 1, 10) AS day, COUNT(*) AS calls,
                       COALESCE(SUM(cost_usd),0) AS cost
                FROM llm_calls WHERE 1=1 {where} {user_clause}
                GROUP BY day ORDER BY day ASC""",
            params,
        ).fetchall()
    return [dict(r) for r in rows]


def cost_by_month(from_date: str | None = None, to_date: str | None = None,
                   user_id: str | None = None) -> list[dict]:
    where, params = _date_filter_clause(from_date, to_date)
    user_clause = ""
    if user_id:
        user_clause = " AND user_id = ?"
        params.append(user_id)
    with _connect() as conn:
        rows = conn.execute(
            f"""SELECT substr(ts, 1, 7) AS month, COUNT(*) AS calls,
                       COALESCE(SUM(cost_usd),0) AS cost
                FROM llm_calls WHERE 1=1 {where} {user_clause}
                GROUP BY month ORDER BY month ASC""",
            params,
        ).fetchall()
    return [dict(r) for r in rows]


def recent_llm_calls(limit: int = 50, user_id: str | None = None,
                      from_date: str | None = None, to_date: str | None = None) -> list[dict]:
    where, params = _date_filter_clause(from_date, to_date)
    user_clause = ""
    if user_id:
        user_clause = " AND user_id = ?"
        params.append(user_id)
    params.append(limit)
    with _connect() as conn:
        rows = conn.execute(
            f"""SELECT * FROM llm_calls WHERE 1=1 {where} {user_clause}
                ORDER BY id DESC LIMIT ?""",
            params,
        ).fetchall()
    return [dict(r) for r in rows]


def recent_http_calls(limit: int = 50, user_id: str | None = None,
                       from_date: str | None = None, to_date: str | None = None) -> list[dict]:
    where, params = _date_filter_clause(from_date, to_date)
    user_clause = ""
    if user_id:
        user_clause = " AND user_id = ?"
        params.append(user_id)
    params.append(limit)
    with _connect() as conn:
        rows = conn.execute(
            f"""SELECT * FROM http_calls WHERE 1=1 {where} {user_clause}
                ORDER BY id DESC LIMIT ?""",
            params,
        ).fetchall()
    return [dict(r) for r in rows]
