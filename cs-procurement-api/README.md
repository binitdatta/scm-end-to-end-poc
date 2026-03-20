# cs-procurement-api
**Procurement ERP — Purchase Order & Invoice Management**

Spring Boot 3.4.3 | JDK 21 | MySQL 8 | RabbitMQ | JPA | Port 8083

---

## Domain

Manages the full PO lifecycle after a vendor RFQ is awarded in `cs-vendor-api`:

```
erp.vendor.rfq.awarded
        ↓
  PO created (DRAFT)
        ↓
     APPROVED  ──→  erp.procurement.po.approved
        ↓
  SENT_TO_VENDOR ─→  erp.procurement.po.sent
        ↓
  ACKNOWLEDGED   ──→  erp.procurement.po.acknowledged
        ↓
  IN_PRODUCTION  ──→  erp.procurement.po.in-production
        ↓
  READY_TO_SHIP  ──→  erp.procurement.po.ready-to-ship  ← WMS Inbound creates ASN
        ↓
   COMPLETED     ──→  erp.procurement.po.completed

  Invoice sub-flow (parallel):
    RECEIVED → APPROVED → PAID
    Each step publishes its own erp.procurement.invoice.* event
```

---

## Project Structure

```
cs-procurement-api/
├── db/
│   ├── 01_ddl_cs_procurement.sql    ← Run first (4 tables + procurement_app user)
│   └── 02_seed_cs_procurement.sql   ← Run second (2 POs, 3 line items, audit events)
├── src/main/java/com/enterprise/csprocurement/
│   ├── CsProcurementApiApplication.java
│   ├── config/RabbitMQConfig.java
│   ├── controller/
│   │   ├── PurchaseOrderController.java
│   │   └── InvoiceController.java
│   ├── dto/
│   │   ├── request/  (CreatePoRequest, ApprovePoRequest, CreateInvoiceRequest)
│   │   └── response/ (ApiResponse, PoResponse, InvoiceResponse, PoEventResponse)
│   ├── entity/
│   │   ├── PurchaseOrder.java
│   │   ├── PoLineItem.java
│   │   ├── PoEvent.java
│   │   └── Invoice.java
│   ├── exception/ (GlobalExceptionHandler + 3 exception classes)
│   ├── messaging/
│   │   ├── ProcurementEventMessage.java
│   │   └── ProcurementEventPublisher.java
│   ├── repository/ (PurchaseOrderRepository, PoEventRepository, InvoiceRepository)
│   └── service/
│       ├── PurchaseOrderService.java
│       └── InvoiceService.java
└── src/main/resources/
    └── application.properties
```

---

## Setup

### Step 1 — MySQL Workbench
Run as admin in order:
1. `db/01_ddl_cs_procurement.sql` — database, `procurement_app` user (no DDL), 4 tables
2. `db/02_seed_cs_procurement.sql` — PO-2025-001 (APPROVED, Vietnam vendor, 500k dino toys), PO-2025-002 (DRAFT, China vendor, 1.2M figurines)

### Step 2 — Run (port 8083)
```bash
mvn clean install -DskipTests
java -jar target/cs-procurement-api-1.0.0-SNAPSHOT.jar
```

All three services can run simultaneously:
- cs-crm-api       → port 8081
- cs-vendor-api    → port 8082
- cs-procurement-api → port 8083

### Step 3 — Test
```bash
chmod +x test_cs_procurement_api.sh && ./test_cs_procurement_api.sh
```

---

## REST Endpoints

| Method | Path                                          | Description                        |
|--------|-----------------------------------------------|------------------------------------|
| POST   | /api/v1/purchase-orders                       | Create PO (DRAFT)                  |
| GET    | /api/v1/purchase-orders                       | List all POs                       |
| GET    | /api/v1/purchase-orders/{id}                  | Get PO                             |
| GET    | /api/v1/purchase-orders/status/{status}       | Filter by status                   |
| GET    | /api/v1/purchase-orders/{id}/events           | Full audit trail                   |
| POST   | /api/v1/purchase-orders/{id}/approve          | → APPROVED                         |
| POST   | /api/v1/purchase-orders/{id}/send             | → SENT_TO_VENDOR                   |
| POST   | /api/v1/purchase-orders/{id}/acknowledge      | → ACKNOWLEDGED                     |
| POST   | /api/v1/purchase-orders/{id}/in-production    | → IN_PRODUCTION                    |
| POST   | /api/v1/purchase-orders/{id}/ready-to-ship    | → READY_TO_SHIP (**WMS trigger**)  |
| POST   | /api/v1/purchase-orders/{id}/complete         | → COMPLETED                        |
| POST   | /api/v1/purchase-orders/{id}/cancel           | → CANCELLED                        |
| POST   | /api/v1/purchase-orders/{id}/invoices         | Receive vendor invoice             |
| GET    | /api/v1/purchase-orders/{id}/invoices         | List invoices for PO               |
| GET    | /api/v1/invoices/{id}                         | Get invoice                        |
| POST   | /api/v1/invoices/{id}/approve                 | → APPROVED                         |
| POST   | /api/v1/invoices/{id}/pay                     | → PAID                             |
| GET    | /actuator/health                              | Health check                       |

---

## RabbitMQ Events Published

