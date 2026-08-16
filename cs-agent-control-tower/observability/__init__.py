"""
observability/

Audit logging, cost tracking, and Prometheus metrics for every HTTP call
and every Anthropic LLM call made by this app.

    context.py      — ContextVars carrying user_id/run_id across threads
    pricing.py       — per-model USD/MTok rates + cost calculation
    jsonl_log.py      — durable raw JSONL logs (logs/llm_calls.jsonl, logs/http_calls.jsonl)
    db.py             — SQLite audit store + aggregation queries
    llm_logger.py     — wraps every anthropic.Anthropic.messages.create() call
    http_logger.py    — wraps every downstream SCM microservice HTTP call
    metrics.py        — Prometheus counters/histograms, scraped via GET /metrics
    audit_routes.py   — Flask blueprint: /audit page + its JSON APIs
"""
