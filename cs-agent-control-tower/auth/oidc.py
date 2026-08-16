"""
auth/oidc.py

Registers the Keycloak OIDC client used for user-facing SSO login (the
"Login" button, distinct from api_clients/keycloak_auth.py's machine-to-
machine service-account client).

This app's real Keycloak client (scm-python-chatbot) is a PUBLIC PKCE
client — no client secret. Authlib handles PKCE automatically when
code_challenge_method is set below; KEYCLOAK_APP_CLIENT_SECRET is simply
left unset (get() defaults to None), which is correct for this client
type, not a missing-config error.

Required env vars:
    KEYCLOAK_BASE_URL         (default http://localhost:8080)
    KEYCLOAK_REALM             (default scm-poc)
    KEYCLOAK_APP_CLIENT_ID     (default scm-python-chatbot)
    KEYCLOAK_APP_CLIENT_SECRET (leave unset for a public/PKCE client)

The client's Valid Redirect URIs in Keycloak admin must include this
app's actual callback URL — confirm it's set to whatever host/port this
Flask app really runs on (e.g. http://localhost:9000/auth/callback),
not whatever Home URL was set when the client was first created.
"""

from __future__ import annotations

import os

from authlib.integrations.flask_client import OAuth

KEYCLOAK_BASE_URL = os.getenv("KEYCLOAK_BASE_URL", "http://localhost:8080")
KEYCLOAK_REALM = os.getenv("KEYCLOAK_REALM", "scm-poc")

oauth = OAuth()


def init_oauth(app) -> OAuth:
    oauth.init_app(app)
    client_secret = os.getenv("KEYCLOAK_APP_CLIENT_SECRET") or None  # None => public/PKCE client
    oauth.register(
        name="keycloak",
        client_id=os.getenv("KEYCLOAK_APP_CLIENT_ID", "scm-python-chatbot"),
        client_secret=client_secret,
        server_metadata_url=(
            f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}"
            f"/.well-known/openid-configuration"
        ),
        client_kwargs={
            "scope": "openid profile email",
            "code_challenge_method": "S256",  # enables PKCE — required for a public client
        },
    )
    return oauth