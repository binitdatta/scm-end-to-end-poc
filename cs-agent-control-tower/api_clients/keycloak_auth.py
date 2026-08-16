"""
api_clients/keycloak_auth.py

Acquires and caches an OAuth2 client-credentials access token, used to
authenticate every scm_client.py call to the downstream CRM/Vendor/
Procurement/WMS-Inbound/OMS/WMS-Outbound/TMS services now that they sit
behind Keycloak.

Deliberately a SEPARATE Keycloak client from the one used for user-facing
SSO login (see auth/oidc.py) — least-privilege: this client only needs
permission to call the SCM APIs as a service account, not to authenticate
humans. Maps to your existing confidential client "scm-service-client",
which has "Service accounts enabled" turned on.

Required env vars:
    KEYCLOAK_BASE_URL            (default http://localhost:8080)
    KEYCLOAK_REALM                (default scm-poc)
    KEYCLOAK_SERVICE_CLIENT_ID    (default scm-service-client)
    KEYCLOAK_SERVICE_CLIENT_SECRET
"""

from __future__ import annotations

import logging
import os
import threading
import time

import requests

logger = logging.getLogger(__name__)

KEYCLOAK_BASE_URL = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "scm-poc")
_CLIENT_ID = os.getenv("KEYCLOAK_SERVICE_CLIENT_ID", "scm-service-client")
_CLIENT_SECRET = os.getenv("KEYCLOAK_SERVICE_CLIENT_SECRET", "")

_TOKEN_URL = f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/token"

_lock = threading.Lock()
_cached_token: str | None = None
_expires_at: float = 0.0  # epoch seconds


def get_service_token() -> str:
    """Returns a valid access token, refreshing ~30s before expiry.
    Thread-safe — scm_client.py calls run from multiple agent-run threads."""
    global _cached_token, _expires_at

    now = time.time()
    if _cached_token and now < _expires_at - 30:
        return _cached_token

    with _lock:
        now = time.time()
        if _cached_token and now < _expires_at - 30:
            return _cached_token

        if not _CLIENT_ID or not _CLIENT_SECRET:
            raise RuntimeError(
                "KEYCLOAK_SERVICE_CLIENT_ID / KEYCLOAK_SERVICE_CLIENT_SECRET "
                "are not set. Get the secret from Keycloak admin -> Clients -> "
                "scm-service-client -> Credentials, and set "
                "KEYCLOAK_SERVICE_CLIENT_SECRET in your .env."
            )

        resp = requests.post(
            _TOKEN_URL,
            data={
                "grant_type": "client_credentials",
                "client_id": _CLIENT_ID,
                "client_secret": _CLIENT_SECRET,
            },
            timeout=10,
        )
        resp.raise_for_status()
        payload = resp.json()
        _cached_token = payload["access_token"]
        _expires_at = now + int(payload.get("expires_in", 60))
        logger.info("Acquired new Keycloak service-account token (expires in %ss)",
                     payload.get("expires_in"))
        return _cached_token


def auth_header() -> dict[str, str]:
    return {"Authorization": f"Bearer {get_service_token()}"}