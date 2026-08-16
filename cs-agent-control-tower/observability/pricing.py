"""
observability/pricing.py

Per-million-token USD rates for cost calculation on every LLM call.

Rates verified against current Anthropic published pricing at the time
this module was written. Anthropic pricing has historically been stable
per model generation but DOES change (e.g. introductory pricing windows
expiring). If Finance flags a cost number that looks off, check this
table against https://www.anthropic.com/pricing first before assuming
the logging pipeline is wrong.
"""

from __future__ import annotations

# USD per 1,000,000 tokens
PRICING_PER_MTOK: dict[str, dict[str, float]] = {
    "claude-sonnet-4-6":  {"input": 3.00,  "output": 15.00},
    "claude-opus-4-8":    {"input": 5.00,  "output": 25.00},
    "claude-haiku-4-5":   {"input": 1.00,  "output": 5.00},
    "claude-sonnet-5":    {"input": 3.00,  "output": 15.00},
    "claude-opus-5":      {"input": 5.00,  "output": 25.00},
    "claude-fable-5":     {"input": 10.00, "output": 50.00},
    "claude-mythos-5":    {"input": 10.00, "output": 50.00},
}

# Fallback if a model string isn't in the table above (new/renamed model).
# Deliberately set to Sonnet-tier rates rather than $0, so an unrecognized
# model shows up as a nonzero, roughly-right cost instead of silently
# reporting free — a $0 line item is much easier to miss on an audit page
# than a plausible-but-uncertain one.
_DEFAULT_RATES = {"input": 3.00, "output": 15.00}


def calc_cost_usd(model: str, input_tokens: int, output_tokens: int) -> float:
    rates = PRICING_PER_MTOK.get(model, _DEFAULT_RATES)
    cost = (input_tokens / 1_000_000) * rates["input"] \
         + (output_tokens / 1_000_000) * rates["output"]
    return round(cost, 6)


def is_known_model(model: str) -> bool:
    return model in PRICING_PER_MTOK