| Event                      | Routing Key                               |
|----------------------------|-------------------------------------------|
| PO created                 | `erp.procurement.po.created`              |
| PO approved                | `erp.procurement.po.approved`             |
| PO sent to vendor          | `erp.procurement.po.sent`                 |
| PO acknowledged            | `erp.procurement.po.acknowledged`         |
| PO in production           | `erp.procurement.po.in-production`        |
| **PO ready to ship**       | **`erp.procurement.po.ready-to-ship`**    |
| PO completed               | `erp.procurement.po.completed`            |
| PO cancelled               | `erp.procurement.po.cancelled`            |
| Invoice received           | `erp.procurement.invoice.received`        |
| Invoice approved           | `erp.procurement.invoice.approved`        |
| Invoice paid               | `erp.procurement.invoice.paid`            |

Exchange: `erp.topic.exchange` (shared with cs-crm-api and cs-vendor-api)

---

## Seeded Data

| PO Number   | Vendor              | Country | Qty       | Value      | Status   |
|-------------|---------------------|---------|-----------|------------|----------|
| PO-2025-001 | Ho Chi Minh Playthings | VIETNAM | 500,000 | $410,000 | APPROVED |
| PO-2025-002 | Shenzhen BrightToy  | CHINA   | 1,200,000 | $936,000 | DRAFT    |


binit.datta@C6NWKQ290Y cs-procurement-api % chmod +x test_cs_procurement_api.sh && ./test_cs_procurement_api.sh

══════════════════════════════════════
1. List all seeded POs
   ══════════════════════════════════════
   {
   "success": true,
   "message": "POs retrieved",
   "data": [
   {
   "externalId": "po-001-uuid",
   "poNumber": "PO-2025-001",
   "rfqExternalId": "rfq-001-uuid",
   "rfqNumber": "RFQ-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "awardExternalId": "award-001-uuid",
   "vendorExternalId": "vnd-002-uuid",
   "vendorCode": "VND-VN-001",
   "vendorName": "Ho Chi Minh Playthings Ltd.",
   "vendorCountry": "VIETNAM",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise (500k units)",
   "quantityOrdered": 500000,
   "unitPriceUsd": 0.82,
   "totalValueUsd": 410000.0,
   "currency": "USD",
   "paymentTerms": "50% upfront, 50% on shipment",
   "incoterms": "FOB",
   "destinationPort": "Port of Los Angeles",
   "requiredDeliveryDate": "2025-04-30",
   "estimatedShipDate": "2025-04-01",
   "status": "APPROVED",
   "createdBy": "procurement.manager",
   "approvedBy": "procurement.director",
   "approvedAt": "2026-01-15T03:00:00",
   "notes": "Vietnam vendor awarded for fastest lead time (35 days) and ISO 9001 certification.",
   "createdAt": "2026-03-18T05:56:05",
   "updatedAt": "2026-03-18T05:56:05",
   "lineItems": [
   {
   "externalId": "poli-001-uuid",
   "lineNumber": 1,
   "itemCode": "TOY-DINO-MIX-001",
   "description": "Dinosaur Figure Mystery Mix \u2014 8 Variants (T-Rex, Triceratops, Brachiosaurus, Stegosaurus, Velociraptor, Pterodactyl, Ankylosaurus, Spinosaurus)",
   "quantity": 480000,
   "unit": "PIECES",
   "unitPriceUsd": 0.82,
   "lineTotalUsd": 393600.0
   },
   {
   "externalId": "poli-002-uuid",
   "lineNumber": 2,
   "itemCode": "PKG-SURPRISE-BOX-001",
   "description": "Branded Surprise Box Packaging \u2014 printed cardboard with mystery design",
   "quantity": 500000,
   "unit": "PIECES",
   "unitPriceUsd": 0.032,
   "lineTotalUsd": 16000.0
   },
   {
   "externalId": "poli-003-uuid",
   "lineNumber": 3,
   "itemCode": "TOY-DINO-BONUS-001",
   "description": "Bonus Rare Holographic Variant \u2014 limited 1-in-25 inclusion",
   "quantity": 20000,
   "unit": "PIECES",
   "unitPriceUsd": 0.02,
   "lineTotalUsd": 400.0
   }
   ]
   },
   {
   "externalId": "po-002-uuid",
   "poNumber": "PO-2025-002",
   "rfqExternalId": "rfq-002-uuid",
   "rfqNumber": "RFQ-2025-002",
   "campaignExternalId": "camp-002-uuid",
   "campaignCode": "HOLIDAY25-TOY",
   "awardExternalId": "award-002-uuid",
   "vendorExternalId": "vnd-001-uuid",
   "vendorCode": "VND-CN-001",
   "vendorName": "Shenzhen BrightToy Manufacturing Co.",
   "vendorCountry": "CHINA",
   "toyDescription": "Holiday 2025 Collectible Figurines \u2014 6 Character Series (1.2M units)",
   "quantityOrdered": 1200000,
   "unitPriceUsd": 0.78,
   "totalValueUsd": 936000.0,
   "currency": "USD",
   "paymentTerms": "NET30",
   "incoterms": "CIF",
   "destinationPort": "Port of Long Beach",
   "requiredDeliveryDate": "2025-10-15",
   "estimatedShipDate": "2025-09-15",
   "status": "DRAFT",
   "createdBy": "procurement.manager",
   "approvedBy": null,
   "approvedAt": null,
   "notes": "Pending final approval from CFO due to order value exceeding $900k threshold.",
   "createdAt": "2026-03-18T05:56:05",
   "updatedAt": "2026-03-18T05:56:05",
   "lineItems": []
   }
   ],
   "timestamp": "2026-03-18T10:57:03"
   }

