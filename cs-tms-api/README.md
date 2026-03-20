# cs-tms-api
**TMS — Delivery Load Tracking, Store Delivery, Proof of Delivery**

Spring Boot 3.4.3 | JDK 21 | MySQL 8 | RabbitMQ | JPA | Port 8087

---

## Domain

The final Spring Boot service in the supply chain. Receives dispatched shipments
from WMS Outbound, tracks carrier delivery to each restaurant store, and issues
Proof of Delivery (POD) confirmation.

```
erp.wms.outbound.shipment.dispatched
        ↓
  Delivery Load CREATED      ──→  erp.tms.load.created
        ↓
  ASSIGNED (driver + truck)  ──→  erp.tms.load.assigned
        ↓
  IN_TRANSIT                 ──→  erp.tms.load.in-transit
                             ──→  erp.tms.delivery.out-for-delivery
        ↓
  POD confirmed per store    (each store individually)
        ↓
  ALL stores POD_CONFIRMED
        ↓
  COMPLETED (auto)           ──→  erp.tms.load.completed
                             ──→  erp.tms.delivery.pod-confirmed  ← FINAL EVENT
                                        ↑ consumed by Flask Control Tower
                                          for BI dashboards + analytics
```

---

## Setup

### Step 1 — MySQL Workbench
1. `db/01_ddl_cs_tms.sql` — creates `cs_tms` DB, `tms_app` user (no DDL), 4 tables
2. `db/02_seed_cs_tms.sql` — seeds LOAD-2025-001 (COMPLETED, 4 stores POD_CONFIRMED), transit events, audit trail

### Step 2 — Fix pom.xml and run (port 8087)
```bash
sed -i '' 's|<n>cs-tms-api</n>|<name>cs-tms-api</name>|' pom.xml
mvn clean install -DskipTests
java -jar target/cs-tms-api-1.0.0-SNAPSHOT.jar
```

### Step 3 — Test
```bash
chmod +x test_cs_tms_api.sh && ./test_cs_tms_api.sh
```

---

## REST Endpoints

| Method | Path                                                       | Description                            |
|--------|------------------------------------------------------------|----------------------------------------|
| POST   | /api/v1/delivery-loads                                     | Create delivery load                   |
| GET    | /api/v1/delivery-loads                                     | List all loads                         |
| GET    | /api/v1/delivery-loads/{id}                                | Get load with store deliveries         |
| GET    | /api/v1/delivery-loads/status/{status}                     | Filter by status                       |
| GET    | /api/v1/delivery-loads/campaign/{code}                     | Filter by campaign                     |
| GET    | /api/v1/delivery-loads/{id}/transit-events                 | Carrier tracking milestones            |
| GET    | /api/v1/delivery-loads/{id}/events                         | TMS audit trail                        |
| POST   | /api/v1/delivery-loads/{id}/assign                         | → ASSIGNED (driver + truck)            |
| POST   | /api/v1/delivery-loads/{id}/in-transit                     | → IN_TRANSIT                           |
| POST   | /api/v1/delivery-loads/{id}/transit-events                 | Append carrier milestone               |
| POST   | /api/v1/delivery-loads/{id}/store-deliveries/{sdId}/pod    | Confirm POD at store                   |
| GET    | /actuator/health                                           | Health check                           |

---

## RabbitMQ Events Published

| Event                       | Routing Key                              |
|-----------------------------|------------------------------------------|
| Load created                | `erp.tms.load.created`                  |
| Driver assigned             | `erp.tms.load.assigned`                 |
| Load in transit             | `erp.tms.load.in-transit`               |
| Out for delivery            | `erp.tms.delivery.out-for-delivery`     |
| Load completed              | `erp.tms.load.completed`                |
| **POD confirmed (all stores)** | **`erp.tms.delivery.pod-confirmed`** |

Exchange: `erp.topic.exchange` (shared across all ERP services)

---

## Seeded Data

| Entity          | Number         | Status    | Details                                          |
|-----------------|----------------|-----------|---------------------------------------------------|
| Delivery Load   | LOAD-2025-001  | COMPLETED | Midwest, XPO, 4 stores all POD_CONFIRMED          |
| Store Deliveries| 4 Midwest stores| POD_CONFIRMED | Chicago, Naperville, Milwaukee, Indianapolis  |
| Transit Events  | 4 milestones   | —         | PICKUP → IN_TRANSIT → OUT_FOR_DELIVERY → DELIVERED|

---

## Full Supply Chain Summary

| # | Service              | Port | Key Event Published                              |
|---|----------------------|------|--------------------------------------------------|
| 1 | cs-crm-api           | 8081 | `erp.crm.campaign.launched`                      |
| 2 | cs-vendor-api        | 8082 | `erp.vendor.rfq.awarded`                         |
| 3 | cs-procurement-api   | 8083 | `erp.procurement.po.ready-to-ship`               |
| 4 | cs-wms-inbound-api   | 8084 | `erp.wms.inbound.putaway.completed`              |
| 5 | cs-oms-api           | 8085 | `erp.oms.store-order.allocated`                  |
| 6 | cs-wms-outbound-api  | 8086 | `erp.wms.outbound.shipment.dispatched`           |
| 7 | **cs-tms-api**       | **8087** | **`erp.tms.delivery.pod-confirmed`** ← FINAL |
| 8 | Flask Control Tower  | 5000 | BI dashboards + Anthropic NL query engine        |

