# cs-oms-api
**OMS — Store Order Management & Allocation**

Spring Boot 3.4.3 | JDK 21 | MySQL 8 | RabbitMQ | JPA | Port 8085

---

## Domain

Manages store-level toy allocation across the food chain's 3,200 US restaurant locations:

```
erp.wms.inbound.putaway.completed
        ↓ (OMS updates inventory view)
  Store order DRAFT
        ↓
  SUBMITTED                ──→  erp.oms.store-order.submitted
        ↓
  ALLOCATED                ──→  erp.oms.store-order.allocated  ← WMS Outbound pick wave
  (splits qty across stores)
        ↓
  PICKING                  ──→  erp.oms.store-order.picking
        ↓
  SHIPPED                  ──→  erp.oms.store-order.shipped
        ↓
  DELIVERED                ──→  erp.oms.store-order.delivered
```

---

## Project Structure

```
cs-oms-api/
├── db/
│   ├── 01_ddl_cs_oms.sql          ← Run first (6 tables + oms_app user)
│   └── 02_seed_cs_oms.sql         ← Run second (regions, stores, inventory, 2 orders)
├── src/main/java/com/enterprise/csoms/
│   ├── CsOmsApiApplication.java
│   ├── config/RabbitMQConfig.java
│   ├── controller/
│   │   ├── StoreOrderController.java
│   │   ├── InventoryController.java
│   │   └── StoreController.java
│   ├── dto/
│   │   ├── request/  (CreateStoreOrderRequest, AllocateOrderRequest, UpdateInventoryRequest)
│   │   └── response/ (ApiResponse, StoreOrderResponse, RegionResponse,
│   │                   StoreResponse, InventoryAvailabilityResponse, OrderEventResponse)
│   ├── entity/
│   │   ├── StoreRegion.java
│   │   ├── Store.java
│   │   ├── StoreOrder.java
│   │   ├── StoreOrderLine.java
│   │   ├── InventoryAvailability.java
│   │   └── OrderEvent.java
│   ├── exception/ (4 exception classes + GlobalExceptionHandler)
│   ├── messaging/
│   │   ├── OmsEventMessage.java
│   │   └── OmsEventPublisher.java
│   ├── repository/ (6 repositories)
│   └── service/
│       ├── StoreOrderService.java
│       ├── InventoryService.java
│       └── StoreService.java
└── src/main/resources/
    └── application.properties
```

---

## Setup

### Step 1 — MySQL Workbench
Run as admin in order:
1. `db/01_ddl_cs_oms.sql` — creates `cs_oms` database, `oms_app` user (no DDL), 6 tables
2. `db/02_seed_cs_oms.sql` — seeds 6 regions, 20 stores, inventory for 2 SKUs, 2 store orders

### Step 2 — Run (port 8085)
```bash
# Fix the <n> tag before building (known pom.xml issue)
sed -i '' 's|<n>cs-oms-api</n>|<name>cs-oms-api</name>|' pom.xml
mvn clean install -DskipTests
java -jar target/cs-oms-api-1.0.0-SNAPSHOT.jar
```

All five services can now run simultaneously:
- cs-crm-api        → 8081
- cs-vendor-api     → 8082
- cs-procurement-api → 8083
- cs-wms-inbound-api → 8084
- cs-oms-api        → 8085

### Step 3 — Test
```bash
chmod +x test_cs_oms_api.sh && ./test_cs_oms_api.sh
```

---

## REST Endpoints

| Method | Path                                          | Description                           |
|--------|-----------------------------------------------|---------------------------------------|
| GET    | /api/v1/regions                               | List all 6 regions                    |
| GET    | /api/v1/regions/{code}                        | Get region by code                    |
| GET    | /api/v1/regions/{code}/stores                 | Stores in a region                    |
| GET    | /api/v1/stores                                | List all stores                       |
| POST   | /api/v1/inventory/update                      | Sync inventory from WMS putaway       |
| GET    | /api/v1/inventory/campaign/{code}             | All SKUs for a campaign               |
| GET    | /api/v1/inventory/sku/{sku}/campaign/{code}   | Single SKU availability               |
| POST   | /api/v1/store-orders                          | Create store order (DRAFT)            |
| GET    | /api/v1/store-orders                          | List all orders                       |
| GET    | /api/v1/store-orders/{id}                     | Get order with store lines            |
| GET    | /api/v1/store-orders/status/{status}          | Filter by status                      |
| GET    | /api/v1/store-orders/campaign/{code}          | Filter by campaign                    |
| GET    | /api/v1/store-orders/{id}/events              | Full audit trail                      |
| POST   | /api/v1/store-orders/{id}/submit              | → SUBMITTED                           |
| POST   | /api/v1/store-orders/{id}/allocate            | → ALLOCATED (**WMS Outbound trigger**)|
| POST   | /api/v1/store-orders/{id}/picking             | → PICKING                             |
| POST   | /api/v1/store-orders/{id}/shipped             | → SHIPPED                             |
| POST   | /api/v1/store-orders/{id}/delivered           | → DELIVERED                           |
| POST   | /api/v1/store-orders/{id}/cancel              | → CANCELLED (releases inventory)      |
| GET    | /actuator/health                              | Health check                          |