══════════════════════════════════════
2. Get PO-2025-001 (seeded, APPROVED)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "PO retrieved",
   "data": {
   "externalId": "po-001-uuid",
   "poNumber": "PO-2025-001",
   "rfqExternalId": "rfq-001-uuid",
   "rfqNumber": "RFQ-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "awardExternalId": "award-001-uuid",
   "vendorExternalId": "vnd-002-uuid",
   "vendorCode": "VND-VN-001",
   "vendorName": "Ho Chi Minh Playthings Ltd.",
   "vendorCountry": "VIETNAM",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise (500k units)",
   "quantityOrdered": 500000,
   "unitPriceUsd": 0.82,
   "totalValueUsd": 410000.0,
   "currency": "USD",
   "paymentTerms": "50% upfront, 50% on shipment",
   "incoterms": "FOB",
   "destinationPort": "Port of Los Angeles",
   "requiredDeliveryDate": "2025-04-30",
   "estimatedShipDate": "2025-04-01",
   "status": "APPROVED",
   "createdBy": "procurement.manager",
   "approvedBy": "procurement.director",
   "approvedAt": "2026-01-15T03:00:00",
   "notes": "Vietnam vendor awarded for fastest lead time (35 days) and ISO 9001 certification.",
   "createdAt": "2026-03-18T05:56:05",
   "updatedAt": "2026-03-18T05:56:05",
   "lineItems": [
   {
   "externalId": "poli-001-uuid",
   "lineNumber": 1,
   "itemCode": "TOY-DINO-MIX-001",
   "description": "Dinosaur Figure Mystery Mix \u2014 8 Variants (T-Rex, Triceratops, Brachiosaurus, Stegosaurus, Velociraptor, Pterodactyl, Ankylosaurus, Spinosaurus)",
   "quantity": 480000,
   "unit": "PIECES",
   "unitPriceUsd": 0.82,
   "lineTotalUsd": 393600.0
   },
   {
   "externalId": "poli-002-uuid",
   "lineNumber": 2,
   "itemCode": "PKG-SURPRISE-BOX-001",
   "description": "Branded Surprise Box Packaging \u2014 printed cardboard with mystery design",
   "quantity": 500000,
   "unit": "PIECES",
   "unitPriceUsd": 0.032,
   "lineTotalUsd": 16000.0
   },
   {
   "externalId": "poli-003-uuid",
   "lineNumber": 3,
   "itemCode": "TOY-DINO-BONUS-001",
   "description": "Bonus Rare Holographic Variant \u2014 limited 1-in-25 inclusion",
   "quantity": 20000,
   "unit": "PIECES",
   "unitPriceUsd": 0.02,
   "lineTotalUsd": 400.0
   }
   ]
   },
   "timestamp": "2026-03-18T10:57:03"
   }

══════════════════════════════════════
3. PO audit events for PO-2025-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "PO events retrieved",
   "data": [
   {
   "id": 1,
   "eventType": "CREATED",
   "previousStatus": null,
   "newStatus": "DRAFT",
   "notes": "PO created from RFQ-2025-001 award. Vietnam vendor Ho Chi Minh Playthings selected.",
   "triggeredBy": "procurement.manager",
   "rabbitmqPublished": false,
   "eventAt": "2026-03-18T05:56:05"
   },
   {
   "id": 2,
   "eventType": "APPROVED",
   "previousStatus": "DRAFT",
   "newStatus": "APPROVED",
   "notes": "PO approved by procurement director. Budget confirmed. Ready to send to vendor.",
   "triggeredBy": "procurement.director",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-18T05:56:05"
   }
   ],
   "timestamp": "2026-03-18T10:57:03"
   }

══════════════════════════════════════
4. Create new PO (DRAFT) → publishes erp.procurement.po.created
   ══════════════════════════════════════
   {
   "success": true,
   "message": "PO created successfully",
   "data": {
   "externalId": "0b6c76ab-bf51-4a9c-87d4-11543da1a7ea",
   "poNumber": "PO-2025-003",
   "rfqExternalId": "rfq-003-ext-uuid",
   "rfqNumber": "RFQ-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "awardExternalId": "award-003-ext-uuid",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025 (250k units)",
   "quantityOrdered": 250000,
   "unitPriceUsd": 0.93,
   "totalValueUsd": 232500.0,
   "currency": "USD",
   "paymentTerms": "NET30",
   "incoterms": "FOB",
   "destinationPort": "Port of Los Angeles",
   "requiredDeliveryDate": "2025-05-15",
   "estimatedShipDate": "2025-04-20",
   "status": "DRAFT",
   "createdBy": "procurement.manager",
   "approvedBy": null,
   "approvedAt": null,
   "notes": "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
   "createdAt": "2026-03-18T10:57:03",
   "updatedAt": "2026-03-18T10:57:03",
   "lineItems": [
   {
   "externalId": "f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e",
   "lineNumber": 1,
   "itemCode": "TOY-SPACE-MIX-001",
   "description": "Space Explorer Figure Mystery Mix \u2014 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
   "quantity": 240000,
   "unit": "PIECES",
   "unitPriceUsd": 0.93,
   "lineTotalUsd": 223200.0
   },
   {
   "externalId": "2894d42c-90aa-4e3d-af93-23b7b8ed94c4",
   "lineNumber": 2,
   "itemCode": "PKG-SURPRISE-BOX-002",
   "description": "Space-themed surprise packaging box",
   "quantity": 250000,
   "unit": "PIECES",
   "unitPriceUsd": 0.032,
   "lineTotalUsd": 8000.0
   }
   ]
   },
   "timestamp": "2026-03-18T10:57:03"
   }
   ✔ New PO externalId: 0b6c76ab-bf51-4a9c-87d4-11543da1a7ea