binit.datta@C6NWKQ290Y cs-tms-api % chmod +x test_cs_tms_api.sh && ./test_cs_tms_api.sh

══════════════════════════════════════
1. List seeded loads (LOAD-2025-001 COMPLETED)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Loads retrieved",
   "data": [
   {
   "externalId": "load-001-uuid",
   "loadNumber": "LOAD-2025-001",
   "shipmentExternalId": "shp-001-uuid",
   "shipmentNumber": "SHP-2025-001",
   "storeOrderExternalId": "ord-001-uuid",
   "storeOrderNumber": "ORD-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-MIDWEST",
   "distributionDc": "DC-CHICAGO",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalCartons": 4,
   "totalUnits": 128000,
   "carrierName": "XPO Logistics",
   "proNumber": "XPO-2025-MW-0441",
   "driverName": "Mike Johnson",
   "truckNumber": "XPO-TRUCK-5521",
   "requiredDeliveryDate": "2025-06-01",
   "pickupDate": "2025-05-20",
   "estimatedDeliveryDate": "2025-05-30",
   "status": "COMPLETED",
   "notes": "All 4 Midwest store deliveries completed. POD confirmed at all locations.",
   "createdBy": "tms.coordinator",
   "createdAt": "2026-03-19T08:11:46",
   "updatedAt": "2026-03-19T08:11:46",
   "storeDeliveries": [
   {
   "externalId": "sd-001-uuid",
   "storeExternalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "city": "Chicago",
   "stateCode": "IL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0001",
   "deliveredQuantity": 32000,
   "podSignatory": "Sarah Chen",
   "podNotes": "All 32,000 units received in good condition. Signed at dock.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-28T05:30:00",
   "podConfirmedAt": "2025-05-28T06:00:00"
   },
   {
   "externalId": "sd-002-uuid",
   "storeExternalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "city": "Naperville",
   "stateCode": "IL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0002",
   "deliveredQuantity": 32000,
   "podSignatory": "Tom Richards",
   "podNotes": "Full carton received. Stored in back stockroom.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-28T08:15:00",
   "podConfirmedAt": "2025-05-28T08:45:00"
   },
   {
   "externalId": "sd-003-uuid",
   "storeExternalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "city": "Milwaukee",
   "stateCode": "WI",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0003",
   "deliveredQuantity": 32000,
   "podSignatory": "Jessica Park",
   "podNotes": "Delivered to store manager. No damage reported.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-29T04:00:00",
   "podConfirmedAt": "2025-05-29T04:30:00"
   },
   {
   "externalId": "sd-004-uuid",
   "storeExternalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "city": "Indianapolis",
   "stateCode": "IN",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0004",
   "deliveredQuantity": 32000,
   "podSignatory": "David Torres",
   "podNotes": "Final delivery on this load. All 32,000 units confirmed.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-30T09:00:00",
   "podConfirmedAt": "2025-05-30T09:30:00"
   }
   ]
   }
   ],
   "timestamp": "2026-03-19T13:12:36"
   }

══════════════════════════════════════
2. Get LOAD-2025-001 (COMPLETED, 4 stores POD_CONFIRMED)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Load retrieved",
   "data": {
   "externalId": "load-001-uuid",
   "loadNumber": "LOAD-2025-001",
   "shipmentExternalId": "shp-001-uuid",
   "shipmentNumber": "SHP-2025-001",
   "storeOrderExternalId": "ord-001-uuid",
   "storeOrderNumber": "ORD-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-MIDWEST",
   "distributionDc": "DC-CHICAGO",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalCartons": 4,
   "totalUnits": 128000,
   "carrierName": "XPO Logistics",
   "proNumber": "XPO-2025-MW-0441",
   "driverName": "Mike Johnson",
   "truckNumber": "XPO-TRUCK-5521",
   "requiredDeliveryDate": "2025-06-01",
   "pickupDate": "2025-05-20",
   "estimatedDeliveryDate": "2025-05-30",
   "status": "COMPLETED",
   "notes": "All 4 Midwest store deliveries completed. POD confirmed at all locations.",
   "createdBy": "tms.coordinator",
   "createdAt": "2026-03-19T08:11:46",
   "updatedAt": "2026-03-19T08:11:46",
   "storeDeliveries": [
   {
   "externalId": "sd-001-uuid",
   "storeExternalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "city": "Chicago",
   "stateCode": "IL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0001",
   "deliveredQuantity": 32000,
   "podSignatory": "Sarah Chen",
   "podNotes": "All 32,000 units received in good condition. Signed at dock.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-28T05:30:00",
   "podConfirmedAt": "2025-05-28T06:00:00"
   },
   {
   "externalId": "sd-002-uuid",
   "storeExternalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "city": "Naperville",
   "stateCode": "IL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0002",
   "deliveredQuantity": 32000,
   "podSignatory": "Tom Richards",
   "podNotes": "Full carton received. Stored in back stockroom.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-28T08:15:00",
   "podConfirmedAt": "2025-05-28T08:45:00"
   },
   {
   "externalId": "sd-003-uuid",
   "storeExternalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "city": "Milwaukee",
   "stateCode": "WI",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0003",
   "deliveredQuantity": 32000,
   "podSignatory": "Jessica Park",
   "podNotes": "Delivered to store manager. No damage reported.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-29T04:00:00",
   "podConfirmedAt": "2025-05-29T04:30:00"
   },
   {
   "externalId": "sd-004-uuid",
   "storeExternalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "city": "Indianapolis",
   "stateCode": "IN",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0004",
   "deliveredQuantity": 32000,
   "podSignatory": "David Torres",
   "podNotes": "Final delivery on this load. All 32,000 units confirmed.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-30T09:00:00",
   "podConfirmedAt": "2025-05-30T09:30:00"
   }
   ]
   },
   "timestamp": "2026-03-19T13:12:36"
   }