---

## RabbitMQ Events Published

| Event                   | Routing Key                             |
|-------------------------|-----------------------------------------|
| Inventory synced        | `erp.oms.inventory.updated`             |
| Order created           | `erp.oms.store-order.created`           |
| Order submitted         | `erp.oms.store-order.submitted`         |
| **Order allocated**     | **`erp.oms.store-order.allocated`**     |
| Order picking           | `erp.oms.store-order.picking`           |
| Order shipped           | `erp.oms.store-order.shipped`           |
| Order delivered         | `erp.oms.store-order.delivered`         |
| Order cancelled         | `erp.oms.store-order.cancelled`         |

Exchange: `erp.topic.exchange` (shared across all ERP services)

---

## Seeded Reference Data

**Regions (6)**

| Code         | Name                  | Stores | DC               |
|--------------|-----------------------|--------|------------------|
| US-MIDWEST   | Midwest United States | 640    | DC-CHICAGO       |
| US-WEST      | Western United States | 580    | DC-LOS-ANGELES   |
| US-SOUTHEAST | Southeast US          | 520    | DC-ATLANTA       |
| US-NORTHEAST | Northeast US          | 480    | DC-NEW-YORK      |
| US-SOUTHWEST | Southwest US          | 440    | DC-DALLAS        |
| US-NORTHWEST | Northwest US          | 540    | DC-SEATTLE       |

**Inventory available**

| SKU                  | Campaign      | Available | Reserved | Remaining |
|----------------------|---------------|-----------|----------|-----------|
| TOY-DINO-MIX-001     | SUMMER25-TOY  | 499,800   | 128,000  | 371,800   |
| TOY-SPACE-MIX-001    | SUMMER25-TOY  | 249,950   | 0        | 249,950   |

**Seeded Orders**

| Order         | Region       | SKU               | Qty     | Status    |
|---------------|--------------|-------------------|---------|-----------|
| ORD-2025-001  | US-MIDWEST   | TOY-DINO-MIX-001  | 128,000 | ALLOCATED |
| ORD-2025-002  | US-WEST      | TOY-DINO-MIX-001  | 116,000 | DRAFT     |

binit.datta@C6NWKQ290Y cs-oms-api % chmod +x test_cs_oms_api.sh && ./test_cs_oms_api.sh