══════════════════════════════════════
5. Approve PO → publishes erp.procurement.po.approved
   ══════════════════════════════════════
   {
   "success": true,
   "message": "PO approved",
   "data": {
   "externalId": "0b6c76ab-bf51-4a9c-87d4-11543da1a7ea",
   "poNumber": "PO-2025-003",
   "rfqExternalId": "rfq-003-ext-uuid",
   "rfqNumber": "RFQ-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "awardExternalId": "award-003-ext-uuid",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025 (250k units)",
   "quantityOrdered": 250000,
   "unitPriceUsd": 0.93,
   "totalValueUsd": 232500.0,
   "currency": "USD",
   "paymentTerms": "NET30",
   "incoterms": "FOB",
   "destinationPort": "Port of Los Angeles",
   "requiredDeliveryDate": "2025-05-15",
   "estimatedShipDate": "2025-04-20",
   "status": "APPROVED",
   "createdBy": "procurement.manager",
   "approvedBy": "procurement.director",
   "approvedAt": "2026-03-18T10:57:03",
   "notes": "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
   "createdAt": "2026-03-18T10:57:04",
   "updatedAt": "2026-03-18T10:57:04",
   "lineItems": [
   {
   "externalId": "f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e",
   "lineNumber": 1,
   "itemCode": "TOY-SPACE-MIX-001",
   "description": "Space Explorer Figure Mystery Mix \u2014 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
   "quantity": 240000,
   "unit": "PIECES",
   "unitPriceUsd": 0.93,
   "lineTotalUsd": 223200.0
   },
   {
   "externalId": "2894d42c-90aa-4e3d-af93-23b7b8ed94c4",
   "lineNumber": 2,
   "itemCode": "PKG-SURPRISE-BOX-002",
   "description": "Space-themed surprise packaging box",
   "quantity": 250000,
   "unit": "PIECES",
   "unitPriceUsd": 0.032,
   "lineTotalUsd": 8000.0
   }
   ]
   },
   "timestamp": "2026-03-18T10:57:03"
   }

══════════════════════════════════════
6. Send to vendor → publishes erp.procurement.po.sent
   ══════════════════════════════════════
   {
   "success": true,
   "message": "PO sent to vendor",
   "data": {
   "externalId": "0b6c76ab-bf51-4a9c-87d4-11543da1a7ea",
   "poNumber": "PO-2025-003",
   "rfqExternalId": "rfq-003-ext-uuid",
   "rfqNumber": "RFQ-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "awardExternalId": "award-003-ext-uuid",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025 (250k units)",
   "quantityOrdered": 250000,
   "unitPriceUsd": 0.93,
   "totalValueUsd": 232500.0,
   "currency": "USD",
   "paymentTerms": "NET30",
   "incoterms": "FOB",
   "destinationPort": "Port of Los Angeles",
   "requiredDeliveryDate": "2025-05-15",
   "estimatedShipDate": "2025-04-20",
   "status": "SENT_TO_VENDOR",
   "createdBy": "procurement.manager",
   "approvedBy": "procurement.director",
   "approvedAt": "2026-03-18T10:57:04",
   "notes": "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
   "createdAt": "2026-03-18T10:57:04",
   "updatedAt": "2026-03-18T10:57:04",
   "lineItems": [
   {
   "externalId": "f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e",
   "lineNumber": 1,
   "itemCode": "TOY-SPACE-MIX-001",
   "description": "Space Explorer Figure Mystery Mix \u2014 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
   "quantity": 240000,
   "unit": "PIECES",
   "unitPriceUsd": 0.93,
   "lineTotalUsd": 223200.0
   },
   {
   "externalId": "2894d42c-90aa-4e3d-af93-23b7b8ed94c4",
   "lineNumber": 2,
   "itemCode": "PKG-SURPRISE-BOX-002",
   "description": "Space-themed surprise packaging box",
   "quantity": 250000,
   "unit": "PIECES",
   "unitPriceUsd": 0.032,
   "lineTotalUsd": 8000.0
   }
   ]
   },
   "timestamp": "2026-03-18T10:57:03"
   }

