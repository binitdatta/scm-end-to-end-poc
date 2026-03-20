"""
API Client — thin HTTP wrapper around all 7 Spring Boot microservices.
Used by the Anthropic service to execute parsed API calls.
"""
import logging
import requests
from config import Config

logger = logging.getLogger(__name__)
TIMEOUT = 10


def _base(service: str) -> str:
    url = Config.SERVICE_URLS.get(service)
    if not url:
        raise ValueError(f"Unknown service: {service}")
    return url.rstrip("/")


def get(service: str, path: str) -> dict:
    """HTTP GET to a downstream service."""
    url = f"{_base(service)}{path}"
    try:
        r = requests.get(url, timeout=TIMEOUT)
        r.raise_for_status()
        return r.json()
    except requests.exceptions.ConnectionError:
        return {"success": False, "error": f"Service {service} is not reachable at {url}"}
    except requests.exceptions.HTTPError as e:
        return {"success": False, "error": str(e), "status_code": r.status_code}
    except Exception as e:
        logger.error("GET %s %s failed: %s", service, path, e)
        return {"success": False, "error": str(e)}


def post(service: str, path: str, payload: dict) -> dict:
    """HTTP POST to a downstream service."""
    url = f"{_base(service)}{path}"
    try:
        r = requests.post(url, json=payload, timeout=TIMEOUT)
        r.raise_for_status()
        return r.json()
    except requests.exceptions.ConnectionError:
        return {"success": False, "error": f"Service {service} is not reachable at {url}"}
    except requests.exceptions.HTTPError as e:
        try:
            body = r.json()
        except Exception:
            body = {}
        return {"success": False, "error": str(e), "detail": body}
    except Exception as e:
        logger.error("POST %s %s failed: %s", service, path, e)
        return {"success": False, "error": str(e)}


def health(service: str) -> str:
    """Returns 'UP' or 'DOWN'."""
    try:
        r = requests.get(f"{_base(service)}/actuator/health", timeout=4)
        data = r.json()
        return data.get("status", "DOWN")
    except Exception:
        return "DOWN"


def all_health() -> dict:
    """Returns health status for all 7 services."""
    return {svc: health(svc) for svc in Config.SERVICE_URLS}