══════════════════════════════════════
3. Transit events for LOAD-2025-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Transit events retrieved",
   "data": [
   {
   "id": 4,
   "eventCode": "DELIVERED",
   "eventDescription": "All Midwest stops completed.",
   "location": "Indianapolis, IN",
   "source": "CARRIER_API",
   "eventAt": "2025-05-30T09:30:00",
   "recordedAt": "2026-03-19T08:11:46"
   },
   {
   "id": 3,
   "eventCode": "OUT_FOR_DELIVERY",
   "eventDescription": "Driver beginning Chicago stops.",
   "location": "Chicago, IL",
   "source": "CARRIER_API",
   "eventAt": "2025-05-28T03:00:00",
   "recordedAt": "2026-03-19T08:11:46"
   },
   {
   "id": 2,
   "eventCode": "IN_TRANSIT",
   "eventDescription": "En route to Midwest stores.",
   "location": "Gary, IN",
   "source": "CARRIER_API",
   "eventAt": "2025-05-20T11:30:00",
   "recordedAt": "2026-03-19T08:11:46"
   },
   {
   "id": 1,
   "eventCode": "PICKUP",
   "eventDescription": "Shipment picked up from DC-CHICAGO.",
   "location": "Chicago, IL",
   "source": "CARRIER_API",
   "eventAt": "2025-05-20T09:00:00",
   "recordedAt": "2026-03-19T08:11:46"
   }
   ],
   "timestamp": "2026-03-19T13:12:36"
   }

══════════════════════════════════════
4. TMS audit events for LOAD-2025-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "TMS events retrieved",
   "data": [
   {
   "id": 1,
   "eventType": "LOAD_CREATED",
   "previousStatus": null,
   "newStatus": "CREATED",
   "notes": "Load created from WMS shipment dispatch event.",
   "triggeredBy": "tms.coordinator",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T08:11:46"
   },
   {
   "id": 2,
   "eventType": "LOAD_ASSIGNED",
   "previousStatus": "CREATED",
   "newStatus": "ASSIGNED",
   "notes": "Assigned to driver Mike Johnson, truck XPO-TRUCK-5521.",
   "triggeredBy": "tms.coordinator",
   "rabbitmqPublished": false,
   "eventAt": "2026-03-19T08:11:46"
   },
   {
   "id": 3,
   "eventType": "LOAD_IN_TRANSIT",
   "previousStatus": "ASSIGNED",
   "newStatus": "IN_TRANSIT",
   "notes": "Driver picked up load from DC-CHICAGO. PRO XPO-2025-MW-0441.",
   "triggeredBy": "xpo.carrier.api",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T08:11:46"
   },
   {
   "id": 4,
   "eventType": "LOAD_COMPLETED",
   "previousStatus": "IN_TRANSIT",
   "newStatus": "COMPLETED",
   "notes": "All 4 Midwest stores delivered and POD confirmed.",
   "triggeredBy": "tms.coordinator",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T08:11:46"
   }
   ],
   "timestamp": "2026-03-19T13:12:36"
   }

══════════════════════════════════════
5. Filter loads by campaign SUMMER25-TOY
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Loads for campaign: SUMMER25-TOY",
   "data": [
   {
   "externalId": "load-001-uuid",
   "loadNumber": "LOAD-2025-001",
   "shipmentExternalId": "shp-001-uuid",
   "shipmentNumber": "SHP-2025-001",
   "storeOrderExternalId": "ord-001-uuid",
   "storeOrderNumber": "ORD-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-MIDWEST",
   "distributionDc": "DC-CHICAGO",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalCartons": 4,
   "totalUnits": 128000,
   "carrierName": "XPO Logistics",
   "proNumber": "XPO-2025-MW-0441",
   "driverName": "Mike Johnson",
   "truckNumber": "XPO-TRUCK-5521",
   "requiredDeliveryDate": "2025-06-01",
   "pickupDate": "2025-05-20",
   "estimatedDeliveryDate": "2025-05-30",
   "status": "COMPLETED",
   "notes": "All 4 Midwest store deliveries completed. POD confirmed at all locations.",
   "createdBy": "tms.coordinator",
   "createdAt": "2026-03-19T08:11:46",
   "updatedAt": "2026-03-19T08:11:46",
   "storeDeliveries": [
   {
   "externalId": "sd-001-uuid",
   "storeExternalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "city": "Chicago",
   "stateCode": "IL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0001",
   "deliveredQuantity": 32000,
   "podSignatory": "Sarah Chen",
   "podNotes": "All 32,000 units received in good condition. Signed at dock.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-28T05:30:00",
   "podConfirmedAt": "2025-05-28T06:00:00"
   },
   {
   "externalId": "sd-002-uuid",
   "storeExternalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "city": "Naperville",
   "stateCode": "IL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0002",
   "deliveredQuantity": 32000,
   "podSignatory": "Tom Richards",
   "podNotes": "Full carton received. Stored in back stockroom.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-28T08:15:00",
   "podConfirmedAt": "2025-05-28T08:45:00"
   },
   {
   "externalId": "sd-003-uuid",
   "storeExternalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "city": "Milwaukee",
   "stateCode": "WI",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0003",
   "deliveredQuantity": 32000,
   "podSignatory": "Jessica Park",
   "podNotes": "Delivered to store manager. No damage reported.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-29T04:00:00",
   "podConfirmedAt": "2025-05-29T04:30:00"
   },
   {
   "externalId": "sd-004-uuid",
   "storeExternalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "city": "Indianapolis",
   "stateCode": "IN",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0004",
   "deliveredQuantity": 32000,
   "podSignatory": "David Torres",
   "podNotes": "Final delivery on this load. All 32,000 units confirmed.",
   "status": "POD_CONFIRMED",
   "deliveredAt": "2025-05-30T09:00:00",
   "podConfirmedAt": "2025-05-30T09:30:00"
   }
   ]
   }
   ],
   "timestamp": "2026-03-19T13:12:36"
   }