══════════════════════════════════════
7. Vendor acknowledges PO → publishes erp.procurement.po.acknowledged
   ══════════════════════════════════════
   {
   "success": true,
   "message": "PO acknowledged by vendor",
   "data": {
   "externalId": "0b6c76ab-bf51-4a9c-87d4-11543da1a7ea",
   "poNumber": "PO-2025-003",
   "rfqExternalId": "rfq-003-ext-uuid",
   "rfqNumber": "RFQ-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "awardExternalId": "award-003-ext-uuid",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025 (250k units)",
   "quantityOrdered": 250000,
   "unitPriceUsd": 0.93,
   "totalValueUsd": 232500.0,
   "currency": "USD",
   "paymentTerms": "NET30",
   "incoterms": "FOB",
   "destinationPort": "Port of Los Angeles",
   "requiredDeliveryDate": "2025-05-15",
   "estimatedShipDate": "2025-04-20",
   "status": "ACKNOWLEDGED",
   "createdBy": "procurement.manager",
   "approvedBy": "procurement.director",
   "approvedAt": "2026-03-18T10:57:04",
   "notes": "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
   "createdAt": "2026-03-18T10:57:04",
   "updatedAt": "2026-03-18T10:57:04",
   "lineItems": [
   {
   "externalId": "f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e",
   "lineNumber": 1,
   "itemCode": "TOY-SPACE-MIX-001",
   "description": "Space Explorer Figure Mystery Mix \u2014 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
   "quantity": 240000,
   "unit": "PIECES",
   "unitPriceUsd": 0.93,
   "lineTotalUsd": 223200.0
   },
   {
   "externalId": "2894d42c-90aa-4e3d-af93-23b7b8ed94c4",
   "lineNumber": 2,
   "itemCode": "PKG-SURPRISE-BOX-002",
   "description": "Space-themed surprise packaging box",
   "quantity": 250000,
   "unit": "PIECES",
   "unitPriceUsd": 0.032,
   "lineTotalUsd": 8000.0
   }
   ]
   },
   "timestamp": "2026-03-18T10:57:03"
   }

══════════════════════════════════════
8. Mark in production → publishes erp.procurement.po.in-production
   ══════════════════════════════════════
   {
   "success": true,
   "message": "PO marked in production",
   "data": {
   "externalId": "0b6c76ab-bf51-4a9c-87d4-11543da1a7ea",
   "poNumber": "PO-2025-003",
   "rfqExternalId": "rfq-003-ext-uuid",
   "rfqNumber": "RFQ-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "awardExternalId": "award-003-ext-uuid",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025 (250k units)",
   "quantityOrdered": 250000,
   "unitPriceUsd": 0.93,
   "totalValueUsd": 232500.0,
   "currency": "USD",
   "paymentTerms": "NET30",
   "incoterms": "FOB",
   "destinationPort": "Port of Los Angeles",
   "requiredDeliveryDate": "2025-05-15",
   "estimatedShipDate": "2025-04-20",
   "status": "IN_PRODUCTION",
   "createdBy": "procurement.manager",
   "approvedBy": "procurement.director",
   "approvedAt": "2026-03-18T10:57:04",
   "notes": "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
   "createdAt": "2026-03-18T10:57:04",
   "updatedAt": "2026-03-18T10:57:04",
   "lineItems": [
   {
   "externalId": "f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e",
   "lineNumber": 1,
   "itemCode": "TOY-SPACE-MIX-001",
   "description": "Space Explorer Figure Mystery Mix \u2014 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
   "quantity": 240000,
   "unit": "PIECES",
   "unitPriceUsd": 0.93,
   "lineTotalUsd": 223200.0
   },
   {
   "externalId": "2894d42c-90aa-4e3d-af93-23b7b8ed94c4",
   "lineNumber": 2,
   "itemCode": "PKG-SURPRISE-BOX-002",
   "description": "Space-themed surprise packaging box",
   "quantity": 250000,
   "unit": "PIECES",
   "unitPriceUsd": 0.032,
   "lineTotalUsd": 8000.0
   }
   ]
   },
   "timestamp": "2026-03-18T10:57:03"
   }

══════════════════════════════════════
9. Ready to ship → publishes erp.procurement.po.ready-to-ship (WMS trigger)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "PO ready to ship",
   "data": {
   "externalId": "0b6c76ab-bf51-4a9c-87d4-11543da1a7ea",
   "poNumber": "PO-2025-003",
   "rfqExternalId": "rfq-003-ext-uuid",
   "rfqNumber": "RFQ-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "awardExternalId": "award-003-ext-uuid",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025 (250k units)",
   "quantityOrdered": 250000,
   "unitPriceUsd": 0.93,
   "totalValueUsd": 232500.0,
   "currency": "USD",
   "paymentTerms": "NET30",
   "incoterms": "FOB",
   "destinationPort": "Port of Los Angeles",
   "requiredDeliveryDate": "2025-05-15",
   "estimatedShipDate": "2025-04-20",
   "status": "READY_TO_SHIP",
   "createdBy": "procurement.manager",
   "approvedBy": "procurement.director",
   "approvedAt": "2026-03-18T10:57:04",
   "notes": "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
   "createdAt": "2026-03-18T10:57:04",
   "updatedAt": "2026-03-18T10:57:04",
   "lineItems": [
   {
   "externalId": "f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e",
   "lineNumber": 1,
   "itemCode": "TOY-SPACE-MIX-001",
   "description": "Space Explorer Figure Mystery Mix \u2014 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
   "quantity": 240000,
   "unit": "PIECES",
   "unitPriceUsd": 0.93,
   "lineTotalUsd": 223200.0
   },
   {
   "externalId": "2894d42c-90aa-4e3d-af93-23b7b8ed94c4",
   "lineNumber": 2,
   "itemCode": "PKG-SURPRISE-BOX-002",
   "description": "Space-themed surprise packaging box",
   "quantity": 250000,
   "unit": "PIECES",
   "unitPriceUsd": 0.032,
   "lineTotalUsd": 8000.0
   }
   ]
   },
   "timestamp": "2026-03-18T10:57:03"
   }
   ✔ KEY EVENT: erp.procurement.po.ready-to-ship — WMS Inbound will create ASN from this