══════════════════════════════════════
1. List all 6 US regions
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Regions retrieved",
   "data": [
   {
   "externalId": "reg-001-uuid",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "storeCount": 640,
   "distributionDc": "DC-CHICAGO",
   "status": "ACTIVE"
   },
   {
   "externalId": "reg-002-uuid",
   "regionCode": "US-WEST",
   "regionName": "Western United States",
   "storeCount": 580,
   "distributionDc": "DC-LOS-ANGELES",
   "status": "ACTIVE"
   },
   {
   "externalId": "reg-003-uuid",
   "regionCode": "US-SOUTHEAST",
   "regionName": "Southeast United States",
   "storeCount": 520,
   "distributionDc": "DC-ATLANTA",
   "status": "ACTIVE"
   },
   {
   "externalId": "reg-004-uuid",
   "regionCode": "US-NORTHEAST",
   "regionName": "Northeast United States",
   "storeCount": 480,
   "distributionDc": "DC-NEW-YORK",
   "status": "ACTIVE"
   },
   {
   "externalId": "reg-005-uuid",
   "regionCode": "US-SOUTHWEST",
   "regionName": "Southwest United States",
   "storeCount": 440,
   "distributionDc": "DC-DALLAS",
   "status": "ACTIVE"
   },
   {
   "externalId": "reg-006-uuid",
   "regionCode": "US-NORTHWEST",
   "regionName": "Northwest United States",
   "storeCount": 540,
   "distributionDc": "DC-SEATTLE",
   "status": "ACTIVE"
   }
   ],
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
2. Get US-MIDWEST region
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Region retrieved",
   "data": {
   "externalId": "reg-001-uuid",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "storeCount": 640,
   "distributionDc": "DC-CHICAGO",
   "status": "ACTIVE"
   },
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
3. Stores in US-MIDWEST
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Stores retrieved for region: US-MIDWEST",
   "data": [
   {
   "externalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "address": "100 N Michigan Ave",
   "city": "Chicago",
   "stateCode": "IL",
   "zipCode": "60601",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "address": "204 S Washington St",
   "city": "Naperville",
   "stateCode": "IL",
   "zipCode": "60540",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "address": "780 N Water St",
   "city": "Milwaukee",
   "stateCode": "WI",
   "zipCode": "53202",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "address": "1 Monument Circle",
   "city": "Indianapolis",
   "stateCode": "IN",
   "zipCode": "46204",
   "status": "ACTIVE"
   }
   ],
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
4. All 20 seeded stores
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Stores retrieved",
   "data": [
   {
   "externalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "address": "100 N Michigan Ave",
   "city": "Chicago",
   "stateCode": "IL",
   "zipCode": "60601",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "address": "204 S Washington St",
   "city": "Naperville",
   "stateCode": "IL",
   "zipCode": "60540",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "address": "780 N Water St",
   "city": "Milwaukee",
   "stateCode": "WI",
   "zipCode": "53202",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "address": "1 Monument Circle",
   "city": "Indianapolis",
   "stateCode": "IN",
   "zipCode": "46204",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-005-uuid",
   "storeNumber": "STR-0101",
   "storeName": "Burger Bliss Los Angeles Downtown",
   "regionCode": "US-WEST",
   "regionName": "Western United States",
   "address": "333 S Grand Ave",
   "city": "Los Angeles",
   "stateCode": "CA",
   "zipCode": "90071",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-006-uuid",
   "storeNumber": "STR-0102",
   "storeName": "Burger Bliss San Francisco",
   "regionCode": "US-WEST",
   "regionName": "Western United States",
   "address": "1 Market St",
   "city": "San Francisco",
   "stateCode": "CA",
   "zipCode": "94105",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-007-uuid",
   "storeNumber": "STR-0103",
   "storeName": "Burger Bliss Las Vegas Strip",
   "regionCode": "US-WEST",
   "regionName": "Western United States",
   "address": "3700 Las Vegas Blvd S",
   "city": "Las Vegas",
   "stateCode": "NV",
   "zipCode": "89109",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-008-uuid",
   "storeNumber": "STR-0104",
   "storeName": "Burger Bliss Phoenix",
   "regionCode": "US-WEST",
   "regionName": "Western United States",
   "address": "201 E Washington St",
   "city": "Phoenix",
   "stateCode": "AZ",
   "zipCode": "85004",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-009-uuid",
   "storeNumber": "STR-0201",
   "storeName": "Burger Bliss Atlanta Midtown",
   "regionCode": "US-SOUTHEAST",
   "regionName": "Southeast United States",
   "address": "848 Peachtree St NE",
   "city": "Atlanta",
   "stateCode": "GA",
   "zipCode": "30308",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-010-uuid",
   "storeNumber": "STR-0202",
   "storeName": "Burger Bliss Miami Brickell",
   "regionCode": "US-SOUTHEAST",
   "regionName": "Southeast United States",
   "address": "1221 Brickell Ave",
   "city": "Miami",
   "stateCode": "FL",
   "zipCode": "33131",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-011-uuid",
   "storeNumber": "STR-0203",
   "storeName": "Burger Bliss Charlotte",
   "regionCode": "US-SOUTHEAST",
   "regionName": "Southeast United States",
   "address": "100 N Tryon St",
   "city": "Charlotte",
   "stateCode": "NC",
   "zipCode": "28202",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-012-uuid",
   "storeNumber": "STR-0204",
   "storeName": "Burger Bliss Nashville",
   "regionCode": "US-SOUTHEAST",
   "regionName": "Southeast United States",
   "address": "209 10th Ave S",
   "city": "Nashville",
   "stateCode": "TN",
   "zipCode": "37203",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-013-uuid",
   "storeNumber": "STR-0301",
   "storeName": "Burger Bliss New York Midtown",
   "regionCode": "US-NORTHEAST",
   "regionName": "Northeast United States",
   "address": "1 Times Square",
   "city": "New York",
   "stateCode": "NY",
   "zipCode": "10036",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-014-uuid",
   "storeNumber": "STR-0302",
   "storeName": "Burger Bliss Boston",
   "regionCode": "US-NORTHEAST",
   "regionName": "Northeast United States",
   "address": "100 Boylston St",
   "city": "Boston",
   "stateCode": "MA",
   "zipCode": "02116",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-015-uuid",
   "storeNumber": "STR-0303",
   "storeName": "Burger Bliss Philadelphia",
   "regionCode": "US-NORTHEAST",
   "regionName": "Northeast United States",
   "address": "1700 Market St",
   "city": "Philadelphia",
   "stateCode": "PA",
   "zipCode": "19103",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-016-uuid",
   "storeNumber": "STR-0304",
   "storeName": "Burger Bliss Washington DC",
   "regionCode": "US-NORTHEAST",
   "regionName": "Northeast United States",
   "address": "1000 Vermont Ave NW",
   "city": "Washington",
   "stateCode": "DC",
   "zipCode": "20005",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-017-uuid",
   "storeNumber": "STR-0401",
   "storeName": "Burger Bliss Dallas Uptown",
   "regionCode": "US-SOUTHWEST",
   "regionName": "Southwest United States",
   "address": "3699 McKinney Ave",
   "city": "Dallas",
   "stateCode": "TX",
   "zipCode": "75204",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-018-uuid",
   "storeNumber": "STR-0402",
   "storeName": "Burger Bliss Houston Galleria",
   "regionCode": "US-SOUTHWEST",
   "regionName": "Southwest United States",
   "address": "5015 Westheimer Rd",
   "city": "Houston",
   "stateCode": "TX",
   "zipCode": "77056",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-019-uuid",
   "storeNumber": "STR-0501",
   "storeName": "Burger Bliss Seattle Pike Place",
   "regionCode": "US-NORTHWEST",
   "regionName": "Northwest United States",
   "address": "1428 Post Alley",
   "city": "Seattle",
   "stateCode": "WA",
   "zipCode": "98101",
   "status": "ACTIVE"
   },
   {
   "externalId": "str-020-uuid",
   "storeNumber": "STR-0502",
   "storeName": "Burger Bliss Portland",
   "regionCode": "US-NORTHWEST",
   "regionName": "Northwest United States",
   "address": "SW 5th & Morrison",
   "city": "Portland",
   "stateCode": "OR",
   "zipCode": "97204",
   "status": "ACTIVE"
   }
   ],
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
5. Inventory for SUMMER25-TOY campaign
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Inventory retrieved for campaign: SUMMER25-TOY",
   "data": [
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "quantityAvailable": 499800,
   "quantityReserved": 128000,
   "quantityRemaining": 371800,
   "sourceAsnNumber": "ASN-2025-001",
   "lastUpdatedAt": "2026-03-19T03:45:40"
   },
   {
   "sku": "TOY-SPACE-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "quantityAvailable": 249950,
   "quantityReserved": 0,
   "quantityRemaining": 249950,
   "sourceAsnNumber": "ASN-2025-003",
   "lastUpdatedAt": "2026-03-19T03:45:40"
   }
   ],
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
6. Inventory: TOY-DINO-MIX-001 / SUMMER25-TOY
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Inventory retrieved for SKU: TOY-DINO-MIX-001",
   "data": {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "quantityAvailable": 499800,
   "quantityReserved": 128000,
   "quantityRemaining": 371800,
   "sourceAsnNumber": "ASN-2025-001",
   "lastUpdatedAt": "2026-03-19T03:45:40"
   },
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
7. List all seeded store orders
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Orders retrieved",
   "data": [
   {
   "externalId": "ord-001-uuid",
   "orderNumber": "ORD-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "distributionDc": "DC-CHICAGO",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "quantityRequested": 128000,
   "quantityAllocated": 128000,
   "quantityPerStore": 200,
   "requestedDeliveryDate": "2025-06-01",
   "allocatedAt": "2026-01-20T03:00:00",
   "status": "ALLOCATED",
   "createdBy": "oms.planner",
   "notes": "Midwest allocation: 640 stores x 200 units each. Reserved from ASN-2025-001.",
   "createdAt": "2026-03-19T03:45:40",
   "updatedAt": "2026-03-19T03:45:40",
   "orderLines": [
   {
   "storeExternalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "city": "Chicago",
   "stateCode": "IL",
   "quantityAllocated": 200,
   "quantityShipped": 0,
   "quantityDelivered": 0,
   "status": "ALLOCATED"
   },
   {
   "storeExternalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "city": "Naperville",
   "stateCode": "IL",
   "quantityAllocated": 200,
   "quantityShipped": 0,
   "quantityDelivered": 0,
   "status": "ALLOCATED"
   },
   {
   "storeExternalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "city": "Milwaukee",
   "stateCode": "WI",
   "quantityAllocated": 200,
   "quantityShipped": 0,
   "quantityDelivered": 0,
   "status": "ALLOCATED"
   },
   {
   "storeExternalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "city": "Indianapolis",
   "stateCode": "IN",
   "quantityAllocated": 200,
   "quantityShipped": 0,
   "quantityDelivered": 0,
   "status": "ALLOCATED"
   }
   ]
   },
   {
   "externalId": "ord-002-uuid",
   "orderNumber": "ORD-2025-002",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-WEST",
   "regionName": "Western United States",
   "distributionDc": "DC-LOS-ANGELES",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "quantityRequested": 116000,
   "quantityAllocated": 0,
   "quantityPerStore": null,
   "requestedDeliveryDate": "2025-06-01",
   "allocatedAt": null,
   "status": "DRAFT",
   "createdBy": "oms.planner",
   "notes": "West allocation: 580 stores x 200 units each. Pending submission and allocation.",
   "createdAt": "2026-03-19T03:45:40",
   "updatedAt": "2026-03-19T03:45:40",
   "orderLines": []
   }
   ],
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
8. Get ORD-2025-001 (ALLOCATED with 4 store lines)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Order retrieved",
   "data": {
   "externalId": "ord-001-uuid",
   "orderNumber": "ORD-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-MIDWEST",
   "regionName": "Midwest United States",
   "distributionDc": "DC-CHICAGO",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "quantityRequested": 128000,
   "quantityAllocated": 128000,
   "quantityPerStore": 200,
   "requestedDeliveryDate": "2025-06-01",
   "allocatedAt": "2026-01-20T03:00:00",
   "status": "ALLOCATED",
   "createdBy": "oms.planner",
   "notes": "Midwest allocation: 640 stores x 200 units each. Reserved from ASN-2025-001.",
   "createdAt": "2026-03-19T03:45:40",
   "updatedAt": "2026-03-19T03:45:40",
   "orderLines": [
   {
   "storeExternalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "city": "Chicago",
   "stateCode": "IL",
   "quantityAllocated": 200,
   "quantityShipped": 0,
   "quantityDelivered": 0,
   "status": "ALLOCATED"
   },
   {
   "storeExternalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "city": "Naperville",
   "stateCode": "IL",
   "quantityAllocated": 200,
   "quantityShipped": 0,
   "quantityDelivered": 0,
   "status": "ALLOCATED"
   },
   {
   "storeExternalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "city": "Milwaukee",
   "stateCode": "WI",
   "quantityAllocated": 200,
   "quantityShipped": 0,
   "quantityDelivered": 0,
   "status": "ALLOCATED"
   },
   {
   "storeExternalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "city": "Indianapolis",
   "stateCode": "IN",
   "quantityAllocated": 200,
   "quantityShipped": 0,
   "quantityDelivered": 0,
   "status": "ALLOCATED"
   }
   ]
   },
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
9. Audit events for ORD-2025-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Order events retrieved",
   "data": [
   {
   "id": 1,
   "eventType": "ORDER_CREATED",
   "previousStatus": null,
   "newStatus": "DRAFT",
   "notes": "Store order created for Midwest region.",
   "triggeredBy": "oms.planner",
   "rabbitmqPublished": false,
   "eventAt": "2026-03-19T03:45:40"
   },
   {
   "id": 2,
   "eventType": "ORDER_SUBMITTED",
   "previousStatus": "DRAFT",
   "newStatus": "SUBMITTED",
   "notes": "Order submitted for allocation.",
   "triggeredBy": "oms.planner",
   "rabbitmqPublished": false,
   "eventAt": "2026-03-19T03:45:40"
   },
   {
   "id": 3,
   "eventType": "ORDER_ALLOCATED",
   "previousStatus": "SUBMITTED",
   "newStatus": "ALLOCATED",
   "notes": "640 stores x 200 units. Total 128,000 units reserved from TOY-DINO-MIX-001.",
   "triggeredBy": "oms.system",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T03:45:40"
   }
   ],
   "timestamp": "2026-03-19T08:53:23"
   }