══════════════════════════════════════
6. Create LOAD-2025-002 (SE, Old Dominion) → erp.tms.load.created
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Delivery load created",
   "data": {
   "externalId": "18ead21f-f4e2-48a1-8efa-fbad63acfb80",
   "loadNumber": "LOAD-2025-002",
   "shipmentExternalId": "shp-002-ext-uuid",
   "shipmentNumber": "SHP-2025-002",
   "storeOrderExternalId": "ord-003-uuid",
   "storeOrderNumber": "ORD-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-SOUTHEAST",
   "distributionDc": "DC-ATLANTA",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalCartons": 4,
   "totalUnits": 104000,
   "carrierName": "Old Dominion Freight",
   "proNumber": "OD-2025-SE-8812",
   "driverName": null,
   "truckNumber": null,
   "requiredDeliveryDate": "2025-06-01",
   "pickupDate": null,
   "estimatedDeliveryDate": null,
   "status": "CREATED",
   "notes": "Southeast stores \u2014 4 cartons, Old Dominion PRO OD-2025-SE-8812.",
   "createdBy": "tms.coordinator",
   "createdAt": "2026-03-19T13:12:36",
   "updatedAt": "2026-03-19T13:12:36",
   "storeDeliveries": [
   {
   "externalId": "49c3fc19-c97a-4e78-b202-104dfdb7621e",
   "storeExternalId": "str-009-uuid",
   "storeNumber": "STR-0201",
   "storeName": "Burger Bliss Atlanta Midtown",
   "city": "Atlanta",
   "stateCode": "GA",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0001",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "PENDING",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "1be3f572-baa0-4b88-b1bf-68cffaa549f6",
   "storeExternalId": "str-010-uuid",
   "storeNumber": "STR-0202",
   "storeName": "Burger Bliss Miami Brickell",
   "city": "Miami",
   "stateCode": "FL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0002",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "PENDING",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "3056330a-dcd7-4cee-8563-5d220a1cb33f",
   "storeExternalId": "str-011-uuid",
   "storeNumber": "STR-0203",
   "storeName": "Burger Bliss Charlotte",
   "city": "Charlotte",
   "stateCode": "NC",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0003",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "PENDING",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "9da9c9c1-0b9c-43e3-a7c0-84eeee8b61bb",
   "storeExternalId": "str-012-uuid",
   "storeNumber": "STR-0204",
   "storeName": "Burger Bliss Nashville",
   "city": "Nashville",
   "stateCode": "TN",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0004",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "PENDING",
   "deliveredAt": null,
   "podConfirmedAt": null
   }
   ]
   },
   "timestamp": "2026-03-19T13:12:36"
   }
   ✔ New load externalId: 18ead21f-f4e2-48a1-8efa-fbad63acfb80
   ✔ Store deliveries: 49c3fc19-c97a-4e78-b202-104dfdb7621e | 1be3f572-baa0-4b88-b1bf-68cffaa549f6 | 3056330a-dcd7-4cee-8563-5d220a1cb33f | 9da9c9c1-0b9c-43e3-a7c0-84eeee8b61bb