══════════════════════════════════════
10. Receive vendor invoice → publishes erp.procurement.invoice.received
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Invoice received successfully",
    "data": {
    "externalId": "9ffcad2c-52bc-4893-bc57-b57f29f3d940",
    "invoiceNumber": "INV-TH-2025-0042",
    "poNumber": "PO-2025-003",
    "vendorExternalId": "vnd-004-uuid",
    "invoiceAmountUsd": 232500.0,
    "taxAmountUsd": 0.0,
    "totalAmountUsd": 232500.0,
    "invoiceDate": "2025-04-20",
    "dueDate": "2025-05-20",
    "status": "RECEIVED",
    "paidAt": null,
    "notes": "Final invoice for PO-2025-003. 250,000 Space Explorer figures. Payment due NET30.",
    "createdAt": "2026-03-18T10:57:03"
    },
    "timestamp": "2026-03-18T10:57:03"
    }
    ✔ Invoice externalId: 9ffcad2c-52bc-4893-bc57-b57f29f3d940

══════════════════════════════════════
11. Approve invoice → publishes erp.procurement.invoice.approved
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Invoice approved",
    "data": {
    "externalId": "9ffcad2c-52bc-4893-bc57-b57f29f3d940",
    "invoiceNumber": "INV-TH-2025-0042",
    "poNumber": "PO-2025-003",
    "vendorExternalId": "vnd-004-uuid",
    "invoiceAmountUsd": 232500.0,
    "taxAmountUsd": 0.0,
    "totalAmountUsd": 232500.0,
    "invoiceDate": "2025-04-20",
    "dueDate": "2025-05-20",
    "status": "APPROVED",
    "paidAt": null,
    "notes": "Final invoice for PO-2025-003. 250,000 Space Explorer figures. Payment due NET30.",
    "createdAt": "2026-03-18T10:57:04"
    },
    "timestamp": "2026-03-18T10:57:04"
    }

══════════════════════════════════════
12. Pay invoice → publishes erp.procurement.invoice.paid
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Invoice paid",
    "data": {
    "externalId": "9ffcad2c-52bc-4893-bc57-b57f29f3d940",
    "invoiceNumber": "INV-TH-2025-0042",
    "poNumber": "PO-2025-003",
    "vendorExternalId": "vnd-004-uuid",
    "invoiceAmountUsd": 232500.0,
    "taxAmountUsd": 0.0,
    "totalAmountUsd": 232500.0,
    "invoiceDate": "2025-04-20",
    "dueDate": "2025-05-20",
    "status": "PAID",
    "paidAt": "2026-03-18T10:57:04",
    "notes": "Final invoice for PO-2025-003. 250,000 Space Explorer figures. Payment due NET30.",
    "createdAt": "2026-03-18T10:57:04"
    },
    "timestamp": "2026-03-18T10:57:04"
    }

══════════════════════════════════════
13. Complete PO → publishes erp.procurement.po.completed
    ══════════════════════════════════════
    {
    "success": true,
    "message": "PO completed",
    "data": {
    "externalId": "0b6c76ab-bf51-4a9c-87d4-11543da1a7ea",
    "poNumber": "PO-2025-003",
    "rfqExternalId": "rfq-003-ext-uuid",
    "rfqNumber": "RFQ-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "awardExternalId": "award-003-ext-uuid",
    "vendorExternalId": "vnd-004-uuid",
    "vendorCode": "VND-TH-001",
    "vendorName": "Bangkok Fun Factory Co. Ltd.",
    "vendorCountry": "THAILAND",
    "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025 (250k units)",
    "quantityOrdered": 250000,
    "unitPriceUsd": 0.93,
    "totalValueUsd": 232500.0,
    "currency": "USD",
    "paymentTerms": "NET30",
    "incoterms": "FOB",
    "destinationPort": "Port of Los Angeles",
    "requiredDeliveryDate": "2025-05-15",
    "estimatedShipDate": "2025-04-20",
    "status": "COMPLETED",
    "createdBy": "procurement.manager",
    "approvedBy": "procurement.director",
    "approvedAt": "2026-03-18T10:57:04",
    "notes": "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
    "createdAt": "2026-03-18T10:57:04",
    "updatedAt": "2026-03-18T10:57:04",
    "lineItems": [
    {
    "externalId": "f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e",
    "lineNumber": 1,
    "itemCode": "TOY-SPACE-MIX-001",
    "description": "Space Explorer Figure Mystery Mix \u2014 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
    "quantity": 240000,
    "unit": "PIECES",
    "unitPriceUsd": 0.93,
    "lineTotalUsd": 223200.0
    },
    {
    "externalId": "2894d42c-90aa-4e3d-af93-23b7b8ed94c4",
    "lineNumber": 2,
    "itemCode": "PKG-SURPRISE-BOX-002",
    "description": "Space-themed surprise packaging box",
    "quantity": 250000,
    "unit": "PIECES",
    "unitPriceUsd": 0.032,
    "lineTotalUsd": 8000.0
    }
    ]
    },
    "timestamp": "2026-03-18T10:57:04"
    }

