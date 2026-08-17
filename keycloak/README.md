# SCM POC — Keycloak 26 Security Integration Guide

This realm file contains hardcoded client secrets and test user
    passwords intentionally designed for local POC use only.
    Never reuse these credentials in any real environment.
## Architecture Overview

```
Browser
  │
  ├─► http://localhost:5000/         (public — no login)
  ├─► http://localhost:5000/architecture (public)
  │
  └─► http://localhost:5000/chat     ──► Keycloak PKCE login required
      http://localhost:5000/explorer         (scm-python-chatbot, public client)
      http://localhost:5000/events
      http://localhost:5000/bi

Python Flask (5000)
  │  M2M client_credentials token (scm-service-client)
  ├─► cs-crm-api          :8081  (OAuth2 Resource Server)
  ├─► cs-vendor-api       :8082  (OAuth2 Resource Server)
  ├─► cs-procurement-api  :8083  (OAuth2 Resource Server)
  ├─► cs-wms-inbound-api  :8084  (OAuth2 Resource Server)
  ├─► cs-oms-api          :8085  (OAuth2 Resource Server)
  ├─► cs-wms-outbound-api :8086  (OAuth2 Resource Server)
  └─► cs-tms-api          :8087  (OAuth2 Resource Server)

Browser → cs-ui-dashboard :8090  (OAuth2 Client — Authorization Code)
  │  access token forwarded to all downstream APIs
  └─► same 7 resource servers above

Keycloak 26          :8080   realm: scm-poc
```

---

## Step 1 — Import the Keycloak Realm

Keycloak must be running on port 8080 (standalone, no Docker needed).

```bash
# Start Keycloak in dev mode (first-time setup)
cd /path/to/keycloak-26.x.x
bin/kc.sh start-dev --http-port=8080

# Import the realm (in a second terminal)
bin/kc.sh import --file /path/to/scm-poc-realm.json
```

Or via the Admin Console UI:
1. Open http://localhost:8080/admin
2. Login with admin / admin
3. Top-left dropdown → **Create Realm**
4. Click **Browse** → select `scm-poc-realm.json` → **Create**

After import you will have:
- Realm: `scm-poc`
- 3 Realm roles: `scm_admin`, `scm_manager`, `scm_viewer`
- 3 test users (see credentials below)
- 9 clients pre-configured

### Test User Credentials
| Username      | Password       | Roles                              |
|---------------|----------------|------------------------------------|
| scm.admin     | Admin@2025!    | scm_admin + scm_manager + scm_viewer |
| scm.manager   | Manager@2025!  | scm_manager + scm_viewer           |
| scm.viewer    | Viewer@2025!   | scm_viewer                         |

---

## Step 2 — Update Each Spring Boot REST API

Do this for: cs-crm-api, cs-vendor-api, cs-procurement-api,
             cs-wms-inbound-api, cs-oms-api, cs-wms-outbound-api, cs-tms-api

### 2a. Add pom.xml dependencies
Open `pom-dependency-additions.xml` for the service and add the two
`<dependency>` blocks inside your existing `<dependencies>` section.

```xml
<!-- Spring Security core -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-security</artifactId>
</dependency>

<!-- OAuth2 Resource Server (JWT Bearer token validation) -->
<dependency>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-oauth2-resource-server</artifactId>
</dependency>
```

### 2b. Add SecurityConfig.java
Copy `SecurityConfig.java` from the patch folder into:
```
src/main/java/com/enterprise/<package>/config/SecurityConfig.java
```

Package mapping:
| Service              | Destination package                      |
|----------------------|------------------------------------------|
| cs-crm-api           | com.enterprise.cscrm.config              |
| cs-vendor-api        | com.enterprise.csvendor.config           |
| cs-procurement-api   | com.enterprise.csprocurement.config      |
| cs-wms-inbound-api   | com.enterprise.cswmsinbound.config       |
| cs-oms-api           | com.enterprise.csoms.config              |
| cs-wms-outbound-api  | com.enterprise.cswmsoutbound.config      |
| cs-tms-api           | com.enterprise.cstms.config              |

### 2c. Append application.properties
Paste the contents of `application-security-additions.properties` at the
bottom of the service's `application.properties`.

Key line (same for all 7 services):
```properties
spring.security.oauth2.resourceserver.jwt.issuer-uri=http://localhost:8080/realms/scm-poc
```

### 2d. Rebuild and restart
```bash
mvn clean package -DskipTests
java -jar target/<service>-0.0.1-SNAPSHOT.jar
```

Test with a valid token:
```bash
# Get a token (scm.admin)
TOKEN=$(curl -s -X POST http://localhost:8080/realms/scm-poc/protocol/openid-connect/token \
  -d "grant_type=password&client_id=scm-python-chatbot&username=scm.admin&password=Admin@2025!&scope=openid" \
  | jq -r '.access_token')

# Call a protected endpoint
curl -H "Authorization: Bearer $TOKEN" http://localhost:8081/api/v1/campaigns | jq .

# Confirm 401 without token
curl -i http://localhost:8081/api/v1/campaigns
```

---

## Step 3 — Update cs-ui-dashboard (Thymeleaf OAuth2 Client)

### 3a. Add pom.xml dependencies
See `cs-ui-dashboard/pom-dependency-additions.xml`

### 3b. Add SecurityConfig.java
```
src/main/java/com/enterprise/csui/config/SecurityConfig.java
```

### 3c. Append application.properties
See `cs-ui-dashboard/application-security-additions.properties`

### 3d. Update Thymeleaf templates
Add the `sec:` namespace and conditionally show user info:

```html
<!-- In base.html <html> tag: -->
<html xmlns:th="http://www.thymeleaf.org"
      xmlns:sec="http://www.thymeleaf.org/extras/spring-security">

<!-- Show username in navbar: -->
<span sec:authentication="name"></span>

<!-- Show logout button: -->
<a th:href="@{/logout}">Logout</a>

<!-- Role-based content: -->
<div sec:authorize="hasRole('scm_admin')">Admin-only section</div>
```

---

## Step 4 — Update Python Flask Chatbot (cs-control-tower)

### 4a. Install new dependency
```bash
pip install requests  # already there; nothing new needed
# requests is the only lib used by keycloak_auth.py
```

### 4b. Copy patch files
```
keycloak_auth.py   → cs-control-tower/keycloak_auth.py
app.py             → cs-control-tower/app.py          (replace existing)
api_client.py      → cs-control-tower/services/api_client.py  (replace existing)
_auth_nav.html     → cs-control-tower/ui/templates/partials/_auth_nav.html
```

### 4c. Add to .env
Paste `dot-env-additions.env` contents into your `.env` file.
Generate a real FLASK_SECRET_KEY:
```bash
python3 -c "import secrets; print(secrets.token_hex(32))"
```

### 4d. Update your base Jinja2 template navbar
```html
{# In ui/templates/base.html — inside your <nav> #}
{% include "partials/_auth_nav.html" %}
```

### 4e. Pass current_user to all protected templates
Each protected route in the new `app.py` passes `current_user=g.user`.
In your templates, access it as `{{ current_user.username }}` etc.

### 4f. Restart
```bash
python app.py
```

Visit http://localhost:5000 — home page loads without login.
Click Chat or any protected link — redirected to Keycloak login.
Login with scm.manager / Manager@2025! — redirected back to the chat page.

---

## Keycloak Endpoint Reference

| Purpose                  | URL                                                                 |
|--------------------------|---------------------------------------------------------------------|
| Admin Console            | http://localhost:8080/admin                                         |
| Realm well-known         | http://localhost:8080/realms/scm-poc/.well-known/openid-configuration |
| Authorization endpoint   | http://localhost:8080/realms/scm-poc/protocol/openid-connect/auth  |
| Token endpoint           | http://localhost:8080/realms/scm-poc/protocol/openid-connect/token |
| JWKS (public keys)       | http://localhost:8080/realms/scm-poc/protocol/openid-connect/certs |
| Userinfo endpoint        | http://localhost:8080/realms/scm-poc/protocol/openid-connect/userinfo |
| End session (logout)     | http://localhost:8080/realms/scm-poc/protocol/openid-connect/logout |

---

## Quick Token Test Commands

```bash
BASE="http://localhost:8080/realms/scm-poc/protocol/openid-connect/token"

# ── Password grant (test only — not used in production) ──────────────────────
TOKEN=$(curl -s -X POST "$BASE" \
  -d "grant_type=password" \
  -d "client_id=scm-python-chatbot" \
  -d "username=scm.admin&password=Admin@2025!" \
  -d "scope=openid" | jq -r '.access_token')

echo $TOKEN | cut -d. -f2 | base64 -d 2>/dev/null | jq .  # decode payload

# ── client_credentials (M2M — as Python chatbot does) ────────────────────────
curl -s -X POST "$BASE" \
  -d "grant_type=client_credentials" \
  -d "client_id=scm-service-client" \
  -d "client_secret=scm-service-client-secret-2025" \
  | jq '{access_token_preview: .access_token[0:60], expires_in}'

# ── Call a resource server with M2M token ─────────────────────────────────────
M2M=$(curl -s -X POST "$BASE" \
  -d "grant_type=client_credentials" \
  -d "client_id=scm-service-client" \
  -d "client_secret=scm-service-client-secret-2025" \
  | jq -r '.access_token')

curl -H "Authorization: Bearer $M2M" http://localhost:8081/api/v1/campaigns | jq .
curl -H "Authorization: Bearer $M2M" http://localhost:8082/api/v1/rfqs       | jq .
curl -H "Authorization: Bearer $M2M" http://localhost:8085/api/v1/orders     | jq .

# ── Verify 401 without token ──────────────────────────────────────────────────
curl -i http://localhost:8081/api/v1/campaigns | head -3

# ── Actuator still open (permit-all) ─────────────────────────────────────────
curl http://localhost:8081/actuator/health | jq .
```

---

## Client Secrets Summary

| Client ID              | Type          | Secret                           |
|------------------------|---------------|----------------------------------|
| scm-python-chatbot     | Public/PKCE   | (none — public client)           |
| scm-service-client     | Confidential  | scm-service-client-secret-2025   |
| scm-ui-dashboard       | Confidential  | scm-ui-dashboard-secret-2025     |
| cs-crm-api             | Resource Srv  | cs-crm-api-secret-2025           |
| cs-vendor-api          | Resource Srv  | cs-vendor-api-secret-2025        |
| cs-procurement-api     | Resource Srv  | cs-procurement-api-secret-2025   |
| cs-wms-inbound-api     | Resource Srv  | cs-wms-inbound-api-secret-2025   |
| cs-oms-api             | Resource Srv  | cs-oms-api-secret-2025           |
| cs-wms-outbound-api    | Resource Srv  | cs-wms-outbound-api-secret-2025  |
| cs-tms-api             | Resource Srv  | cs-tms-api-secret-2025           |

Note: Resource server clients don't need their secrets in application.properties —
Spring validates tokens by fetching Keycloak's public JWKS keys, not the client secret.
The secrets exist in Keycloak but the services themselves only need issuer-uri.