══════════════════════════════════════
7. Assign driver + truck → erp.tms.load.assigned
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Driver assigned to load",
   "data": {
   "externalId": "18ead21f-f4e2-48a1-8efa-fbad63acfb80",
   "loadNumber": "LOAD-2025-002",
   "shipmentExternalId": "shp-002-ext-uuid",
   "shipmentNumber": "SHP-2025-002",
   "storeOrderExternalId": "ord-003-uuid",
   "storeOrderNumber": "ORD-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-SOUTHEAST",
   "distributionDc": "DC-ATLANTA",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalCartons": 4,
   "totalUnits": 104000,
   "carrierName": "Old Dominion Freight",
   "proNumber": "OD-2025-SE-8812",
   "driverName": "Carlos Mendez",
   "truckNumber": "OD-TRUCK-8812",
   "requiredDeliveryDate": "2025-06-01",
   "pickupDate": "2025-05-28",
   "estimatedDeliveryDate": "2025-06-01",
   "status": "ASSIGNED",
   "notes": "Southeast stores \u2014 4 cartons, Old Dominion PRO OD-2025-SE-8812.",
   "createdBy": "tms.coordinator",
   "createdAt": "2026-03-19T13:12:37",
   "updatedAt": "2026-03-19T13:12:36",
   "storeDeliveries": [
   {
   "externalId": "49c3fc19-c97a-4e78-b202-104dfdb7621e",
   "storeExternalId": "str-009-uuid",
   "storeNumber": "STR-0201",
   "storeName": "Burger Bliss Atlanta Midtown",
   "city": "Atlanta",
   "stateCode": "GA",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0001",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "PENDING",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "1be3f572-baa0-4b88-b1bf-68cffaa549f6",
   "storeExternalId": "str-010-uuid",
   "storeNumber": "STR-0202",
   "storeName": "Burger Bliss Miami Brickell",
   "city": "Miami",
   "stateCode": "FL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0002",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "PENDING",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "3056330a-dcd7-4cee-8563-5d220a1cb33f",
   "storeExternalId": "str-011-uuid",
   "storeNumber": "STR-0203",
   "storeName": "Burger Bliss Charlotte",
   "city": "Charlotte",
   "stateCode": "NC",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0003",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "PENDING",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "9da9c9c1-0b9c-43e3-a7c0-84eeee8b61bb",
   "storeExternalId": "str-012-uuid",
   "storeNumber": "STR-0204",
   "storeName": "Burger Bliss Nashville",
   "city": "Nashville",
   "stateCode": "TN",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0004",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "PENDING",
   "deliveredAt": null,
   "podConfirmedAt": null
   }
   ]
   },
   "timestamp": "2026-03-19T13:12:36"
   }

══════════════════════════════════════
8. Mark IN_TRANSIT → erp.tms.load.in-transit + erp.tms.delivery.out-for-delivery
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Load in transit",
   "data": {
   "externalId": "18ead21f-f4e2-48a1-8efa-fbad63acfb80",
   "loadNumber": "LOAD-2025-002",
   "shipmentExternalId": "shp-002-ext-uuid",
   "shipmentNumber": "SHP-2025-002",
   "storeOrderExternalId": "ord-003-uuid",
   "storeOrderNumber": "ORD-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-SOUTHEAST",
   "distributionDc": "DC-ATLANTA",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalCartons": 4,
   "totalUnits": 104000,
   "carrierName": "Old Dominion Freight",
   "proNumber": "OD-2025-SE-8812",
   "driverName": "Carlos Mendez",
   "truckNumber": "OD-TRUCK-8812",
   "requiredDeliveryDate": "2025-06-01",
   "pickupDate": "2025-05-28",
   "estimatedDeliveryDate": "2025-06-01",
   "status": "IN_TRANSIT",
   "notes": "Southeast stores \u2014 4 cartons, Old Dominion PRO OD-2025-SE-8812.",
   "createdBy": "tms.coordinator",
   "createdAt": "2026-03-19T13:12:37",
   "updatedAt": "2026-03-19T13:12:36",
   "storeDeliveries": [
   {
   "externalId": "49c3fc19-c97a-4e78-b202-104dfdb7621e",
   "storeExternalId": "str-009-uuid",
   "storeNumber": "STR-0201",
   "storeName": "Burger Bliss Atlanta Midtown",
   "city": "Atlanta",
   "stateCode": "GA",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0001",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "OUT_FOR_DELIVERY",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "1be3f572-baa0-4b88-b1bf-68cffaa549f6",
   "storeExternalId": "str-010-uuid",
   "storeNumber": "STR-0202",
   "storeName": "Burger Bliss Miami Brickell",
   "city": "Miami",
   "stateCode": "FL",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0002",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "OUT_FOR_DELIVERY",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "3056330a-dcd7-4cee-8563-5d220a1cb33f",
   "storeExternalId": "str-011-uuid",
   "storeNumber": "STR-0203",
   "storeName": "Burger Bliss Charlotte",
   "city": "Charlotte",
   "stateCode": "NC",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0003",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "OUT_FOR_DELIVERY",
   "deliveredAt": null,
   "podConfirmedAt": null
   },
   {
   "externalId": "9da9c9c1-0b9c-43e3-a7c0-84eeee8b61bb",
   "storeExternalId": "str-012-uuid",
   "storeNumber": "STR-0204",
   "storeName": "Burger Bliss Nashville",
   "city": "Nashville",
   "stateCode": "TN",
   "sku": "TOY-DINO-MIX-001",
   "quantity": 26000,
   "cartonLabel": "CTN-SE-0004",
   "deliveredQuantity": null,
   "podSignatory": null,
   "podNotes": null,
   "status": "OUT_FOR_DELIVERY",
   "deliveredAt": null,
   "podConfirmedAt": null
   }
   ]
   },
   "timestamp": "2026-03-19T13:12:36"
   }

══════════════════════════════════════
9. Record carrier transit milestones
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Transit event recorded",
   "data": {
   "id": 5,
   "eventCode": "PICKUP",
   "eventDescription": "Load picked up from DC-ATLANTA.",
   "location": "Atlanta, GA",
   "source": "CARRIER_API",
   "eventAt": "2026-03-19T13:12:36",
   "recordedAt": "2026-03-19T13:12:36"
   },
   "timestamp": "2026-03-19T13:12:36"
   }
   {
   "success": true,
   "message": "Transit event recorded",
   "data": {
   "id": 6,
   "eventCode": "IN_TRANSIT",
   "eventDescription": "En route to Southeast stores.",
   "location": "Macon, GA",
   "source": "CARRIER_API",
   "eventAt": "2026-03-19T13:12:36",
   "recordedAt": "2026-03-19T13:12:36"
   },
   "timestamp": "2026-03-19T13:12:36"
   }
   ✔ Carrier milestones recorded

