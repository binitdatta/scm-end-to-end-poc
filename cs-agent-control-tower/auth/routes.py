"""
auth/routes.py

/login          — redirects to Keycloak's authorization endpoint
/auth/callback  — Keycloak redirects back here with the code; exchanges
                   it for tokens, pulls the username out of the ID token
                   userinfo, and stores it in the Flask session
/logout         — clears the local session AND redirects through
                   Keycloak's end-session endpoint (same pattern as your
                   Spring Security apps' logoutSuccessUrl), so this is a
                   real SSO logout, not just a local cookie clear
/me             — small JSON endpoint the frontend can poll to know who's
                   logged in (used by console.html's navbar)
"""

from __future__ import annotations

import os

from flask import Blueprint, jsonify, redirect, session, url_for

from .oidc import oauth, KEYCLOAK_BASE_URL, KEYCLOAK_REALM

bp = Blueprint("auth", __name__)


@bp.get("/login")
def login():
    redirect_uri = url_for("auth.callback", _external=True)
    return oauth.keycloak.authorize_redirect(redirect_uri)


@bp.get("/auth/callback")
def callback():
    token = oauth.keycloak.authorize_access_token()
    userinfo = token.get("userinfo")
    if not userinfo:
        userinfo = oauth.keycloak.userinfo(token=token)
    session["user_id"] = userinfo.get("preferred_username") or userinfo.get("sub") or "unknown"
    session["user_email"] = userinfo.get("email")
    session["id_token"] = token.get("id_token")
    return redirect(url_for("index"))


@bp.get("/logout")
def logout():
    id_token = session.pop("id_token", None)
    session.clear()

    client_id = os.getenv("KEYCLOAK_APP_CLIENT_ID", "")
    post_logout_uri = url_for("index", _external=True)
    end_session_url = (
        f"{KEYCLOAK_BASE_URL}/realms/{KEYCLOAK_REALM}/protocol/openid-connect/logout"
        f"?post_logout_redirect_uri={post_logout_uri}&client_id={client_id}"
    )
    if id_token:
        end_session_url += f"&id_token_hint={id_token}"
    return redirect(end_session_url)


@bp.get("/me")
def me():
    return jsonify({
        "authenticated": bool(session.get("user_id")),
        "user_id": session.get("user_id"),
        "email": session.get("user_email"),
    })
