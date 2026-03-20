# cs-vendor-api
**Vendor Portal ERP — Toy Surprise Campaign Simulation**

Spring Boot 3.4.3 | JDK 21 | MySQL 8 | RabbitMQ | JPA | Port 8082

---

## Domain

Manages the full vendor sourcing lifecycle for toy procurement:
- Vendor registration (China, Vietnam, India, Thailand suppliers)
- RFQ (Request for Quote) issuance for each campaign
- Vendor quote submission and comparison
- Award decision — the `erp.vendor.rfq.awarded` event triggers PO creation in `cs-procurement-api`
- Vendor scorecards

---

## Project Structure

```
cs-vendor-api/
├── db/
│   ├── 01_ddl_cs_vendor.sql       ← Run first (schema + vendor_app user)
│   └── 02_seed_cs_vendor.sql      ← Run second (7 vendors, 2 RFQs, 4 quotes)
├── src/main/java/com/enterprise/csvendor/
│   ├── CsVendorApiApplication.java
│   ├── config/RabbitMQConfig.java
│   ├── controller/
│   │   ├── VendorController.java
│   │   └── RfqController.java
│   ├── dto/
│   │   ├── request/  (CreateVendorRequest, CreateRfqRequest,
│   │   │              SubmitQuoteRequest, AwardRfqRequest)
│   │   └── response/ (ApiResponse, VendorResponse, RfqResponse,
│   │                   QuoteResponse, AwardResponse)
│   ├── entity/
│   │   ├── Vendor.java
│   │   ├── Rfq.java
│   │   ├── RfqVendor.java
│   │   ├── VendorQuote.java
│   │   └── RfqAward.java
│   ├── exception/
│   │   ├── GlobalExceptionHandler.java
│   │   ├── ResourceNotFoundException.java
│   │   ├── InvalidStateException.java
│   │   └── DuplicateResourceException.java
│   ├── messaging/
│   │   ├── VendorEventMessage.java
│   │   └── VendorEventPublisher.java
│   ├── repository/
│   │   ├── VendorRepository.java
│   │   ├── RfqRepository.java
│   │   ├── VendorQuoteRepository.java
│   │   └── RfqAwardRepository.java
│   └── service/
│       ├── VendorService.java
│       └── RfqService.java
└── src/main/resources/
    └── application.properties
```

---

## Setup Steps

### Step 1 — MySQL Workbench
Run as root/admin in order:
1. `db/01_ddl_cs_vendor.sql` — creates `cs_vendor` database, `vendor_app` user (no DDL), 5 tables + indexes
2. `db/02_seed_cs_vendor.sql` — 7 vendors across 4 countries, 2 RFQs, 4 quotes for RFQ-2025-001

### Step 2 — Confirm RabbitMQ is running
```bash
brew services list | grep rabbitmq
```

### Step 3 — Open in IntelliJ
File → Open → `cs-vendor-api`. Maven auto-imports. Enable Lombok annotation processing.

### Step 4 — Run
```bash
mvn spring-boot:run
# or
mvn clean install -DskipTests && java -jar target/cs-vendor-api-1.0.0-SNAPSHOT.jar
```
Starts on **port 8082**. Both cs-crm-api (8081) and cs-vendor-api (8082) can run simultaneously.

### Step 5 — Test
```bash
chmod +x test_cs_vendor_api.sh && ./test_cs_vendor_api.sh
```

---

## REST Endpoints

| Method | Path                              | Description                              |
|--------|-----------------------------------|------------------------------------------|
| POST   | /api/v1/vendors                   | Register vendor + publish event          |
| GET    | /api/v1/vendors                   | List all vendors                         |
| GET    | /api/v1/vendors/{id}              | Get vendor by external ID                |
| GET    | /api/v1/vendors/country/{country} | Filter active vendors by country         |
| PATCH  | /api/v1/vendors/{id}/scorecard    | Update scorecard rating                  |
| POST   | /api/v1/rfqs                      | Create RFQ (DRAFT)                       |
| GET    | /api/v1/rfqs                      | List all RFQs                            |
| GET    | /api/v1/rfqs/{id}                 | Get RFQ by external ID                   |
| POST   | /api/v1/rfqs/{id}/open            | DRAFT → OPEN + publish event             |
| POST   | /api/v1/rfqs/{id}/quotes          | Vendor submits quote + publish event     |
| GET    | /api/v1/rfqs/{id}/quotes          | List all quotes for RFQ                  |
| POST   | /api/v1/rfqs/{id}/award           | Award RFQ → KEY event for procurement    |
| GET    | /api/v1/rfqs/{id}/award           | Get award record                         |
| POST   | /api/v1/rfqs/{id}/cancel          | Cancel RFQ + publish event               |
| GET    | /actuator/health                  | Health check                             |

