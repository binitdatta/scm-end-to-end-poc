"""
Anthropic AI Service — Two-Pass Natural Language Engine
=======================================================

Pass 1 — Parse:
  User's English question → Claude → structured JSON describing which
  service to call, the HTTP method, the path, and the request body.

Pass 2 — Narrate:
  Raw JSON API response → Claude → friendly English answer for the user.

This allows the chat interface to feel like talking to a knowledgeable
supply chain manager who has live access to every system.
"""
import json
import logging
from typing import Optional
import anthropic
from config import Config

logger = logging.getLogger(__name__)

# ---------------------------------------------------------------------------
# System prompt — teaches Claude the full API surface of all 7 services
# ---------------------------------------------------------------------------
SYSTEM_PROMPT = """You are the AI assistant for the Burger Bliss ERP Control Tower.
You have expert knowledge of a toy surprise campaign supply chain system consisting of
7 Spring Boot microservices running on localhost.

SERVICE DIRECTORY:
- crm        → http://localhost:8081  — Campaigns
- vendor     → http://localhost:8082  — Vendors, RFQs, Quotes
- procurement → http://localhost:8083  — Purchase Orders
- wms-inbound → http://localhost:8084  — ASNs, Receiving, Inventory
- oms         → http://localhost:8085  — Store Orders, Regions, Allocation
- wms-outbound → http://localhost:8086  — Pick Waves, Shipments
- tms         → http://localhost:8087  — Delivery Loads, Store Deliveries, POD

KEY API ENDPOINTS:
crm:
  GET  /api/v1/campaigns
  GET  /api/v1/campaigns/{id}
  POST /api/v1/campaigns/{id}/launch

vendor:
  GET  /api/v1/vendors
  GET  /api/v1/rfqs
  GET  /api/v1/rfqs/{id}/quotes

procurement:
  GET  /api/v1/purchase-orders
  GET  /api/v1/purchase-orders/{id}

wms-inbound:
  GET  /api/v1/asns
  GET  /api/v1/inventory/campaign/SUMMER25-TOY
  GET  /api/v1/inventory/sku/{sku}/campaign/{campaign}

oms:
  GET  /api/v1/store-orders
  GET  /api/v1/store-orders/status/{status}
  GET  /api/v1/regions
  GET  /api/v1/inventory/sku/{sku}/campaign/{campaign}

wms-outbound:
  GET  /api/v1/pick-waves
  GET  /api/v1/shipments

tms:
  GET  /api/v1/delivery-loads
  GET  /api/v1/delivery-loads/status/{status}
  GET  /api/v1/delivery-loads/campaign/{campaign}
  GET  /api/v1/delivery-loads/{id}

CAMPAIGN: SUMMER25-TOY
SKUs: TOY-DINO-MIX-001, TOY-SPACE-MIX-001

When asked to PARSE a question, respond ONLY with valid JSON in this exact format:
{
  "service": "<service-name>",
  "method": "GET" | "POST",
  "path": "/api/v1/...",
  "payload": {} | null,
  "intent_summary": "one-line description of what we are fetching"
}

If the question cannot be answered by calling one of the APIs above, respond with:
{
  "service": null,
  "method": null,
  "path": null,
  "payload": null,
  "intent_summary": "general_knowledge",
  "direct_answer": "your direct answer here"
}
"""

NARRATOR_SYSTEM = """You are the AI assistant for the Burger Bliss ERP Control Tower.
Your job is to transform raw JSON API responses into clear, friendly, business-focused
English summaries. Be concise but informative. Use bullet points where helpful.
Highlight key numbers, statuses, and any anomalies. Address the user directly.
Do not repeat the raw JSON. Speak like a knowledgeable supply chain analyst.
"""


def _client() -> anthropic.Anthropic:
    return anthropic.Anthropic(api_key=Config.ANTHROPIC_API_KEY)


def parse_question(question: str) -> dict:
    """
    Pass 1: Convert an English question into a structured API call descriptor.
    Returns a dict with keys: service, method, path, payload, intent_summary.
    """
    if not Config.ANTHROPIC_API_KEY:
        return {
            "service": None, "method": None, "path": None,
            "payload": None, "intent_summary": "error",
            "direct_answer": "ANTHROPIC_API_KEY is not set in your .env file."
        }
    try:
        client = _client()
        message = client.messages.create(
            model=Config.ANTHROPIC_MODEL,
            max_tokens=512,
            system=SYSTEM_PROMPT,
            messages=[{"role": "user", "content": f"PARSE this question: {question}"}]
        )
        raw = message.content[0].text.strip()
        # Strip markdown code fences if present
        if raw.startswith("```"):
            raw = raw.split("```")[1]
            if raw.startswith("json"):
                raw = raw[4:]
        return json.loads(raw.strip())
    except json.JSONDecodeError as e:
        logger.error("Parse JSON decode error: %s", e)
        return {"service": None, "method": None, "path": None,
                "payload": None, "intent_summary": "parse_error",
                "direct_answer": "I could not understand how to query that. Please rephrase."}
    except Exception as e:
        logger.error("Parse error: %s", e)
        return {"service": None, "method": None, "path": None,
                "payload": None, "intent_summary": "error",
                "direct_answer": f"Error contacting Anthropic API: {str(e)}"}


def narrate_response(question: str, intent: str, api_data: dict) -> str:
    """
    Pass 2: Convert raw API JSON into a friendly English answer.
    """
    if not Config.ANTHROPIC_API_KEY:
        return "ANTHROPIC_API_KEY is not set. Please add it to your .env file."
    try:
        client = _client()
        prompt = f"""The user asked: "{question}"

We called the API with intent: "{intent}"

The API returned this JSON:
{json.dumps(api_data, indent=2, default=str)[:6000]}

Please provide a clear, friendly, business-focused answer to the user's question
based on this data."""

        message = client.messages.create(
            model=Config.ANTHROPIC_MODEL,
            max_tokens=1024,
            system=NARRATOR_SYSTEM,
            messages=[{"role": "user", "content": prompt}]
        )
        return message.content[0].text.strip()
    except Exception as e:
        logger.error("Narrate error: %s", e)
        return f"I retrieved the data but encountered an error generating the summary: {str(e)}"


def answer_question(question: str) -> dict:
    """
    Full two-pass pipeline.
    Returns:
        {
            "answer": str,           # English response for the user
            "service": str | None,   # Which service was called
            "endpoint": str | None,  # Path that was called
            "api_payload": dict,     # Request payload (if POST)
            "raw_json": dict,        # Raw API response
            "intent": str,           # What we understood the question to mean
        }
    """
    # Pass 1 — parse
    parsed = parse_question(question)

    # General knowledge / error path (no API call needed)
    if parsed.get("service") is None:
        return {
            "answer":      parsed.get("direct_answer", "I don't know how to answer that."),
            "service":     None,
            "endpoint":    None,
            "api_payload": None,
            "raw_json":    None,
            "intent":      parsed.get("intent_summary", ""),
        }

    service  = parsed["service"]
    method   = parsed.get("method", "GET").upper()
    path     = parsed["path"]
    payload  = parsed.get("payload") or {}
    intent   = parsed.get("intent_summary", "")

    # Execute API call
    from services.api_client import get, post
    if method == "POST":
        raw_json = post(service, path, payload)
    else:
        raw_json = get(service, path)

    # Pass 2 — narrate
    answer = narrate_response(question, intent, raw_json)

    return {
        "answer":      answer,
        "service":     service,
        "endpoint":    f"{method} {path}",
        "api_payload": payload if method == "POST" else None,
        "raw_json":    raw_json,
        "intent":      intent,
    }