══════════════════════════════════════
14. Filter POs by status=DRAFT
    ══════════════════════════════════════
    {
    "success": true,
    "message": "POs retrieved for status: DRAFT",
    "data": [
    {
    "externalId": "po-002-uuid",
    "poNumber": "PO-2025-002",
    "rfqExternalId": "rfq-002-uuid",
    "rfqNumber": "RFQ-2025-002",
    "campaignExternalId": "camp-002-uuid",
    "campaignCode": "HOLIDAY25-TOY",
    "awardExternalId": "award-002-uuid",
    "vendorExternalId": "vnd-001-uuid",
    "vendorCode": "VND-CN-001",
    "vendorName": "Shenzhen BrightToy Manufacturing Co.",
    "vendorCountry": "CHINA",
    "toyDescription": "Holiday 2025 Collectible Figurines \u2014 6 Character Series (1.2M units)",
    "quantityOrdered": 1200000,
    "unitPriceUsd": 0.78,
    "totalValueUsd": 936000.0,
    "currency": "USD",
    "paymentTerms": "NET30",
    "incoterms": "CIF",
    "destinationPort": "Port of Long Beach",
    "requiredDeliveryDate": "2025-10-15",
    "estimatedShipDate": "2025-09-15",
    "status": "DRAFT",
    "createdBy": "procurement.manager",
    "approvedBy": null,
    "approvedAt": null,
    "notes": "Pending final approval from CFO due to order value exceeding $900k threshold.",
    "createdAt": "2026-03-18T05:56:05",
    "updatedAt": "2026-03-18T05:56:05",
    "lineItems": []
    }
    ],
    "timestamp": "2026-03-18T10:57:04"
    }

══════════════════════════════════════
14b. Filter POs by status=COMPLETED
══════════════════════════════════════
{
"success": true,
"message": "POs retrieved for status: COMPLETED",
"data": [
{
"externalId": "0b6c76ab-bf51-4a9c-87d4-11543da1a7ea",
"poNumber": "PO-2025-003",
"rfqExternalId": "rfq-003-ext-uuid",
"rfqNumber": "RFQ-2025-003",
"campaignExternalId": "camp-001-uuid",
"campaignCode": "SUMMER25-TOY",
"awardExternalId": "award-003-ext-uuid",
"vendorExternalId": "vnd-004-uuid",
"vendorCode": "VND-TH-001",
"vendorName": "Bangkok Fun Factory Co. Ltd.",
"vendorCountry": "THAILAND",
"toyDescription": "Space Explorer Figure Series \u2014 Summer 2025 (250k units)",
"quantityOrdered": 250000,
"unitPriceUsd": 0.93,
"totalValueUsd": 232500.0,
"currency": "USD",
"paymentTerms": "NET30",
"incoterms": "FOB",
"destinationPort": "Port of Los Angeles",
"requiredDeliveryDate": "2025-05-15",
"estimatedShipDate": "2025-04-20",
"status": "COMPLETED",
"createdBy": "procurement.manager",
"approvedBy": "procurement.director",
"approvedAt": "2026-03-18T10:57:04",
"notes": "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
"createdAt": "2026-03-18T10:57:04",
"updatedAt": "2026-03-18T10:57:04",
"lineItems": [
{
"externalId": "f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e",
"lineNumber": 1,
"itemCode": "TOY-SPACE-MIX-001",
"description": "Space Explorer Figure Mystery Mix \u2014 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
"quantity": 240000,
"unit": "PIECES",
"unitPriceUsd": 0.93,
"lineTotalUsd": 223200.0
},
{
"externalId": "2894d42c-90aa-4e3d-af93-23b7b8ed94c4",
"lineNumber": 2,
"itemCode": "PKG-SURPRISE-BOX-002",
"description": "Space-themed surprise packaging box",
"quantity": 250000,
"unit": "PIECES",
"unitPriceUsd": 0.032,
"lineTotalUsd": 8000.0
}
]
}
],
"timestamp": "2026-03-18T10:57:04"
}

══════════════════════════════════════
15. Attempt to approve already-COMPLETED PO (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "PO must be DRAFT to be approved. Current: COMPLETED",
    "data": null,
    "timestamp": "2026-03-18T10:57:04"
    }

══════════════════════════════════════
16. Attempt duplicate PO number (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "PO number already exists: PO-2025-003",
    "data": null,
    "timestamp": "2026-03-18T10:57:04"
    }