---

## RabbitMQ Events Published

| Event                        | Routing Key                      | Consumed by          |
|------------------------------|----------------------------------|----------------------|
| Vendor registered            | `erp.vendor.vendor.created`      | Control Tower        |
| RFQ opened for bidding       | `erp.vendor.rfq.opened`          | Control Tower        |
| Vendor quote submitted       | `erp.vendor.quote.submitted`     | Control Tower        |
| **RFQ awarded to vendor**    | **`erp.vendor.rfq.awarded`**     | **cs-procurement-api** |
| RFQ cancelled                | `erp.vendor.rfq.cancelled`       | Control Tower        |

Exchange: `erp.topic.exchange` (Topic, durable, shared with cs-crm-api)

---

## Seeded Reference Data

**Vendors**
| Code        | Name                              | Country  | Rating | Lead Time |
|-------------|-----------------------------------|----------|--------|-----------|
| VND-CN-001  | Shenzhen BrightToy Manufacturing  | CHINA    | 4.20   | 45 days   |
| VND-VN-001  | Ho Chi Minh Playthings Ltd.       | VIETNAM  | 4.50   | 38 days   |
| VND-IN-001  | Pune Creative Toys Pvt. Ltd.      | INDIA    | 3.90   | 55 days   |
| VND-TH-001  | Bangkok Fun Factory Co. Ltd.      | THAILAND | 4.75   | 42 days   |
| VND-CN-002  | Guangzhou PackMaster Co.          | CHINA    | 4.00   | 30 days   |
| VND-VN-002  | Hanoi Precision Plastics          | VIETNAM  | 4.10   | 40 days   |
| VND-IN-002  | Chennai Toy Crafts Ltd.           | INDIA    | 3.20   | 60 days   |

**RFQs**
| RFQ Number    | Campaign        | Qty       | Status       |
|---------------|-----------------|-----------|--------------|
| RFQ-2025-001  | SUMMER25-TOY    | 500,000   | OPEN (4 quotes received) |
| RFQ-2025-002  | HOLIDAY25-TOY   | 1,200,000 | DRAFT        |

binit.datta@C6NWKQ290Y cs-vendor-api % chmod +x test_cs_vendor_api.sh && ./test_cs_vendor_api.sh