══════════════════════════════════════
10. Update inventory — simulate WMS putaway.completed → erp.oms.inventory.updated
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Inventory updated successfully",
    "data": {
    "sku": "TOY-SPACE-MIX-001",
    "campaignCode": "SUMMER25-TOY",
    "quantityAvailable": 249950,
    "quantityReserved": 0,
    "quantityRemaining": 249950,
    "sourceAsnNumber": "ASN-2025-003",
    "lastUpdatedAt": "2026-03-19T03:45:40"
    },
    "timestamp": "2026-03-19T08:53:23"
    }
    ✔ SPACE inventory confirmed in OMS: 249,950 units

══════════════════════════════════════
11. Create new store order (DRAFT) for SOUTHEAST → erp.oms.store-order.created
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Store order created successfully",
    "data": {
    "externalId": "a094fc71-2302-4981-b13d-d4a270480a76",
    "orderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "regionName": "Southeast United States",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 104000,
    "quantityAllocated": 0,
    "quantityPerStore": null,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": null,
    "status": "DRAFT",
    "createdBy": "oms.planner",
    "notes": "Southeast allocation: 520 stores x 200 units each.",
    "createdAt": "2026-03-19T08:53:23",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": []
    },
    "timestamp": "2026-03-19T08:53:23"
    }
    ✔ New order externalId: a094fc71-2302-4981-b13d-d4a270480a76

