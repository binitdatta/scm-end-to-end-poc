"""
observability/metrics.py

Prometheus metrics, exposed via GET /metrics (see app.py). This is the
actual Prometheus integration — a pull-based scrape endpoint with
counters and histograms — as opposed to the JSONL/SQLite audit trail,
which is a different system serving a different purpose (per-call detail
and per-user/day/month cost breakdown for the Audit Trail page).

Typical Prometheus scrape config point at this app:

    scrape_configs:
      - job_name: cs-agent-control-tower
        static_configs:
          - targets: ["localhost:9000"]
        metrics_path: /metrics
"""

from __future__ import annotations

from prometheus_client import Counter, Histogram

LLM_REQUESTS_TOTAL = Counter(
    "llm_requests_total",
    "Total Anthropic API calls made by this app",
    ["caller", "model", "status"],
)
LLM_INPUT_TOKENS_TOTAL = Counter(
    "llm_input_tokens_total",
    "Total input tokens sent to Anthropic",
    ["caller", "model"],
)
LLM_OUTPUT_TOKENS_TOTAL = Counter(
    "llm_output_tokens_total",
    "Total output tokens received from Anthropic",
    ["caller", "model"],
)
LLM_COST_USD_TOTAL = Counter(
    "llm_cost_usd_total",
    "Total estimated USD cost of Anthropic API calls",
    ["caller", "model"],
)
LLM_REQUEST_DURATION_SECONDS = Histogram(
    "llm_request_duration_seconds",
    "Anthropic API call latency",
    ["caller", "model"],
)

HTTP_REQUESTS_TOTAL = Counter(
    "scm_http_requests_total",
    "Total downstream SCM microservice HTTP calls made by this app",
    ["service", "method", "status_code"],
)
HTTP_REQUEST_DURATION_SECONDS = Histogram(
    "scm_http_request_duration_seconds",
    "Downstream SCM microservice HTTP call latency",
    ["service", "method"],
)


def record_llm_call(*, caller: str, model: str, status: str,
                     input_tokens: int, output_tokens: int,
                     cost_usd: float, duration_s: float) -> None:
    LLM_REQUESTS_TOTAL.labels(caller=caller, model=model, status=status).inc()
    LLM_INPUT_TOKENS_TOTAL.labels(caller=caller, model=model).inc(input_tokens)
    LLM_OUTPUT_TOKENS_TOTAL.labels(caller=caller, model=model).inc(output_tokens)
    LLM_COST_USD_TOTAL.labels(caller=caller, model=model).inc(cost_usd)
    LLM_REQUEST_DURATION_SECONDS.labels(caller=caller, model=model).observe(duration_s)


def record_http_call(*, service: str, method: str, status_code: int | None,
                      duration_s: float) -> None:
    code_label = str(status_code) if status_code is not None else "error"
    HTTP_REQUESTS_TOTAL.labels(service=service, method=method, status_code=code_label).inc()
    HTTP_REQUEST_DURATION_SECONDS.labels(service=service, method=method).observe(duration_s)