══════════════════════════════════════
1. List all vendors (seeded)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Vendors retrieved",
   "data": [
   {
   "externalId": "vnd-001-uuid",
   "vendorName": "Shenzhen BrightToy Manufacturing Co.",
   "vendorCode": "VND-CN-001",
   "country": "CHINA",
   "contactName": "Wei Zhang",
   "contactEmail": "wei.zhang@brighttoy.cn",
   "contactPhone": "+86-755-8801-2233",
   "address": "18 Longhua Industrial Zone, Shenzhen, Guangdong, China 518109",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 45,
   "paymentTerms": "NET30",
   "scorecardRating": 4.2,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   },
   {
   "externalId": "vnd-002-uuid",
   "vendorName": "Ho Chi Minh Playthings Ltd.",
   "vendorCode": "VND-VN-001",
   "country": "VIETNAM",
   "contactName": "Nguyen Thi Lan",
   "contactEmail": "lan.nguyen@hcmplaythings.vn",
   "contactPhone": "+84-28-3822-5511",
   "address": "45 Tan Binh Industrial Park, Ho Chi Minh City, Vietnam",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 38,
   "paymentTerms": "50% upfront, 50% on shipment",
   "scorecardRating": 4.5,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   },
   {
   "externalId": "vnd-003-uuid",
   "vendorName": "Pune Creative Toys Pvt. Ltd.",
   "vendorCode": "VND-IN-001",
   "country": "INDIA",
   "contactName": "Rajesh Mehta",
   "contactEmail": "rajesh.mehta@punecreative.in",
   "contactPhone": "+91-20-2712-8899",
   "address": "Plot 22, Bhosari MIDC Industrial Area, Pune, Maharashtra 411026, India",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 55,
   "paymentTerms": "NET45",
   "scorecardRating": 3.9,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   },
   {
   "externalId": "vnd-004-uuid",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCode": "VND-TH-001",
   "country": "THAILAND",
   "contactName": "Somchai Wattana",
   "contactEmail": "somchai@bangkokfun.co.th",
   "contactPhone": "+66-2-685-4400",
   "address": "99 Moo 4, Amata City Industrial Estate, Chonburi 20160, Thailand",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 42,
   "paymentTerms": "NET30",
   "scorecardRating": 4.75,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   },
   {
   "externalId": "vnd-005-uuid",
   "vendorName": "Guangzhou PackMaster Co.",
   "vendorCode": "VND-CN-002",
   "country": "CHINA",
   "contactName": "Li Mei",
   "contactEmail": "limei@gzpackmaster.cn",
   "contactPhone": "+86-20-6601-3344",
   "address": "88 Panyu Economic Development Zone, Guangzhou, China 511400",
   "status": "ACTIVE",
   "category": "PACKAGING",
   "leadTimeDays": 30,
   "paymentTerms": "NET30",
   "scorecardRating": 4.0,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   },
   {
   "externalId": "vnd-006-uuid",
   "vendorName": "Hanoi Precision Plastics",
   "vendorCode": "VND-VN-002",
   "country": "VIETNAM",
   "contactName": "Tran Van Duc",
   "contactEmail": "duc.tran@hanoiplastics.vn",
   "contactPhone": "+84-24-3826-7700",
   "address": "12 Quang Minh Industrial Zone, Me Linh, Hanoi, Vietnam",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 40,
   "paymentTerms": "NET30",
   "scorecardRating": 4.1,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   },
   {
   "externalId": "vnd-007-uuid",
   "vendorName": "Chennai Toy Crafts Ltd.",
   "vendorCode": "VND-IN-002",
   "country": "INDIA",
   "contactName": "Priya Rajan",
   "contactEmail": "priya@chennaicrafts.in",
   "contactPhone": "+91-44-2431-5566",
   "address": "No. 7 SIDCO Industrial Estate, Ambattur, Chennai 600058, India",
   "status": "INACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 60,
   "paymentTerms": "NET60",
   "scorecardRating": 3.2,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   }
   ],
   "timestamp": "2026-03-18T10:39:26"
   }

══════════════════════════════════════
2. Active vendors in VIETNAM
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Vendors retrieved for country: VIETNAM",
   "data": [
   {
   "externalId": "vnd-002-uuid",
   "vendorName": "Ho Chi Minh Playthings Ltd.",
   "vendorCode": "VND-VN-001",
   "country": "VIETNAM",
   "contactName": "Nguyen Thi Lan",
   "contactEmail": "lan.nguyen@hcmplaythings.vn",
   "contactPhone": "+84-28-3822-5511",
   "address": "45 Tan Binh Industrial Park, Ho Chi Minh City, Vietnam",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 38,
   "paymentTerms": "50% upfront, 50% on shipment",
   "scorecardRating": 4.5,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   },
   {
   "externalId": "vnd-006-uuid",
   "vendorName": "Hanoi Precision Plastics",
   "vendorCode": "VND-VN-002",
   "country": "VIETNAM",
   "contactName": "Tran Van Duc",
   "contactEmail": "duc.tran@hanoiplastics.vn",
   "contactPhone": "+84-24-3826-7700",
   "address": "12 Quang Minh Industrial Zone, Me Linh, Hanoi, Vietnam",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 40,
   "paymentTerms": "NET30",
   "scorecardRating": 4.1,
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   }
   ],
   "timestamp": "2026-03-18T10:39:26"
   }

══════════════════════════════════════
2b. Active vendors in THAILAND
══════════════════════════════════════
{
"success": true,
"message": "Vendors retrieved for country: THAILAND",
"data": [
{
"externalId": "vnd-004-uuid",
"vendorName": "Bangkok Fun Factory Co. Ltd.",
"vendorCode": "VND-TH-001",
"country": "THAILAND",
"contactName": "Somchai Wattana",
"contactEmail": "somchai@bangkokfun.co.th",
"contactPhone": "+66-2-685-4400",
"address": "99 Moo 4, Amata City Industrial Estate, Chonburi 20160, Thailand",
"status": "ACTIVE",
"category": "TOY_MANUFACTURER",
"leadTimeDays": 42,
"paymentTerms": "NET30",
"scorecardRating": 4.75,
"createdAt": "2026-03-18T05:38:07",
"updatedAt": "2026-03-18T05:38:07"
}
],
"timestamp": "2026-03-18T10:39:26"
}