══════════════════════════════════════
10. Confirm POD — Burger Bliss Atlanta
    ══════════════════════════════════════
    {
    "success": true,
    "message": "POD confirmed",
    "data": {
    "externalId": "49c3fc19-c97a-4e78-b202-104dfdb7621e",
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "deliveredQuantity": 26000,
    "podSignatory": "Maria Gonzalez",
    "podNotes": "Full carton received at Atlanta. 26,000 dino toys. Signed at receiving dock.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-29T10:00:00",
    "podConfirmedAt": "2026-03-19T13:12:36"
    },
    "timestamp": "2026-03-19T13:12:36"
    }

══════════════════════════════════════
11. Confirm POD — Burger Bliss Miami
    ══════════════════════════════════════
    {
    "success": true,
    "message": "POD confirmed",
    "data": {
    "externalId": "1be3f572-baa0-4b88-b1bf-68cffaa549f6",
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "deliveredQuantity": 26000,
    "podSignatory": "James Williams",
    "podNotes": "All 26,000 units received in good condition. Stored in back room.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-29T14:30:00",
    "podConfirmedAt": "2026-03-19T13:12:36"
    },
    "timestamp": "2026-03-19T13:12:36"
    }

══════════════════════════════════════
12. Confirm POD — Burger Bliss Charlotte
    ══════════════════════════════════════
    {
    "success": true,
    "message": "POD confirmed",
    "data": {
    "externalId": "3056330a-dcd7-4cee-8563-5d220a1cb33f",
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "deliveredQuantity": 26000,
    "podSignatory": "Angela Davis",
    "podNotes": "Delivery accepted. No damage. Carton label CTN-SE-0003 scanned.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-30T09:15:00",
    "podConfirmedAt": "2026-03-19T13:12:36"
    },
    "timestamp": "2026-03-19T13:12:36"
    }

══════════════════════════════════════
13. Confirm POD — Burger Bliss Nashville → TRIGGERS FINAL SUPPLY CHAIN EVENTS
    ══════════════════════════════════════
    {
    "success": true,
    "message": "POD confirmed",
    "data": {
    "externalId": "9da9c9c1-0b9c-43e3-a7c0-84eeee8b61bb",
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "deliveredQuantity": 26000,
    "podSignatory": "Robert Kim",
    "podNotes": "Final delivery on this load. All 26,000 Nashville units confirmed.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-30T15:00:00",
    "podConfirmedAt": "2026-03-19T13:12:36"
    },
    "timestamp": "2026-03-19T13:12:36"
    }
    ✔ ALL 4 STORES POD CONFIRMED — Load auto-completed!
    ✔ KEY EVENT: erp.tms.delivery.pod-confirmed published (FINAL supply chain event)
    ✔ erp.tms.load.completed published
    ✔ Flask Control Tower will receive this and update BI dashboard

══════════════════════════════════════
14. Verify load COMPLETED — all 4 stores POD_CONFIRMED
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Load retrieved",
    "data": {
    "externalId": "18ead21f-f4e2-48a1-8efa-fbad63acfb80",
    "loadNumber": "LOAD-2025-002",
    "shipmentExternalId": "shp-002-ext-uuid",
    "shipmentNumber": "SHP-2025-002",
    "storeOrderExternalId": "ord-003-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 104000,
    "carrierName": "Old Dominion Freight",
    "proNumber": "OD-2025-SE-8812",
    "driverName": "Carlos Mendez",
    "truckNumber": "OD-TRUCK-8812",
    "requiredDeliveryDate": "2025-06-01",
    "pickupDate": "2025-05-28",
    "estimatedDeliveryDate": "2025-06-01",
    "status": "COMPLETED",
    "notes": "Southeast stores \u2014 4 cartons, Old Dominion PRO OD-2025-SE-8812.",
    "createdBy": "tms.coordinator",
    "createdAt": "2026-03-19T13:12:37",
    "updatedAt": "2026-03-19T13:12:37",
    "storeDeliveries": [
    {
    "externalId": "49c3fc19-c97a-4e78-b202-104dfdb7621e",
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "deliveredQuantity": 26000,
    "podSignatory": "Maria Gonzalez",
    "podNotes": "Full carton received at Atlanta. 26,000 dino toys. Signed at receiving dock.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-29T10:00:00",
    "podConfirmedAt": "2026-03-19T13:12:37"
    },
    {
    "externalId": "1be3f572-baa0-4b88-b1bf-68cffaa549f6",
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "deliveredQuantity": 26000,
    "podSignatory": "James Williams",
    "podNotes": "All 26,000 units received in good condition. Stored in back room.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-29T14:30:00",
    "podConfirmedAt": "2026-03-19T13:12:37"
    },
    {
    "externalId": "3056330a-dcd7-4cee-8563-5d220a1cb33f",
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "deliveredQuantity": 26000,
    "podSignatory": "Angela Davis",
    "podNotes": "Delivery accepted. No damage. Carton label CTN-SE-0003 scanned.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-30T09:15:00",
    "podConfirmedAt": "2026-03-19T13:12:37"
    },
    {
    "externalId": "9da9c9c1-0b9c-43e3-a7c0-84eeee8b61bb",
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "deliveredQuantity": 26000,
    "podSignatory": "Robert Kim",
    "podNotes": "Final delivery on this load. All 26,000 Nashville units confirmed.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-30T15:00:00",
    "podConfirmedAt": "2026-03-19T13:12:37"
    }
    ]
    },
    "timestamp": "2026-03-19T13:12:36"
    }

