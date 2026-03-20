# cs-ui-dashboard
**ERP Simulation UI — Bootstrap 5 Dark Theme Dashboard**

Spring Boot 3.4.3 | Thymeleaf | Bootstrap 5 | Port 8090

---

## Overview

A unified BFF (Backend for Frontend) orchestrator that provides a professional dark-themed
dashboard across all 7 ERP microservices. Each service has its own page with:

- **Data tables** showing live records from the downstream service
- **Data entry panels** for creating records and driving lifecycle transitions
- **Response modal** showing the raw API response JSON after each action
- **Toast notifications** confirming success or error
- **Auto-refresh** after every action

The UI proxies all API calls through Spring Boot to avoid CORS issues.
No separate JS framework — just Bootstrap 5 + vanilla JS fetch calls.

---

## Setup

### Step 1 — Fix pom.xml
```bash
cd cs-ui-dashboard
sed -i '' 's|<n>cs-ui-dashboard</n>|<name>cs-ui-dashboard</name>|' pom.xml
```

### Step 2 — Prerequisites
All 7 microservices must be running:
```
cs-crm-api        → localhost:8081
cs-vendor-api     → localhost:8082
cs-procurement-api → localhost:8083
cs-wms-inbound-api → localhost:8084
cs-oms-api        → localhost:8085
cs-wms-outbound-api → localhost:8086
cs-tms-api        → localhost:8087
```

### Step 3 — Build and Run
```bash
mvn clean install -DskipTests
java -jar target/cs-ui-dashboard-1.0.0-SNAPSHOT.jar
```

### Step 4 — Open Browser
```
http://localhost:8090
```

---

## Pages

| URL | Service | Key Actions |
|-----|---------|-------------|
| `/` | Overview | Health check grid, supply chain flow, live stats |
| `/crm` | CRM (8081) | List campaigns, create campaign, launch campaign |
| `/vendor` | Vendor (8082) | Vendors, RFQs, quotes, award contract |
| `/procurement` | Procurement (8083) | POs, line items, full lifecycle |
| `/wms-inbound` | WMS Inbound (8084) | ASNs, create/receive/putaway, inventory |
| `/oms` | OMS (8085) | Store orders, regions, allocate, full lifecycle |
| `/wms-outbound` | WMS Outbound (8086) | Pick waves, shipments, dispatch |
| `/tms` | TMS (8087) | Loads, POD confirmation, transit events |

---

## Architecture

```
Browser
  ↓ fetch /api/proxy/{service}/{path}
cs-ui-dashboard:8090
  ↓ RestClient
  ├── cs-crm-api:8081
  ├── cs-vendor-api:8082
  ├── cs-procurement-api:8083
  ├── cs-wms-inbound-api:8084
  ├── cs-oms-api:8085
  ├── cs-wms-outbound-api:8086
  └── cs-tms-api:8087
```

All frontend JavaScript calls go through `/api/proxy/{service}/**` which the
`ApiController` forwards to the correct downstream service using named RestClient beans.