══════════════════════════════════════
3. Create new vendor (China) → publishes erp.vendor.vendor.created
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Vendor created successfully",
   "data": {
   "externalId": "79d9792c-7311-4c7e-b0d0-9ef916bb1fb5",
   "vendorName": "Dongguan SuperToy Co. Ltd.",
   "vendorCode": "VND-CN-003",
   "country": "CHINA",
   "contactName": "Chen Wei",
   "contactEmail": "chenwei@dongguan-supertoy.cn",
   "contactPhone": "+86-769-8801-5599",
   "address": "Building 3, Houjie Town Industrial Park, Dongguan, Guangdong 523940",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 40,
   "paymentTerms": "NET30",
   "scorecardRating": 4.3,
   "createdAt": "2026-03-18T10:39:26",
   "updatedAt": "2026-03-18T10:39:26"
   },
   "timestamp": "2026-03-18T10:39:27"
   }
   ✔ New vendor externalId: 79d9792c-7311-4c7e-b0d0-9ef916bb1fb5

══════════════════════════════════════
4. Update scorecard for new vendor
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Scorecard updated",
   "data": {
   "externalId": "79d9792c-7311-4c7e-b0d0-9ef916bb1fb5",
   "vendorName": "Dongguan SuperToy Co. Ltd.",
   "vendorCode": "VND-CN-003",
   "country": "CHINA",
   "contactName": "Chen Wei",
   "contactEmail": "chenwei@dongguan-supertoy.cn",
   "contactPhone": "+86-769-8801-5599",
   "address": "Building 3, Houjie Town Industrial Park, Dongguan, Guangdong 523940",
   "status": "ACTIVE",
   "category": "TOY_MANUFACTURER",
   "leadTimeDays": 40,
   "paymentTerms": "NET30",
   "scorecardRating": 4.6,
   "createdAt": "2026-03-18T10:39:27",
   "updatedAt": "2026-03-18T10:39:27"
   },
   "timestamp": "2026-03-18T10:39:27"
   }

══════════════════════════════════════
5. List all RFQs (seeded)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "RFQs retrieved",
   "data": [
   {
   "externalId": "rfq-001-uuid",
   "rfqNumber": "RFQ-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "title": "Summer 2025 Toy Surprise \u2014 Dinosaur Figure Series",
   "description": "Sourcing 500,000 mystery dinosaur figures for kids meal toy surprise campaign. Must meet CPSC safety standards. Individually packaged in branded surprise box.",
   "toyCategory": "Dinosaur Figures",
   "quantityRequired": 500000,
   "unit": "PIECES",
   "targetUnitCostUsd": 0.85,
   "requiredByDate": "2025-04-30",
   "submissionDeadline": "2025-02-28",
   "status": "OPEN",
   "createdBy": "procurement.manager",
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   },
   {
   "externalId": "rfq-002-uuid",
   "rfqNumber": "RFQ-2025-002",
   "campaignExternalId": "camp-002-uuid",
   "campaignCode": "HOLIDAY25-TOY",
   "title": "Holiday 2025 \u2014 Collectible Figurine Series (6 Characters)",
   "description": "Sourcing 1,200,000 collectible holiday figurines across 6 character designs. Premium finish required. Full color box packaging included.",
   "toyCategory": "Collectible Figurines",
   "quantityRequired": 1200000,
   "unit": "PIECES",
   "targetUnitCostUsd": 1.2,
   "requiredByDate": "2025-10-15",
   "submissionDeadline": "2025-07-31",
   "status": "DRAFT",
   "createdBy": "procurement.manager",
   "createdAt": "2026-03-18T05:38:07",
   "updatedAt": "2026-03-18T05:38:07"
   }
   ],
   "timestamp": "2026-03-18T10:39:27"
   }