══════════════════════════════════════
15. Full TMS audit trail (CREATED → ASSIGNED → IN_TRANSIT → COMPLETED)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "TMS events retrieved",
    "data": [
    {
    "id": 5,
    "eventType": "LOAD_CREATED",
    "previousStatus": null,
    "newStatus": "CREATED",
    "notes": "Load created from WMS shipment SHP-2025-002",
    "triggeredBy": "tms.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T13:12:37"
    },
    {
    "id": 6,
    "eventType": "LOAD_ASSIGNED",
    "previousStatus": "CREATED",
    "newStatus": "ASSIGNED",
    "notes": "Driver: Carlos Mendez Truck: OD-TRUCK-8812",
    "triggeredBy": "tms.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T13:12:37"
    },
    {
    "id": 7,
    "eventType": "LOAD_IN_TRANSIT",
    "previousStatus": "ASSIGNED",
    "newStatus": "IN_TRANSIT",
    "notes": "PRO: OD-2025-SE-8812. Driver Carlos Mendez picked up load from DC-ATLANTA. PRO OD-2025-SE-8812 active.",
    "triggeredBy": "od.carrier.api",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T13:12:37"
    },
    {
    "id": 8,
    "eventType": "LOAD_COMPLETED",
    "previousStatus": "IN_TRANSIT",
    "newStatus": "COMPLETED",
    "notes": "All 4 stores POD confirmed. Total delivered: 104000",
    "triggeredBy": "tms.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T13:12:37"
    }
    ],
    "timestamp": "2026-03-19T13:12:37"
    }

══════════════════════════════════════
16. Carrier transit event trail
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Transit events retrieved",
    "data": [
    {
    "id": 5,
    "eventCode": "PICKUP",
    "eventDescription": "Load picked up from DC-ATLANTA.",
    "location": "Atlanta, GA",
    "source": "CARRIER_API",
    "eventAt": "2026-03-19T13:12:37",
    "recordedAt": "2026-03-19T13:12:37"
    },
    {
    "id": 6,
    "eventCode": "IN_TRANSIT",
    "eventDescription": "En route to Southeast stores.",
    "location": "Macon, GA",
    "source": "CARRIER_API",
    "eventAt": "2026-03-19T13:12:37",
    "recordedAt": "2026-03-19T13:12:37"
    }
    ],
    "timestamp": "2026-03-19T13:12:37"
    }