══════════════════════════════════════
12. Submit order → erp.oms.store-order.submitted
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order submitted",
    "data": {
    "externalId": "a094fc71-2302-4981-b13d-d4a270480a76",
    "orderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "regionName": "Southeast United States",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 104000,
    "quantityAllocated": 0,
    "quantityPerStore": null,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": null,
    "status": "SUBMITTED",
    "createdBy": "oms.planner",
    "notes": "Southeast allocation: 520 stores x 200 units each.",
    "createdAt": "2026-03-19T08:53:23",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": []
    },
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
13. ALLOCATE order → erp.oms.store-order.allocated (WMS Outbound trigger)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order allocated successfully",
    "data": {
    "externalId": "a094fc71-2302-4981-b13d-d4a270480a76",
    "orderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "regionName": "Southeast United States",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 104000,
    "quantityAllocated": 104000,
    "quantityPerStore": 26000,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": "2026-03-19T08:53:23",
    "status": "ALLOCATED",
    "createdBy": "oms.planner",
    "notes": "Southeast allocation: 520 stores x 200 units each.",
    "createdAt": "2026-03-19T08:53:23",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    }
    ]
    },
    "timestamp": "2026-03-19T08:53:23"
    }
    ✔ KEY EVENT published: erp.oms.store-order.allocated
    ✔ WMS Outbound will create pick waves from this event

