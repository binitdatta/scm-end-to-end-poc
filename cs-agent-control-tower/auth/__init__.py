"""
auth/

Real Keycloak SSO (Authorization Code flow via Authlib) for user-facing
login — distinct from api_clients/keycloak_auth.py, which is the
machine-to-machine client-credentials client this app uses to call the
downstream SCM services.

    oidc.py    — Authlib OAuth client registration
    routes.py  — /login, /auth/callback, /logout, /me
"""