══════════════════════════════════════
17. Filter loads by status=COMPLETED
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Loads for status: COMPLETED",
    "data": [
    {
    "externalId": "load-001-uuid",
    "loadNumber": "LOAD-2025-001",
    "shipmentExternalId": "shp-001-uuid",
    "shipmentNumber": "SHP-2025-001",
    "storeOrderExternalId": "ord-001-uuid",
    "storeOrderNumber": "ORD-2025-001",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-MIDWEST",
    "distributionDc": "DC-CHICAGO",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 128000,
    "carrierName": "XPO Logistics",
    "proNumber": "XPO-2025-MW-0441",
    "driverName": "Mike Johnson",
    "truckNumber": "XPO-TRUCK-5521",
    "requiredDeliveryDate": "2025-06-01",
    "pickupDate": "2025-05-20",
    "estimatedDeliveryDate": "2025-05-30",
    "status": "COMPLETED",
    "notes": "All 4 Midwest store deliveries completed. POD confirmed at all locations.",
    "createdBy": "tms.coordinator",
    "createdAt": "2026-03-19T08:11:46",
    "updatedAt": "2026-03-19T08:11:46",
    "storeDeliveries": [
    {
    "externalId": "sd-001-uuid",
    "storeExternalId": "str-001-uuid",
    "storeNumber": "STR-0001",
    "storeName": "Burger Bliss Chicago Downtown",
    "city": "Chicago",
    "stateCode": "IL",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 32000,
    "cartonLabel": "CTN-MW-0001",
    "deliveredQuantity": 32000,
    "podSignatory": "Sarah Chen",
    "podNotes": "All 32,000 units received in good condition. Signed at dock.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-28T05:30:00",
    "podConfirmedAt": "2025-05-28T06:00:00"
    },
    {
    "externalId": "sd-002-uuid",
    "storeExternalId": "str-002-uuid",
    "storeNumber": "STR-0002",
    "storeName": "Burger Bliss Naperville",
    "city": "Naperville",
    "stateCode": "IL",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 32000,
    "cartonLabel": "CTN-MW-0002",
    "deliveredQuantity": 32000,
    "podSignatory": "Tom Richards",
    "podNotes": "Full carton received. Stored in back stockroom.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-28T08:15:00",
    "podConfirmedAt": "2025-05-28T08:45:00"
    },
    {
    "externalId": "sd-003-uuid",
    "storeExternalId": "str-003-uuid",
    "storeNumber": "STR-0003",
    "storeName": "Burger Bliss Milwaukee",
    "city": "Milwaukee",
    "stateCode": "WI",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 32000,
    "cartonLabel": "CTN-MW-0003",
    "deliveredQuantity": 32000,
    "podSignatory": "Jessica Park",
    "podNotes": "Delivered to store manager. No damage reported.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-29T04:00:00",
    "podConfirmedAt": "2025-05-29T04:30:00"
    },
    {
    "externalId": "sd-004-uuid",
    "storeExternalId": "str-004-uuid",
    "storeNumber": "STR-0004",
    "storeName": "Burger Bliss Indianapolis",
    "city": "Indianapolis",
    "stateCode": "IN",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 32000,
    "cartonLabel": "CTN-MW-0004",
    "deliveredQuantity": 32000,
    "podSignatory": "David Torres",
    "podNotes": "Final delivery on this load. All 32,000 units confirmed.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-30T09:00:00",
    "podConfirmedAt": "2025-05-30T09:30:00"
    }
    ]
    },
    {
    "externalId": "18ead21f-f4e2-48a1-8efa-fbad63acfb80",
    "loadNumber": "LOAD-2025-002",
    "shipmentExternalId": "shp-002-ext-uuid",
    "shipmentNumber": "SHP-2025-002",
    "storeOrderExternalId": "ord-003-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 104000,
    "carrierName": "Old Dominion Freight",
    "proNumber": "OD-2025-SE-8812",
    "driverName": "Carlos Mendez",
    "truckNumber": "OD-TRUCK-8812",
    "requiredDeliveryDate": "2025-06-01",
    "pickupDate": "2025-05-28",
    "estimatedDeliveryDate": "2025-06-01",
    "status": "COMPLETED",
    "notes": "Southeast stores \u2014 4 cartons, Old Dominion PRO OD-2025-SE-8812.",
    "createdBy": "tms.coordinator",
    "createdAt": "2026-03-19T13:12:37",
    "updatedAt": "2026-03-19T13:12:37",
    "storeDeliveries": [
    {
    "externalId": "49c3fc19-c97a-4e78-b202-104dfdb7621e",
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "deliveredQuantity": 26000,
    "podSignatory": "Maria Gonzalez",
    "podNotes": "Full carton received at Atlanta. 26,000 dino toys. Signed at receiving dock.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-29T10:00:00",
    "podConfirmedAt": "2026-03-19T13:12:37"
    },
    {
    "externalId": "1be3f572-baa0-4b88-b1bf-68cffaa549f6",
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "deliveredQuantity": 26000,
    "podSignatory": "James Williams",
    "podNotes": "All 26,000 units received in good condition. Stored in back room.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-29T14:30:00",
    "podConfirmedAt": "2026-03-19T13:12:37"
    },
    {
    "externalId": "3056330a-dcd7-4cee-8563-5d220a1cb33f",
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "deliveredQuantity": 26000,
    "podSignatory": "Angela Davis",
    "podNotes": "Delivery accepted. No damage. Carton label CTN-SE-0003 scanned.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-30T09:15:00",
    "podConfirmedAt": "2026-03-19T13:12:37"
    },
    {
    "externalId": "9da9c9c1-0b9c-43e3-a7c0-84eeee8b61bb",
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "sku": "TOY-DINO-MIX-001",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "deliveredQuantity": 26000,
    "podSignatory": "Robert Kim",
    "podNotes": "Final delivery on this load. All 26,000 Nashville units confirmed.",
    "status": "POD_CONFIRMED",
    "deliveredAt": "2025-05-30T15:00:00",
    "podConfirmedAt": "2026-03-19T13:12:37"
    }
    ]
    }
    ],
    "timestamp": "2026-03-19T13:12:37"
    }

══════════════════════════════════════
18. Duplicate load for same shipment (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "Load already exists for shipment: shp-002-ext-uuid",
    "data": null,
    "timestamp": "2026-03-19T13:12:37"
    }

══════════════════════════════════════
19. Assign driver to COMPLETED load (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "Load must be CREATED to be assigned. Current: COMPLETED",
    "data": null,
    "timestamp": "2026-03-19T13:12:37"
    }

══════════════════════════════════════
20. Mark in-transit on CREATED load without assigning driver (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "Load must be ASSIGNED to be in transit. Current: CREATED",
    "data": null,
    "timestamp": "2026-03-19T13:12:37"
    }

══════════════════════════════════════
21. Actuator Health Check
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
    "free": 887853563904,
    "threshold": 10485760,
    "path": "/Users/binit.datta/tms_enterprise_poc/cs-tms-api/.",
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
✔   erp.tms.load.created              — load created from WMS dispatch
✔   erp.tms.load.assigned             — driver + truck assigned
✔   erp.tms.load.in-transit           — truck en route
✔   erp.tms.delivery.out-for-delivery — all stores out for delivery
✔   erp.tms.load.completed            — all stores delivered
✔   erp.tms.delivery.pod-confirmed    — FINAL EVENT: Flask Control Tower consumes this
✔
✔ THE FULL SUPPLY CHAIN IS NOW COMPLETE:
✔   CRM → Vendor → Procurement → WMS Inbound → OMS → WMS Outbound → TMS → POD
✔   Toys are in the restaurants. Campaign SUMMER25-TOY is live!
✔
✔ Check: http://localhost:15672 → Queues → control-tower-test
binit.datta@C6NWKQ290Y cs-tms-api % 