══════════════════════════════════════
6. Create new RFQ for AUTUMN25-TOY campaign
   ══════════════════════════════════════
   {
   "success": true,
   "message": "RFQ created successfully",
   "data": {
   "externalId": "f53250ae-78b3-4ae7-8640-4603c56ef069",
   "rfqNumber": "RFQ-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "title": "Summer 2025 \u2014 Space Explorer Figure Series",
   "description": "250,000 space explorer toy figures for the summer kids meal campaign. UV-safe paint required.",
   "toyCategory": "Space Explorer Figures",
   "quantityRequired": 250000,
   "unit": "PIECES",
   "targetUnitCostUsd": 0.9,
   "requiredByDate": "2025-05-15",
   "submissionDeadline": "2025-03-31",
   "status": "DRAFT",
   "createdBy": "procurement.manager",
   "createdAt": "2026-03-18T10:39:27",
   "updatedAt": "2026-03-18T10:39:27"
   },
   "timestamp": "2026-03-18T10:39:27"
   }
   ✔ New RFQ externalId: f53250ae-78b3-4ae7-8640-4603c56ef069

══════════════════════════════════════
7. Open RFQ → publishes erp.vendor.rfq.opened
   ══════════════════════════════════════
   {
   "success": true,
   "message": "RFQ opened",
   "data": {
   "externalId": "f53250ae-78b3-4ae7-8640-4603c56ef069",
   "rfqNumber": "RFQ-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "title": "Summer 2025 \u2014 Space Explorer Figure Series",
   "description": "250,000 space explorer toy figures for the summer kids meal campaign. UV-safe paint required.",
   "toyCategory": "Space Explorer Figures",
   "quantityRequired": 250000,
   "unit": "PIECES",
   "targetUnitCostUsd": 0.9,
   "requiredByDate": "2025-05-15",
   "submissionDeadline": "2025-03-31",
   "status": "OPEN",
   "createdBy": "procurement.manager",
   "createdAt": "2026-03-18T10:39:27",
   "updatedAt": "2026-03-18T10:39:27"
   },
   "timestamp": "2026-03-18T10:39:27"
   }
   ✔ Check RabbitMQ: routing key erp.vendor.rfq.opened

══════════════════════════════════════
8a. China vendor submits quote → publishes erp.vendor.quote.submitted
══════════════════════════════════════
{
"success": true,
"message": "Quote submitted successfully",
"data": {
"externalId": "7158674e-dbf1-4a7b-acf6-d21b614bac66",
"rfqNumber": "RFQ-2025-003",
"vendorExternalId": "vnd-001-uuid",
"vendorName": "Shenzhen BrightToy Manufacturing Co.",
"vendorCode": "VND-CN-001",
"vendorCountry": "CHINA",
"quotedUnitCostUsd": 0.84,
"quotedQuantity": 250000,
"totalCostUsd": 210000.0,
"leadTimeDays": 42,
"deliveryDate": "2025-05-10",
"paymentTerms": "NET30",
"notes": "Single-run production. ASTM F963 certified. Sample batch available in 2 weeks.",
"status": "SUBMITTED",
"submittedAt": "2026-03-18T10:39:27"
},
"timestamp": "2026-03-18T10:39:27"
}

══════════════════════════════════════
8b. Thailand vendor submits quote → publishes erp.vendor.quote.submitted
══════════════════════════════════════
{
"success": false,
"message": "Quotes can only be submitted to OPEN RFQs. Current: UNDER_REVIEW",
"data": null,
"timestamp": "2026-03-18T10:39:27"
}

══════════════════════════════════════
9. View all quotes for RFQ (side-by-side comparison)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Quotes retrieved",
   "data": [
   {
   "externalId": "7158674e-dbf1-4a7b-acf6-d21b614bac66",
   "rfqNumber": "RFQ-2025-003",
   "vendorExternalId": "vnd-001-uuid",
   "vendorName": "Shenzhen BrightToy Manufacturing Co.",
   "vendorCode": "VND-CN-001",
   "vendorCountry": "CHINA",
   "quotedUnitCostUsd": 0.84,
   "quotedQuantity": 250000,
   "totalCostUsd": 210000.0,
   "leadTimeDays": 42,
   "deliveryDate": "2025-05-10",
   "paymentTerms": "NET30",
   "notes": "Single-run production. ASTM F963 certified. Sample batch available in 2 weeks.",
   "status": "SUBMITTED",
   "submittedAt": "2026-03-18T10:39:27"
   }
   ],
   "timestamp": "2026-03-18T10:39:27"
   }