══════════════════════════════════════
17. Drive seeded PO-2025-001 (APPROVED) → SENT_TO_VENDOR
    ══════════════════════════════════════
    {
    "success": true,
    "message": "PO sent to vendor",
    "data": {
    "externalId": "po-001-uuid",
    "poNumber": "PO-2025-001",
    "rfqExternalId": "rfq-001-uuid",
    "rfqNumber": "RFQ-2025-001",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "awardExternalId": "award-001-uuid",
    "vendorExternalId": "vnd-002-uuid",
    "vendorCode": "VND-VN-001",
    "vendorName": "Ho Chi Minh Playthings Ltd.",
    "vendorCountry": "VIETNAM",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise (500k units)",
    "quantityOrdered": 500000,
    "unitPriceUsd": 0.82,
    "totalValueUsd": 410000.0,
    "currency": "USD",
    "paymentTerms": "50% upfront, 50% on shipment",
    "incoterms": "FOB",
    "destinationPort": "Port of Los Angeles",
    "requiredDeliveryDate": "2025-04-30",
    "estimatedShipDate": "2025-04-01",
    "status": "SENT_TO_VENDOR",
    "createdBy": "procurement.manager",
    "approvedBy": "procurement.director",
    "approvedAt": "2026-01-15T03:00:00",
    "notes": "Vietnam vendor awarded for fastest lead time (35 days) and ISO 9001 certification.",
    "createdAt": "2026-03-18T05:56:05",
    "updatedAt": "2026-03-18T05:56:05",
    "lineItems": [
    {
    "externalId": "poli-001-uuid",
    "lineNumber": 1,
    "itemCode": "TOY-DINO-MIX-001",
    "description": "Dinosaur Figure Mystery Mix \u2014 8 Variants (T-Rex, Triceratops, Brachiosaurus, Stegosaurus, Velociraptor, Pterodactyl, Ankylosaurus, Spinosaurus)",
    "quantity": 480000,
    "unit": "PIECES",
    "unitPriceUsd": 0.82,
    "lineTotalUsd": 393600.0
    },
    {
    "externalId": "poli-002-uuid",
    "lineNumber": 2,
    "itemCode": "PKG-SURPRISE-BOX-001",
    "description": "Branded Surprise Box Packaging \u2014 printed cardboard with mystery design",
    "quantity": 500000,
    "unit": "PIECES",
    "unitPriceUsd": 0.032,
    "lineTotalUsd": 16000.0
    },
    {
    "externalId": "poli-003-uuid",
    "lineNumber": 3,
    "itemCode": "TOY-DINO-BONUS-001",
    "description": "Bonus Rare Holographic Variant \u2014 limited 1-in-25 inclusion",
    "quantity": 20000,
    "unit": "PIECES",
    "unitPriceUsd": 0.02,
    "lineTotalUsd": 400.0
    }
    ]
    },
    "timestamp": "2026-03-18T10:57:04"
    }

══════════════════════════════════════
18. Full audit trail for new PO
    ══════════════════════════════════════
    {
    "success": true,
    "message": "PO events retrieved",
    "data": [
    {
    "id": 4,
    "eventType": "CREATED",
    "previousStatus": null,
    "newStatus": "DRAFT",
    "notes": "PO created",
    "triggeredBy": "procurement.manager",
    "rabbitmqPublished": false,
    "eventAt": "2026-03-18T10:57:04"
    },
    {
    "id": 5,
    "eventType": "APPROVED",
    "previousStatus": "DRAFT",
    "newStatus": "APPROVED",
    "notes": "Budget confirmed. Toy specs verified. Approved.",
    "triggeredBy": "procurement.director",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T10:57:04"
    },
    {
    "id": 6,
    "eventType": "SENT_TO_VENDOR",
    "previousStatus": "APPROVED",
    "newStatus": "SENT_TO_VENDOR",
    "notes": "PO emailed and uploaded to vendor portal.",
    "triggeredBy": "procurement.manager",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T10:57:04"
    },
    {
    "id": 7,
    "eventType": "ACKNOWLEDGED",
    "previousStatus": "SENT_TO_VENDOR",
    "newStatus": "ACKNOWLEDGED",
    "notes": "Bangkok Fun Factory confirmed receipt. Production slot reserved.",
    "triggeredBy": "vnd-th-001.portal",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T10:57:04"
    },
    {
    "id": 8,
    "eventType": "IN_PRODUCTION",
    "previousStatus": "ACKNOWLEDGED",
    "newStatus": "IN_PRODUCTION",
    "notes": "Molds ready. First production run started. ETA 35 days.",
    "triggeredBy": "vnd-th-001.portal",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T10:57:04"
    },
    {
    "id": 9,
    "eventType": "READY_TO_SHIP",
    "previousStatus": "IN_PRODUCTION",
    "newStatus": "READY_TO_SHIP",
    "notes": "All 250k units QC passed. Loaded on vessel MSC AURORA. ETA LAX 2025-05-05.",
    "triggeredBy": "vnd-th-001.portal",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T10:57:04"
    },
    {
    "id": 10,
    "eventType": "COMPLETED",
    "previousStatus": "READY_TO_SHIP",
    "newStatus": "COMPLETED",
    "notes": "All toys received at DC. Invoice paid. PO closed.",
    "triggeredBy": "procurement.manager",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T10:57:04"
    }
    ],
    "timestamp": "2026-03-18T10:57:04"
    }

══════════════════════════════════════
19. Actuator Health Check
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
    "free": 894708682752,
    "threshold": 10485760,
    "path": "/Users/binit.datta/tms_enterprise_poc/cs-procurement-api/.",
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
✔ RabbitMQ events published (check http://localhost:15672):
✔   erp.procurement.po.created       — new PO drafted
✔   erp.procurement.po.approved      — PO budget cleared
✔   erp.procurement.po.sent          — PO transmitted to vendor
✔   erp.procurement.po.acknowledged  — vendor confirmed
✔   erp.procurement.po.in-production — toys being manufactured
✔   erp.procurement.po.ready-to-ship — KEY: WMS inbound creates ASN from this
✔   erp.procurement.invoice.received — vendor invoice arrived
✔   erp.procurement.invoice.approved — 3-way match complete
✔   erp.procurement.invoice.paid     — wire transfer sent
✔   erp.procurement.po.completed     — PO fully closed
binit.datta@C6NWKQ290Y cs-procurement-api % 