══════════════════════════════════════
14. Verify order + store lines after allocation
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order retrieved",
    "data": {
    "externalId": "a094fc71-2302-4981-b13d-d4a270480a76",
    "orderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "regionName": "Southeast United States",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 104000,
    "quantityAllocated": 104000,
    "quantityPerStore": 26000,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": "2026-03-19T08:53:24",
    "status": "ALLOCATED",
    "createdBy": "oms.planner",
    "notes": "Southeast allocation: 520 stores x 200 units each.",
    "createdAt": "2026-03-19T08:53:23",
    "updatedAt": "2026-03-19T08:53:24",
    "orderLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    }
    ]
    },
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
15. Mark PICKING → erp.oms.store-order.picking
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order picking started",
    "data": {
    "externalId": "a094fc71-2302-4981-b13d-d4a270480a76",
    "orderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "regionName": "Southeast United States",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 104000,
    "quantityAllocated": 104000,
    "quantityPerStore": 26000,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": "2026-03-19T08:53:24",
    "status": "PICKING",
    "createdBy": "oms.planner",
    "notes": "Southeast allocation: 520 stores x 200 units each.",
    "createdAt": "2026-03-19T08:53:23",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantityAllocated": 26000,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    }
    ]
    },
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
16. Mark SHIPPED → erp.oms.store-order.shipped
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order shipped",
    "data": {
    "externalId": "a094fc71-2302-4981-b13d-d4a270480a76",
    "orderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "regionName": "Southeast United States",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 104000,
    "quantityAllocated": 104000,
    "quantityPerStore": 26000,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": "2026-03-19T08:53:24",
    "status": "SHIPPED",
    "createdBy": "oms.planner",
    "notes": "Southeast allocation: 520 stores x 200 units each.",
    "createdAt": "2026-03-19T08:53:23",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 0,
    "status": "SHIPPED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 0,
    "status": "SHIPPED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 0,
    "status": "SHIPPED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 0,
    "status": "SHIPPED"
    }
    ]
    },
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
17. Mark DELIVERED → erp.oms.store-order.delivered
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order delivered",
    "data": {
    "externalId": "a094fc71-2302-4981-b13d-d4a270480a76",
    "orderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "regionName": "Southeast United States",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 104000,
    "quantityAllocated": 104000,
    "quantityPerStore": 26000,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": "2026-03-19T08:53:24",
    "status": "DELIVERED",
    "createdBy": "oms.planner",
    "notes": "Southeast allocation: 520 stores x 200 units each.",
    "createdAt": "2026-03-19T08:53:23",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 26000,
    "status": "DELIVERED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 26000,
    "status": "DELIVERED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 26000,
    "status": "DELIVERED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 26000,
    "status": "DELIVERED"
    }
    ]
    },
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
18. Full audit trail (7 events from DRAFT → DELIVERED)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order events retrieved",
    "data": [
    {
    "id": 7,
    "eventType": "ORDER_ALLOCATED",
    "previousStatus": "SUBMITTED",
    "newStatus": "ALLOCATED",
    "notes": "4 stores x ~26000 units. Total=104000",
    "triggeredBy": "oms.system",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T08:53:24"
    },
    {
    "id": 8,
    "eventType": "ORDER_PICKING",
    "previousStatus": "ALLOCATED",
    "newStatus": "PICKING",
    "notes": "Pick wave WV-2025-003 started. 520 store cartons being picked.",
    "triggeredBy": "wms.outbound",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T08:53:24"
    },
    {
    "id": 9,
    "eventType": "ORDER_SHIPPED",
    "previousStatus": "PICKING",
    "newStatus": "SHIPPED",
    "notes": "All 520 store cartons loaded on outbound trucks. En route to Southeast stores.",
    "triggeredBy": "tms.carrier",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T08:53:24"
    },
    {
    "id": 10,
    "eventType": "ORDER_DELIVERED",
    "previousStatus": "SHIPPED",
    "newStatus": "DELIVERED",
    "notes": "Delivery confirmed at all 520 SE store locations. POD received.",
    "triggeredBy": "tms.carrier",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T08:53:24"
    },
    {
    "id": 5,
    "eventType": "ORDER_CREATED",
    "previousStatus": null,
    "newStatus": "DRAFT",
    "notes": "Order created for region US-SOUTHEAST",
    "triggeredBy": "oms.planner",
    "rabbitmqPublished": false,
    "eventAt": "2026-03-19T08:53:23"
    },
    {
    "id": 6,
    "eventType": "ORDER_SUBMITTED",
    "previousStatus": "DRAFT",
    "newStatus": "SUBMITTED",
    "notes": "Inventory confirmed. Submitting for allocation.",
    "triggeredBy": "oms.planner",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T08:53:23"
    }
    ],
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
19. Create order then cancel — inventory release guard
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order cancelled",
    "data": {
    "externalId": "15fdd5a7-183c-4a07-b258-b5e002d64bc1",
    "orderNumber": "ORD-2025-CANCEL",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-NORTHWEST",
    "regionName": "Northwest United States",
    "distributionDc": "DC-SEATTLE",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Test cancel order",
    "quantityRequested": 10000,
    "quantityAllocated": 0,
    "quantityPerStore": null,
    "requestedDeliveryDate": "2025-06-15",
    "allocatedAt": null,
    "status": "CANCELLED",
    "createdBy": "test.user",
    "notes": null,
    "createdAt": "2026-03-19T08:53:24",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": []
    },
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
20. Order exceeding available inventory (expect 422 Unprocessable)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order submitted",
    "data": {
    "externalId": "5e8171a2-9d90-4af8-bc5d-0324cf82b60a",
    "orderNumber": "ORD-2025-HUGE",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-WEST",
    "regionName": "Western United States",
    "distributionDc": "DC-LOS-ANGELES",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Too large order",
    "quantityRequested": 9999999,
    "quantityAllocated": 0,
    "quantityPerStore": null,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": null,
    "status": "SUBMITTED",
    "createdBy": "test",
    "notes": null,
    "createdAt": "2026-03-19T08:53:24",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": []
    },
    "timestamp": "2026-03-19T08:53:23"
    }
    {
    "success": false,
    "message": "Insufficient inventory. Requested=9999999 Available=267800 for SKU=TOY-DINO-MIX-001",
    "data": null,
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
21. Duplicate order number (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "Order number already exists: ORD-2025-003",
    "data": null,
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
22. Filter orders by campaign SUMMER25-TOY
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Orders retrieved for campaign: SUMMER25-TOY",
    "data": [
    {
    "externalId": "ord-001-uuid",
    "orderNumber": "ORD-2025-001",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-MIDWEST",
    "regionName": "Midwest United States",
    "distributionDc": "DC-CHICAGO",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 128000,
    "quantityAllocated": 128000,
    "quantityPerStore": 200,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": "2026-01-20T03:00:00",
    "status": "ALLOCATED",
    "createdBy": "oms.planner",
    "notes": "Midwest allocation: 640 stores x 200 units each. Reserved from ASN-2025-001.",
    "createdAt": "2026-03-19T03:45:40",
    "updatedAt": "2026-03-19T03:45:40",
    "orderLines": [
    {
    "storeExternalId": "str-001-uuid",
    "storeNumber": "STR-0001",
    "storeName": "Burger Bliss Chicago Downtown",
    "city": "Chicago",
    "stateCode": "IL",
    "quantityAllocated": 200,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-002-uuid",
    "storeNumber": "STR-0002",
    "storeName": "Burger Bliss Naperville",
    "city": "Naperville",
    "stateCode": "IL",
    "quantityAllocated": 200,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-003-uuid",
    "storeNumber": "STR-0003",
    "storeName": "Burger Bliss Milwaukee",
    "city": "Milwaukee",
    "stateCode": "WI",
    "quantityAllocated": 200,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    },
    {
    "storeExternalId": "str-004-uuid",
    "storeNumber": "STR-0004",
    "storeName": "Burger Bliss Indianapolis",
    "city": "Indianapolis",
    "stateCode": "IN",
    "quantityAllocated": 200,
    "quantityShipped": 0,
    "quantityDelivered": 0,
    "status": "ALLOCATED"
    }
    ]
    },
    {
    "externalId": "ord-002-uuid",
    "orderNumber": "ORD-2025-002",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-WEST",
    "regionName": "Western United States",
    "distributionDc": "DC-LOS-ANGELES",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 116000,
    "quantityAllocated": 0,
    "quantityPerStore": null,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": null,
    "status": "DRAFT",
    "createdBy": "oms.planner",
    "notes": "West allocation: 580 stores x 200 units each. Pending submission and allocation.",
    "createdAt": "2026-03-19T03:45:40",
    "updatedAt": "2026-03-19T03:45:40",
    "orderLines": []
    },
    {
    "externalId": "a094fc71-2302-4981-b13d-d4a270480a76",
    "orderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "regionName": "Southeast United States",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 104000,
    "quantityAllocated": 104000,
    "quantityPerStore": 26000,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": "2026-03-19T08:53:24",
    "status": "DELIVERED",
    "createdBy": "oms.planner",
    "notes": "Southeast allocation: 520 stores x 200 units each.",
    "createdAt": "2026-03-19T08:53:23",
    "updatedAt": "2026-03-19T08:53:24",
    "orderLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 26000,
    "status": "DELIVERED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 26000,
    "status": "DELIVERED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 26000,
    "status": "DELIVERED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantityAllocated": 26000,
    "quantityShipped": 26000,
    "quantityDelivered": 26000,
    "status": "DELIVERED"
    }
    ]
    },
    {
    "externalId": "15fdd5a7-183c-4a07-b258-b5e002d64bc1",
    "orderNumber": "ORD-2025-CANCEL",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-NORTHWEST",
    "regionName": "Northwest United States",
    "distributionDc": "DC-SEATTLE",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Test cancel order",
    "quantityRequested": 10000,
    "quantityAllocated": 0,
    "quantityPerStore": null,
    "requestedDeliveryDate": "2025-06-15",
    "allocatedAt": null,
    "status": "CANCELLED",
    "createdBy": "test.user",
    "notes": null,
    "createdAt": "2026-03-19T08:53:24",
    "updatedAt": "2026-03-19T08:53:24",
    "orderLines": []
    },
    {
    "externalId": "5e8171a2-9d90-4af8-bc5d-0324cf82b60a",
    "orderNumber": "ORD-2025-HUGE",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-WEST",
    "regionName": "Western United States",
    "distributionDc": "DC-LOS-ANGELES",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Too large order",
    "quantityRequested": 9999999,
    "quantityAllocated": 0,
    "quantityPerStore": null,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": null,
    "status": "SUBMITTED",
    "createdBy": "test",
    "notes": null,
    "createdAt": "2026-03-19T08:53:24",
    "updatedAt": "2026-03-19T08:53:24",
    "orderLines": []
    }
    ],
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
23. Drive seeded ORD-2025-002 (DRAFT → SUBMITTED)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Order submitted",
    "data": {
    "externalId": "ord-002-uuid",
    "orderNumber": "ORD-2025-002",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-WEST",
    "regionName": "Western United States",
    "distributionDc": "DC-LOS-ANGELES",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested": 116000,
    "quantityAllocated": 0,
    "quantityPerStore": null,
    "requestedDeliveryDate": "2025-06-01",
    "allocatedAt": null,
    "status": "SUBMITTED",
    "createdBy": "oms.planner",
    "notes": "West allocation: 580 stores x 200 units each. Pending submission and allocation.",
    "createdAt": "2026-03-19T03:45:40",
    "updatedAt": "2026-03-19T08:53:23",
    "orderLines": []
    },
    "timestamp": "2026-03-19T08:53:23"
    }

══════════════════════════════════════
24. Actuator Health Check
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
    "free": 893803896832,
    "threshold": 10485760,
    "path": "/Users/binit.datta/tms_enterprise_poc/cs-oms-api/.",
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
✔   erp.oms.inventory.updated         — WMS putaway synced to OMS
✔   erp.oms.store-order.created       — new order drafted
✔   erp.oms.store-order.submitted     — order ready for allocation
✔   erp.oms.store-order.allocated     — KEY: WMS Outbound creates pick wave
✔   erp.oms.store-order.picking       — WMS picking in progress
✔   erp.oms.store-order.shipped       — trucks en route to stores
✔   erp.oms.store-order.delivered     — toys in restaurants
✔   erp.oms.store-order.cancelled     — cancelled with inventory release
✔ Check: http://localhost:15672 → Queues → control-tower-test
binit.datta@C6NWKQ290Y cs-oms-api % 