══════════════════════════════════════
10. Award RFQ to Thailand vendor → publishes erp.vendor.rfq.awarded
    ══════════════════════════════════════
    {
    "success": false,
    "message": "No quote found from vendor VND-TH-001 for RFQ RFQ-2025-003",
    "data": null,
    "timestamp": "2026-03-18T10:39:27"
    }
    ✔ KEY EVENT: erp.vendor.rfq.awarded published — Procurement ERP will use this to create a PO

══════════════════════════════════════
11. Get award record for RFQ
    ══════════════════════════════════════
    {
    "success": false,
    "message": "No award found for RFQ: f53250ae-78b3-4ae7-8640-4603c56ef069",
    "data": null,
    "timestamp": "2026-03-18T10:39:27"
    }

══════════════════════════════════════
12. Attempt duplicate quote from same vendor (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "Quotes can only be submitted to OPEN RFQs. Current: UNDER_REVIEW",
    "data": null,
    "timestamp": "2026-03-18T10:39:27"
    }

══════════════════════════════════════
13. Attempt to award already-awarded RFQ (expect 409)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "RFQ awarded successfully",
    "data": {
    "externalId": "60fbfabb-7a21-4fcd-bdde-5a11789957cd",
    "rfqNumber": "RFQ-2025-003",
    "campaignCode": "SUMMER25-TOY",
    "winningVendorExternalId": "vnd-001-uuid",
    "winningVendorCode": "VND-CN-001",
    "winningVendorName": "Shenzhen BrightToy Manufacturing Co.",
    "winningVendorCountry": "CHINA",
    "awardedQuantity": 250000,
    "awardedUnitCostUsd": 0.84,
    "totalAwardValueUsd": 210000.0,
    "awardNotes": null,
    "awardedBy": "test",
    "awardedAt": "2026-03-18T10:39:27"
    },
    "timestamp": "2026-03-18T10:39:27"
    }

══════════════════════════════════════
14. Create then cancel an RFQ → publishes erp.vendor.rfq.cancelled
    ══════════════════════════════════════
    {
    "success": true,
    "message": "RFQ cancelled",
    "data": {
    "externalId": "a2ff54c4-1817-4311-a521-b33b527a2248",
    "rfqNumber": "RFQ-2025-CANCEL",
    "campaignExternalId": "camp-002-uuid",
    "campaignCode": "HOLIDAY25-TOY",
    "title": "Test RFQ for cancellation",
    "description": null,
    "toyCategory": null,
    "quantityRequired": 10000,
    "unit": "PIECES",
    "targetUnitCostUsd": null,
    "requiredByDate": "2025-12-01",
    "submissionDeadline": "2025-09-30",
    "status": "CANCELLED",
    "createdBy": "test.user",
    "createdAt": "2026-03-18T10:39:27",
    "updatedAt": "2026-03-18T10:39:27"
    },
    "timestamp": "2026-03-18T10:39:27"
    }

══════════════════════════════════════
15. Actuator Health Check
    ══════════════════════════════════════
    {
    "status": "UP",
    "components": {
    "db": {
    "status": "UP",
    "details": {
    "database": "MySQL",
    "validationQuery": "isValid()"
    }
    },
    "diskSpace": {
    "status": "UP",
    "details": {
    "total": 994662584320,
    "free": 894846447616,
    "threshold": 10485760,
    "path": "/Users/binit.datta/tms_enterprise_poc/cs-vendor-api/.",
    "exists": true
    }
    },
    "ping": {
    "status": "UP"
    },
    "rabbit": {
    "status": "UP",
    "details": {
    "version": "4.2.5"
    }
    },
    "ssl": {
    "status": "UP",
    "details": {
    "validChains": [],
    "invalidChains": []
    }
    }
    }
    }

✔ All tests complete.
✔ RabbitMQ events published:
✔   erp.vendor.vendor.created   — new vendor registered
✔   erp.vendor.rfq.opened       — RFQ opened for bidding
✔   erp.vendor.quote.submitted  — vendor quotes (x2)
✔   erp.vendor.rfq.awarded      — KEY: triggers PO in cs-procurement-api
✔   erp.vendor.rfq.cancelled    — RFQ cancelled
✔ Check: http://localhost:15672 → Queues → control-tower-test
binit.datta@C6NWKQ290Y cs-vendor-api % 