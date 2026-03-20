# cs-wms-inbound-api
**WMS Inbound — ASN, Receiving, Putaway, Inventory**

Spring Boot 3.4.3 | JDK 21 | MySQL 8 | RabbitMQ | JPA | Port 8084

---

## Domain

Manages the physical inbound flow of toys from vendor to warehouse:

```
erp.procurement.po.ready-to-ship
        ↓
  ASN created (CREATED)    ──→  erp.wms.inbound.asn.created
        ↓
  Dock scheduled (SCHEDULED) → erp.wms.inbound.asn.scheduled
        ↓
  IN_TRANSIT
        ↓
  ARRIVED                  ──→  erp.wms.inbound.shipment.arrived
        ↓
  RECEIVED (physical count)──→  erp.wms.inbound.receiving.completed
        ↓
  PUTAWAY_COMPLETED         ──→  erp.wms.inbound.putaway.completed
                                      ↑ KEY EVENT consumed by cs-oms-api
                                        to mark inventory available
                                        for store allocation
```

---

## Setup

### Step 1 — MySQL Workbench
1. `db/01_ddl_cs_wms_inbound.sql` — creates `cs_wms_inbound` DB, `wms_inbound_app` user (no DDL), 5 tables
2. `db/02_seed_cs_wms_inbound.sql` — seeds 2 ASNs, receiving record, putaway tasks, inventory locations

### Step 2 — Run (port 8084)
```bash
mvn clean install -DskipTests
java -jar target/cs-wms-inbound-api-1.0.0-SNAPSHOT.jar
```

### Step 3 — Test
```bash
chmod +x test_cs_wms_inbound_api.sh && ./test_cs_wms_inbound_api.sh
```

---

## REST Endpoints

| Method | Path                                   | Description                              |
|--------|----------------------------------------|------------------------------------------|
| POST   | /api/v1/asns                           | Create ASN                               |
| GET    | /api/v1/asns                           | List all ASNs                            |
| GET    | /api/v1/asns/{id}                      | Get ASN                                  |
| GET    | /api/v1/asns/status/{status}           | Filter by status                         |
| POST   | /api/v1/asns/{id}/schedule             | → SCHEDULED (dock booked)                |
| POST   | /api/v1/asns/{id}/in-transit           | → IN_TRANSIT                             |
| POST   | /api/v1/asns/{id}/arrived              | → ARRIVED                                |
| POST   | /api/v1/asns/{id}/receive              | → RECEIVED (physical count)              |
| GET    | /api/v1/asns/{id}/receiving            | Get receiving record                     |
| POST   | /api/v1/asns/{id}/putaway              | → PUTAWAY_COMPLETED (**OMS trigger**)    |
| GET    | /api/v1/asns/{id}/events               | Full audit trail                         |
| GET    | /api/v1/inventory/sku/{sku}            | Inventory by SKU (all bins)              |
| GET    | /api/v1/inventory/campaign/{code}      | Inventory by campaign                    |
| GET    | /api/v1/inventory/sku/{sku}/available  | Total available quantity                 |
| GET    | /api/v1/inventory/campaign/{code}/on-hand | Total on-hand quantity                |
| GET    | /actuator/health                       | Health check                             |

---

## RabbitMQ Events

| Event                   | Routing Key                                 |
|-------------------------|---------------------------------------------|
| ASN created             | `erp.wms.inbound.asn.created`               |
| Dock scheduled          | `erp.wms.inbound.asn.scheduled`             |
| Shipment arrived        | `erp.wms.inbound.shipment.arrived`          |
| Receiving completed     | `erp.wms.inbound.receiving.completed`       |
| **Putaway completed**   | **`erp.wms.inbound.putaway.completed`**     |

Exchange: `erp.topic.exchange` (shared across all ERP services)

---

## Seeded Data

| ASN Number   | PO           | Vendor              | SKU                  | Qty       | Status             |
|--------------|--------------|---------------------|----------------------|-----------|--------------------|
| ASN-2025-001 | PO-2025-001  | Ho Chi Minh Playthings | TOY-DINO-MIX-001  | 500,000   | PUTAWAY_COMPLETED  |
| ASN-2025-002 | PO-2025-002  | Shenzhen BrightToy  | TOY-HOLIDAY-MIX-001  | 1,200,000 | SCHEDULED          |

Seeded inventory (from ASN-2025-001):
- `BIN-A-01-001`: 250,000 units available
- `BIN-A-02-001`: 249,800 units available
- Total available: 499,800 units of `TOY-DINO-MIX-001`


binit.datta@C6NWKQ290Y cs-wms-inbound-api % chmod +x test_cs_wms_inbound_api.sh && ./test_cs_wms_inbound_api.sh


══════════════════════════════════════
1. List all seeded ASNs
   ══════════════════════════════════════
   {
   "success": true,
   "message": "ASNs retrieved",
   "data": [
   {
   "externalId": "asn-001-uuid",
   "asnNumber": "ASN-2025-001",
   "poExternalId": "po-001-uuid",
   "poNumber": "PO-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-002-uuid",
   "vendorCode": "VND-VN-001",
   "vendorName": "Ho Chi Minh Playthings Ltd.",
   "vendorCountry": "VIETNAM",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "expectedQuantity": 500000,
   "unitOfMeasure": "PIECES",
   "carrierName": "OOCL Shipping",
   "trackingNumber": "OOCL-VIET-20250401-8821",
   "originPort": "Port of Ho Chi Minh City",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": "2025-05-05",
   "dockAppointmentDate": "2025-05-06T03:00:00",
   "dockDoor": "DOOR-05",
   "status": "PUTAWAY_COMPLETED",
   "notes": "Vessel OOCL EUROPE arrived on schedule. 500k cartons offloaded. Awaiting dock receiving.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T09:04:15",
   "updatedAt": "2026-03-18T09:04:15"
   },
   {
   "externalId": "asn-002-uuid",
   "asnNumber": "ASN-2025-002",
   "poExternalId": "po-002-uuid",
   "poNumber": "PO-2025-002",
   "campaignExternalId": "camp-002-uuid",
   "campaignCode": "HOLIDAY25-TOY",
   "vendorExternalId": "vnd-001-uuid",
   "vendorCode": "VND-CN-001",
   "vendorName": "Shenzhen BrightToy Manufacturing Co.",
   "vendorCountry": "CHINA",
   "sku": "TOY-HOLIDAY-MIX-001",
   "toyDescription": "Holiday 2025 Collectible Figurines \u2014 6 Character Series",
   "expectedQuantity": 1200000,
   "unitOfMeasure": "PIECES",
   "carrierName": "COSCO Shipping",
   "trackingNumber": "COSCO-CN-20250915-4492",
   "originPort": "Port of Shenzhen",
   "destinationPort": "Port of Long Beach",
   "incoterms": "CIF",
   "estimatedArrivalDate": "2025-10-05",
   "actualArrivalDate": null,
   "dockAppointmentDate": "2025-10-06T02:00:00",
   "dockDoor": "DOOR-03",
   "status": "SCHEDULED",
   "notes": "Vessel departs Shenzhen Sept 15. ETA Long Beach Oct 5. Dock slot confirmed.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T09:04:15",
   "updatedAt": "2026-03-18T09:04:15"
   }
   ],
   "timestamp": "2026-03-18T14:04:50"
   }

══════════════════════════════════════
2. Get ASN-2025-001 (PUTAWAY_COMPLETED)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "ASN retrieved",
   "data": {
   "externalId": "asn-001-uuid",
   "asnNumber": "ASN-2025-001",
   "poExternalId": "po-001-uuid",
   "poNumber": "PO-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-002-uuid",
   "vendorCode": "VND-VN-001",
   "vendorName": "Ho Chi Minh Playthings Ltd.",
   "vendorCountry": "VIETNAM",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "expectedQuantity": 500000,
   "unitOfMeasure": "PIECES",
   "carrierName": "OOCL Shipping",
   "trackingNumber": "OOCL-VIET-20250401-8821",
   "originPort": "Port of Ho Chi Minh City",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": "2025-05-05",
   "dockAppointmentDate": "2025-05-06T03:00:00",
   "dockDoor": "DOOR-05",
   "status": "PUTAWAY_COMPLETED",
   "notes": "Vessel OOCL EUROPE arrived on schedule. 500k cartons offloaded. Awaiting dock receiving.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T09:04:15",
   "updatedAt": "2026-03-18T09:04:15"
   },
   "timestamp": "2026-03-18T14:04:50"
   }

══════════════════════════════════════
3. Receiving record for ASN-2025-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Receiving record retrieved",
   "data": {
   "externalId": "rr-001-uuid",
   "asnNumber": "ASN-2025-001",
   "receivedQuantity": 499800,
   "damagedQuantity": 200,
   "rejectedQuantity": 0,
   "acceptedQuantity": 499800,
   "varianceQuantity": -200,
   "receivedBy": "warehouse.receiver.01",
   "qcPassed": true,
   "qcNotes": "Minor damage on 200 units from moisture. All rejected units documented. 499,800 accepted. QC PASSED.",
   "receivedAt": "2025-05-06T05:30:00"
   },
   "timestamp": "2026-03-18T14:04:50"
   }

══════════════════════════════════════
4. Inventory by SKU (TOY-DINO-MIX-001)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Inventory retrieved for SKU: TOY-DINO-MIX-001",
   "data": [
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityOnHand": 250000,
   "quantityReserved": 0,
   "quantityAvailable": 250000,
   "lastReceiptDate": "2025-05-06",
   "lastUpdatedAt": "2026-03-18T09:04:15"
   },
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityOnHand": 249800,
   "quantityReserved": 0,
   "quantityAvailable": 249800,
   "lastReceiptDate": "2025-05-06",
   "lastUpdatedAt": "2026-03-18T09:04:15"
   }
   ],
   "timestamp": "2026-03-18T14:04:50"
   }

══════════════════════════════════════
5. Inventory by campaign (SUMMER25-TOY)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Inventory retrieved for campaign: SUMMER25-TOY",
   "data": [
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityOnHand": 250000,
   "quantityReserved": 0,
   "quantityAvailable": 250000,
   "lastReceiptDate": "2025-05-06",
   "lastUpdatedAt": "2026-03-18T09:04:15"
   },
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityOnHand": 249800,
   "quantityReserved": 0,
   "quantityAvailable": 249800,
   "lastReceiptDate": "2025-05-06",
   "lastUpdatedAt": "2026-03-18T09:04:15"
   }
   ],
   "timestamp": "2026-03-18T14:04:50"
   }

══════════════════════════════════════
6. Total available quantity for TOY-DINO-MIX-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Available quantity for SKU: TOY-DINO-MIX-001",
   "data": {
   "sku": "TOY-DINO-MIX-001",
   "totalAvailable": 499800
   },
   "timestamp": "2026-03-18T14:04:50"
   }

══════════════════════════════════════
7. Create new ASN for PO-2025-003 → publishes erp.wms.inbound.asn.created
   ══════════════════════════════════════
   {
   "success": true,
   "message": "ASN created successfully",
   "data": {
   "externalId": "e417ca0e-8237-4fa6-99a5-78183f02f1ea",
   "asnNumber": "ASN-2025-003",
   "poExternalId": "po-003-test-uuid",
   "poNumber": "PO-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "sku": "TOY-SPACE-MIX-001",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
   "expectedQuantity": 250000,
   "unitOfMeasure": "PIECES",
   "carrierName": "MSC Shipping",
   "trackingNumber": "MSC-THAI-20250420-7743",
   "originPort": "Laem Chabang Port, Thailand",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": null,
   "dockAppointmentDate": "2025-05-06T08:00:00",
   "dockDoor": "DOOR-07",
   "status": "CREATED",
   "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T14:04:50",
   "updatedAt": "2026-03-18T14:04:50"
   },
   "timestamp": "2026-03-18T14:04:50"
   }
   ✔ New ASN externalId: e417ca0e-8237-4fa6-99a5-78183f02f1ea

══════════════════════════════════════
8. Schedule dock appointment → publishes erp.wms.inbound.asn.scheduled
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Dock appointment scheduled",
   "data": {
   "externalId": "e417ca0e-8237-4fa6-99a5-78183f02f1ea",
   "asnNumber": "ASN-2025-003",
   "poExternalId": "po-003-test-uuid",
   "poNumber": "PO-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "sku": "TOY-SPACE-MIX-001",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
   "expectedQuantity": 250000,
   "unitOfMeasure": "PIECES",
   "carrierName": "MSC Shipping",
   "trackingNumber": "MSC-THAI-20250420-7743",
   "originPort": "Laem Chabang Port, Thailand",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": null,
   "dockAppointmentDate": "2025-05-06T08:00:00",
   "dockDoor": "DOOR-07",
   "status": "SCHEDULED",
   "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T14:04:50",
   "updatedAt": "2026-03-18T14:04:50"
   },
   "timestamp": "2026-03-18T14:04:50"
   }

══════════════════════════════════════
9. Mark in transit
   ══════════════════════════════════════
   {
   "success": true,
   "message": "ASN marked in transit",
   "data": {
   "externalId": "e417ca0e-8237-4fa6-99a5-78183f02f1ea",
   "asnNumber": "ASN-2025-003",
   "poExternalId": "po-003-test-uuid",
   "poNumber": "PO-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "sku": "TOY-SPACE-MIX-001",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
   "expectedQuantity": 250000,
   "unitOfMeasure": "PIECES",
   "carrierName": "MSC Shipping",
   "trackingNumber": "MSC-THAI-20250420-7743",
   "originPort": "Laem Chabang Port, Thailand",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": null,
   "dockAppointmentDate": "2025-05-06T08:00:00",
   "dockDoor": "DOOR-07",
   "status": "IN_TRANSIT",
   "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T14:04:50",
   "updatedAt": "2026-03-18T14:04:50"
   },
   "timestamp": "2026-03-18T14:04:50"
   }

══════════════════════════════════════
10. Mark arrived → publishes erp.wms.inbound.shipment.arrived
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment marked arrived",
    "data": {
    "externalId": "e417ca0e-8237-4fa6-99a5-78183f02f1ea",
    "asnNumber": "ASN-2025-003",
    "poExternalId": "po-003-test-uuid",
    "poNumber": "PO-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "vendorExternalId": "vnd-004-uuid",
    "vendorCode": "VND-TH-001",
    "vendorName": "Bangkok Fun Factory Co. Ltd.",
    "vendorCountry": "THAILAND",
    "sku": "TOY-SPACE-MIX-001",
    "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
    "expectedQuantity": 250000,
    "unitOfMeasure": "PIECES",
    "carrierName": "MSC Shipping",
    "trackingNumber": "MSC-THAI-20250420-7743",
    "originPort": "Laem Chabang Port, Thailand",
    "destinationPort": "Port of Los Angeles",
    "incoterms": "FOB",
    "estimatedArrivalDate": "2025-05-05",
    "actualArrivalDate": "2025-05-05",
    "dockAppointmentDate": "2025-05-06T08:00:00",
    "dockDoor": "DOOR-07",
    "status": "ARRIVED",
    "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
    "createdBy": "wms.inbound.coordinator",
    "createdAt": "2026-03-18T14:04:50",
    "updatedAt": "2026-03-18T14:04:50"
    },
    "timestamp": "2026-03-18T14:04:50"
    }

══════════════════════════════════════
11. Receive shipment → publishes erp.wms.inbound.receiving.completed
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment received successfully",
    "data": {
    "externalId": "f6a4b8b5-fd99-4fce-95ef-f818d77f8de1",
    "asnNumber": "ASN-2025-003",
    "receivedQuantity": 249950,
    "damagedQuantity": 50,
    "rejectedQuantity": 0,
    "acceptedQuantity": 249900,
    "varianceQuantity": -50,
    "receivedBy": "warehouse.receiver.02",
    "qcPassed": true,
    "qcNotes": "50 units with minor paint defects isolated. 249,950 units accepted. All safety certifications verified. QC PASSED.",
    "receivedAt": "2026-03-18T14:04:50"
    },
    "timestamp": "2026-03-18T14:04:50"
    }

══════════════════════════════════════
12. Complete putaway (2 bins) → publishes erp.wms.inbound.putaway.completed (OMS trigger)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "Unexpected error: Cannot invoke \"java.lang.Integer.intValue()\" because the return value of \"com.enterprise.cswmsinbound.entity.InventoryLocation.getQuantityOnHand()\" is null",
    "data": null,
    "timestamp": "2026-03-18T14:04:50"
    }
    ✔ KEY EVENT: erp.wms.inbound.putaway.completed — OMS will mark this inventory available

══════════════════════════════════════
13. Inventory for SPACE SKU after putaway
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Inventory retrieved for SKU: TOY-SPACE-MIX-001",
    "data": [],
    "timestamp": "2026-03-18T14:04:50"
    }
    {
    "success": true,
    "message": "Available quantity for SKU: TOY-SPACE-MIX-001",
    "data": {
    "sku": "TOY-SPACE-MIX-001",
    "totalAvailable": 0
    },
    "timestamp": "2026-03-18T14:04:50"
    }

══════════════════════════════════════
14. Full ASN audit trail
    ══════════════════════════════════════
    {
    "success": true,
    "message": "ASN events retrieved",
    "data": [
    {
    "id": 8,
    "eventType": "ASN_CREATED",
    "previousStatus": null,
    "newStatus": "CREATED",
    "notes": "ASN created",
    "triggeredBy": "wms.inbound.coordinator",
    "rabbitmqPublished": false,
    "eventAt": "2026-03-18T14:04:50"
    },
    {
    "id": 9,
    "eventType": "DOCK_SCHEDULED",
    "previousStatus": "CREATED",
    "newStatus": "SCHEDULED",
    "notes": "Dock DOOR-07 booked for 2025-05-06T08:00",
    "triggeredBy": "wms.inbound.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T14:04:50"
    },
    {
    "id": 10,
    "eventType": "IN_TRANSIT",
    "previousStatus": "SCHEDULED",
    "newStatus": "IN_TRANSIT",
    "notes": "Vessel MSC AURORA departed Laem Chabang. ETA 15 days.",
    "triggeredBy": "msc.tracking.api",
    "rabbitmqPublished": false,
    "eventAt": "2026-03-18T14:04:50"
    },
    {
    "id": 11,
    "eventType": "SHIPMENT_ARRIVED",
    "previousStatus": "IN_TRANSIT",
    "newStatus": "ARRIVED",
    "notes": "MSC AURORA docked at Port of Los Angeles, Berth 302.",
    "triggeredBy": "wms.inbound.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T14:04:50"
    },
    {
    "id": 12,
    "eventType": "RECEIVING_COMPLETED",
    "previousStatus": "ARRIVED",
    "newStatus": "RECEIVED",
    "notes": "Accepted=249900 Damaged=50 Variance=-50",
    "triggeredBy": "warehouse.receiver.02",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T14:04:50"
    }
    ],
    "timestamp": "2026-03-18T14:04:50"
    }

══════════════════════════════════════
15. Filter ASNs by status=PUTAWAY_COMPLETED
    ══════════════════════════════════════
    {
    "success": true,
    "message": "ASNs retrieved for status: PUTAWAY_COMPLETED",
    "data": [
    {
    "externalId": "asn-001-uuid",
    "asnNumber": "ASN-2025-001",
    "poExternalId": "po-001-uuid",
    "poNumber": "PO-2025-001",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "vendorExternalId": "vnd-002-uuid",
    "vendorCode": "VND-VN-001",
    "vendorName": "Ho Chi Minh Playthings Ltd.",
    "vendorCountry": "VIETNAM",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "expectedQuantity": 500000,
    "unitOfMeasure": "PIECES",
    "carrierName": "OOCL Shipping",
    "trackingNumber": "OOCL-VIET-20250401-8821",
    "originPort": "Port of Ho Chi Minh City",
    "destinationPort": "Port of Los Angeles",
    "incoterms": "FOB",
    "estimatedArrivalDate": "2025-05-05",
    "actualArrivalDate": "2025-05-05",
    "dockAppointmentDate": "2025-05-06T03:00:00",
    "dockDoor": "DOOR-05",
    "status": "PUTAWAY_COMPLETED",
    "notes": "Vessel OOCL EUROPE arrived on schedule. 500k cartons offloaded. Awaiting dock receiving.",
    "createdBy": "wms.inbound.coordinator",
    "createdAt": "2026-03-18T09:04:15",
    "updatedAt": "2026-03-18T09:04:15"
    }
    ],
    "timestamp": "2026-03-18T14:04:50"
    }

══════════════════════════════════════
16. Duplicate ASN for same PO (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "ASN already exists for PO: po-003-test-uuid",
    "data": null,
    "timestamp": "2026-03-18T14:04:50"
    }

══════════════════════════════════════
17. Attempt to receive SCHEDULED ASN-2025-002 (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "ASN must be ARRIVED to receive. Current: SCHEDULED",
    "data": null,
    "timestamp": "2026-03-18T14:04:50"
    }

══════════════════════════════════════
18. Mark seeded ASN-2025-002 (SCHEDULED) → IN_TRANSIT
    ══════════════════════════════════════
    {
    "success": true,
    "message": "ASN marked in transit",
    "data": {
    "externalId": "asn-002-uuid",
    "asnNumber": "ASN-2025-002",
    "poExternalId": "po-002-uuid",
    "poNumber": "PO-2025-002",
    "campaignExternalId": "camp-002-uuid",
    "campaignCode": "HOLIDAY25-TOY",
    "vendorExternalId": "vnd-001-uuid",
    "vendorCode": "VND-CN-001",
    "vendorName": "Shenzhen BrightToy Manufacturing Co.",
    "vendorCountry": "CHINA",
    "sku": "TOY-HOLIDAY-MIX-001",
    "toyDescription": "Holiday 2025 Collectible Figurines \u2014 6 Character Series",
    "expectedQuantity": 1200000,
    "unitOfMeasure": "PIECES",
    "carrierName": "COSCO Shipping",
    "trackingNumber": "COSCO-CN-20250915-4492",
    "originPort": "Port of Shenzhen",
    "destinationPort": "Port of Long Beach",
    "incoterms": "CIF",
    "estimatedArrivalDate": "2025-10-05",
    "actualArrivalDate": null,
    "dockAppointmentDate": "2025-10-06T02:00:00",
    "dockDoor": "DOOR-03",
    "status": "IN_TRANSIT",
    "notes": "Vessel departs Shenzhen Sept 15. ETA Long Beach Oct 5. Dock slot confirmed.",
    "createdBy": "wms.inbound.coordinator",
    "createdAt": "2026-03-18T09:04:15",
    "updatedAt": "2026-03-18T09:04:15"
    },
    "timestamp": "2026-03-18T14:04:50"
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
    "free": 894366232576,
    "threshold": 10485760,
    "path": "/Users/binit.datta/tms_enterprise_poc/cs-wms-inbound-api/.",
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
✔   erp.wms.inbound.asn.created          — ASN created from PO
✔   erp.wms.inbound.asn.scheduled        — dock appointment confirmed
✔   erp.wms.inbound.shipment.arrived     — vessel docked
✔   erp.wms.inbound.receiving.completed  — physical count done
✔   erp.wms.inbound.putaway.completed    — KEY: OMS marks inventory available
✔ Check: http://localhost:15672 → Queues → control-tower-test
binit.datta@C6NWKQ290Y cs-wms-inbound-api % 

binit.datta@C6NWKQ290Y cs-wms-inbound-api % ./test_cs_wms_inbound_api.sh

══════════════════════════════════════
1. List all seeded ASNs
   ══════════════════════════════════════
   {
   "success": true,
   "message": "ASNs retrieved",
   "data": [
   {
   "externalId": "asn-001-uuid",
   "asnNumber": "ASN-2025-001",
   "poExternalId": "po-001-uuid",
   "poNumber": "PO-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-002-uuid",
   "vendorCode": "VND-VN-001",
   "vendorName": "Ho Chi Minh Playthings Ltd.",
   "vendorCountry": "VIETNAM",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "expectedQuantity": 500000,
   "unitOfMeasure": "PIECES",
   "carrierName": "OOCL Shipping",
   "trackingNumber": "OOCL-VIET-20250401-8821",
   "originPort": "Port of Ho Chi Minh City",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": "2025-05-05",
   "dockAppointmentDate": "2025-05-06T03:00:00",
   "dockDoor": "DOOR-05",
   "status": "PUTAWAY_COMPLETED",
   "notes": "Vessel OOCL EUROPE arrived on schedule. 500k cartons offloaded. Awaiting dock receiving.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T09:04:15",
   "updatedAt": "2026-03-18T09:04:15"
   },
   {
   "externalId": "asn-002-uuid",
   "asnNumber": "ASN-2025-002",
   "poExternalId": "po-002-uuid",
   "poNumber": "PO-2025-002",
   "campaignExternalId": "camp-002-uuid",
   "campaignCode": "HOLIDAY25-TOY",
   "vendorExternalId": "vnd-001-uuid",
   "vendorCode": "VND-CN-001",
   "vendorName": "Shenzhen BrightToy Manufacturing Co.",
   "vendorCountry": "CHINA",
   "sku": "TOY-HOLIDAY-MIX-001",
   "toyDescription": "Holiday 2025 Collectible Figurines \u2014 6 Character Series",
   "expectedQuantity": 1200000,
   "unitOfMeasure": "PIECES",
   "carrierName": "COSCO Shipping",
   "trackingNumber": "COSCO-CN-20250915-4492",
   "originPort": "Port of Shenzhen",
   "destinationPort": "Port of Long Beach",
   "incoterms": "CIF",
   "estimatedArrivalDate": "2025-10-05",
   "actualArrivalDate": null,
   "dockAppointmentDate": "2025-10-06T02:00:00",
   "dockDoor": "DOOR-03",
   "status": "SCHEDULED",
   "notes": "Vessel departs Shenzhen Sept 15. ETA Long Beach Oct 5. Dock slot confirmed.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T09:04:15",
   "updatedAt": "2026-03-18T09:06:38"
   }
   ],
   "timestamp": "2026-03-18T14:07:13"
   }

══════════════════════════════════════
2. Get ASN-2025-001 (PUTAWAY_COMPLETED)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "ASN retrieved",
   "data": {
   "externalId": "asn-001-uuid",
   "asnNumber": "ASN-2025-001",
   "poExternalId": "po-001-uuid",
   "poNumber": "PO-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-002-uuid",
   "vendorCode": "VND-VN-001",
   "vendorName": "Ho Chi Minh Playthings Ltd.",
   "vendorCountry": "VIETNAM",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "expectedQuantity": 500000,
   "unitOfMeasure": "PIECES",
   "carrierName": "OOCL Shipping",
   "trackingNumber": "OOCL-VIET-20250401-8821",
   "originPort": "Port of Ho Chi Minh City",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": "2025-05-05",
   "dockAppointmentDate": "2025-05-06T03:00:00",
   "dockDoor": "DOOR-05",
   "status": "PUTAWAY_COMPLETED",
   "notes": "Vessel OOCL EUROPE arrived on schedule. 500k cartons offloaded. Awaiting dock receiving.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T09:04:15",
   "updatedAt": "2026-03-18T09:04:15"
   },
   "timestamp": "2026-03-18T14:07:13"
   }

══════════════════════════════════════
3. Receiving record for ASN-2025-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Receiving record retrieved",
   "data": {
   "externalId": "rr-001-uuid",
   "asnNumber": "ASN-2025-001",
   "receivedQuantity": 499800,
   "damagedQuantity": 200,
   "rejectedQuantity": 0,
   "acceptedQuantity": 499800,
   "varianceQuantity": -200,
   "receivedBy": "warehouse.receiver.01",
   "qcPassed": true,
   "qcNotes": "Minor damage on 200 units from moisture. All rejected units documented. 499,800 accepted. QC PASSED.",
   "receivedAt": "2025-05-06T05:30:00"
   },
   "timestamp": "2026-03-18T14:07:13"
   }

══════════════════════════════════════
4. Inventory by SKU (TOY-DINO-MIX-001)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Inventory retrieved for SKU: TOY-DINO-MIX-001",
   "data": [
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityOnHand": 250000,
   "quantityReserved": 0,
   "quantityAvailable": 250000,
   "lastReceiptDate": "2025-05-06",
   "lastUpdatedAt": "2026-03-18T09:04:15"
   },
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityOnHand": 249800,
   "quantityReserved": 0,
   "quantityAvailable": 249800,
   "lastReceiptDate": "2025-05-06",
   "lastUpdatedAt": "2026-03-18T09:04:15"
   }
   ],
   "timestamp": "2026-03-18T14:07:13"
   }

══════════════════════════════════════
5. Inventory by campaign (SUMMER25-TOY)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Inventory retrieved for campaign: SUMMER25-TOY",
   "data": [
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityOnHand": 250000,
   "quantityReserved": 0,
   "quantityAvailable": 250000,
   "lastReceiptDate": "2025-05-06",
   "lastUpdatedAt": "2026-03-18T09:04:15"
   },
   {
   "sku": "TOY-DINO-MIX-001",
   "campaignCode": "SUMMER25-TOY",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityOnHand": 249800,
   "quantityReserved": 0,
   "quantityAvailable": 249800,
   "lastReceiptDate": "2025-05-06",
   "lastUpdatedAt": "2026-03-18T09:04:15"
   }
   ],
   "timestamp": "2026-03-18T14:07:13"
   }

══════════════════════════════════════
6. Total available quantity for TOY-DINO-MIX-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Available quantity for SKU: TOY-DINO-MIX-001",
   "data": {
   "sku": "TOY-DINO-MIX-001",
   "totalAvailable": 499800
   },
   "timestamp": "2026-03-18T14:07:13"
   }

══════════════════════════════════════
7. Create new ASN for PO-2025-003 → publishes erp.wms.inbound.asn.created
   ══════════════════════════════════════
   {
   "success": true,
   "message": "ASN created successfully",
   "data": {
   "externalId": "57b0fbbb-ae84-41d1-bb35-4b4fb0228360",
   "asnNumber": "ASN-2025-003",
   "poExternalId": "po-003-test-uuid",
   "poNumber": "PO-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "sku": "TOY-SPACE-MIX-001",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
   "expectedQuantity": 250000,
   "unitOfMeasure": "PIECES",
   "carrierName": "MSC Shipping",
   "trackingNumber": "MSC-THAI-20250420-7743",
   "originPort": "Laem Chabang Port, Thailand",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": null,
   "dockAppointmentDate": "2025-05-06T08:00:00",
   "dockDoor": "DOOR-07",
   "status": "CREATED",
   "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T14:07:14",
   "updatedAt": "2026-03-18T14:07:14"
   },
   "timestamp": "2026-03-18T14:07:14"
   }
   ✔ New ASN externalId: 57b0fbbb-ae84-41d1-bb35-4b4fb0228360

══════════════════════════════════════
8. Schedule dock appointment → publishes erp.wms.inbound.asn.scheduled
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Dock appointment scheduled",
   "data": {
   "externalId": "57b0fbbb-ae84-41d1-bb35-4b4fb0228360",
   "asnNumber": "ASN-2025-003",
   "poExternalId": "po-003-test-uuid",
   "poNumber": "PO-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "sku": "TOY-SPACE-MIX-001",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
   "expectedQuantity": 250000,
   "unitOfMeasure": "PIECES",
   "carrierName": "MSC Shipping",
   "trackingNumber": "MSC-THAI-20250420-7743",
   "originPort": "Laem Chabang Port, Thailand",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": null,
   "dockAppointmentDate": "2025-05-06T08:00:00",
   "dockDoor": "DOOR-07",
   "status": "SCHEDULED",
   "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T14:07:14",
   "updatedAt": "2026-03-18T14:07:14"
   },
   "timestamp": "2026-03-18T14:07:14"
   }

══════════════════════════════════════
9. Mark in transit
   ══════════════════════════════════════
   {
   "success": true,
   "message": "ASN marked in transit",
   "data": {
   "externalId": "57b0fbbb-ae84-41d1-bb35-4b4fb0228360",
   "asnNumber": "ASN-2025-003",
   "poExternalId": "po-003-test-uuid",
   "poNumber": "PO-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "vendorExternalId": "vnd-004-uuid",
   "vendorCode": "VND-TH-001",
   "vendorName": "Bangkok Fun Factory Co. Ltd.",
   "vendorCountry": "THAILAND",
   "sku": "TOY-SPACE-MIX-001",
   "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
   "expectedQuantity": 250000,
   "unitOfMeasure": "PIECES",
   "carrierName": "MSC Shipping",
   "trackingNumber": "MSC-THAI-20250420-7743",
   "originPort": "Laem Chabang Port, Thailand",
   "destinationPort": "Port of Los Angeles",
   "incoterms": "FOB",
   "estimatedArrivalDate": "2025-05-05",
   "actualArrivalDate": null,
   "dockAppointmentDate": "2025-05-06T08:00:00",
   "dockDoor": "DOOR-07",
   "status": "IN_TRANSIT",
   "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
   "createdBy": "wms.inbound.coordinator",
   "createdAt": "2026-03-18T14:07:14",
   "updatedAt": "2026-03-18T14:07:14"
   },
   "timestamp": "2026-03-18T14:07:14"
   }

══════════════════════════════════════
10. Mark arrived → publishes erp.wms.inbound.shipment.arrived
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment marked arrived",
    "data": {
    "externalId": "57b0fbbb-ae84-41d1-bb35-4b4fb0228360",
    "asnNumber": "ASN-2025-003",
    "poExternalId": "po-003-test-uuid",
    "poNumber": "PO-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "vendorExternalId": "vnd-004-uuid",
    "vendorCode": "VND-TH-001",
    "vendorName": "Bangkok Fun Factory Co. Ltd.",
    "vendorCountry": "THAILAND",
    "sku": "TOY-SPACE-MIX-001",
    "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
    "expectedQuantity": 250000,
    "unitOfMeasure": "PIECES",
    "carrierName": "MSC Shipping",
    "trackingNumber": "MSC-THAI-20250420-7743",
    "originPort": "Laem Chabang Port, Thailand",
    "destinationPort": "Port of Los Angeles",
    "incoterms": "FOB",
    "estimatedArrivalDate": "2025-05-05",
    "actualArrivalDate": "2025-05-05",
    "dockAppointmentDate": "2025-05-06T08:00:00",
    "dockDoor": "DOOR-07",
    "status": "ARRIVED",
    "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
    "createdBy": "wms.inbound.coordinator",
    "createdAt": "2026-03-18T14:07:14",
    "updatedAt": "2026-03-18T14:07:14"
    },
    "timestamp": "2026-03-18T14:07:14"
    }

══════════════════════════════════════
11. Receive shipment → publishes erp.wms.inbound.receiving.completed
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment received successfully",
    "data": {
    "externalId": "10b73980-84c9-48de-be33-224a7629a208",
    "asnNumber": "ASN-2025-003",
    "receivedQuantity": 249950,
    "damagedQuantity": 50,
    "rejectedQuantity": 0,
    "acceptedQuantity": 249900,
    "varianceQuantity": -50,
    "receivedBy": "warehouse.receiver.02",
    "qcPassed": true,
    "qcNotes": "50 units with minor paint defects isolated. 249,950 units accepted. All safety certifications verified. QC PASSED.",
    "receivedAt": "2026-03-18T14:07:14"
    },
    "timestamp": "2026-03-18T14:07:14"
    }

══════════════════════════════════════
12. Complete putaway (2 bins) → publishes erp.wms.inbound.putaway.completed (OMS trigger)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Putaway completed successfully",
    "data": {
    "asnNumber": "ASN-2025-003",
    "campaignCode": "SUMMER25-TOY",
    "sku": "TOY-SPACE-MIX-001",
    "totalQuantityPutaway": 249950,
    "bins": [
    {
    "warehouseZone": "ZONE-B",
    "warehouseAisle": "B-01",
    "warehouseBin": "BIN-B-01-001",
    "quantity": 125000
    },
    {
    "warehouseZone": "ZONE-B",
    "warehouseAisle": "B-02",
    "warehouseBin": "BIN-B-02-001",
    "quantity": 124950
    }
    ],
    "completedAt": "2026-03-18T14:07:14"
    },
    "timestamp": "2026-03-18T14:07:14"
    }
    ✔ KEY EVENT: erp.wms.inbound.putaway.completed — OMS will mark this inventory available

══════════════════════════════════════
13. Inventory for SPACE SKU after putaway
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Inventory retrieved for SKU: TOY-SPACE-MIX-001",
    "data": [
    {
    "sku": "TOY-SPACE-MIX-001",
    "campaignCode": "SUMMER25-TOY",
    "warehouseZone": "ZONE-B",
    "warehouseAisle": "B-01",
    "warehouseBin": "BIN-B-01-001",
    "quantityOnHand": 125000,
    "quantityReserved": 0,
    "quantityAvailable": 125000,
    "lastReceiptDate": "2026-03-18",
    "lastUpdatedAt": "2026-03-18T14:07:14"
    },
    {
    "sku": "TOY-SPACE-MIX-001",
    "campaignCode": "SUMMER25-TOY",
    "warehouseZone": "ZONE-B",
    "warehouseAisle": "B-02",
    "warehouseBin": "BIN-B-02-001",
    "quantityOnHand": 124950,
    "quantityReserved": 0,
    "quantityAvailable": 124950,
    "lastReceiptDate": "2026-03-18",
    "lastUpdatedAt": "2026-03-18T14:07:14"
    }
    ],
    "timestamp": "2026-03-18T14:07:14"
    }
    {
    "success": true,
    "message": "Available quantity for SKU: TOY-SPACE-MIX-001",
    "data": {
    "sku": "TOY-SPACE-MIX-001",
    "totalAvailable": 249950
    },
    "timestamp": "2026-03-18T14:07:14"
    }

══════════════════════════════════════
14. Full ASN audit trail
    ══════════════════════════════════════
    {
    "success": true,
    "message": "ASN events retrieved",
    "data": [
    {
    "id": 14,
    "eventType": "ASN_CREATED",
    "previousStatus": null,
    "newStatus": "CREATED",
    "notes": "ASN created",
    "triggeredBy": "wms.inbound.coordinator",
    "rabbitmqPublished": false,
    "eventAt": "2026-03-18T14:07:14"
    },
    {
    "id": 15,
    "eventType": "DOCK_SCHEDULED",
    "previousStatus": "CREATED",
    "newStatus": "SCHEDULED",
    "notes": "Dock DOOR-07 booked for 2025-05-06T08:00",
    "triggeredBy": "wms.inbound.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T14:07:14"
    },
    {
    "id": 16,
    "eventType": "IN_TRANSIT",
    "previousStatus": "SCHEDULED",
    "newStatus": "IN_TRANSIT",
    "notes": "Vessel MSC AURORA departed Laem Chabang. ETA 15 days.",
    "triggeredBy": "msc.tracking.api",
    "rabbitmqPublished": false,
    "eventAt": "2026-03-18T14:07:14"
    },
    {
    "id": 17,
    "eventType": "SHIPMENT_ARRIVED",
    "previousStatus": "IN_TRANSIT",
    "newStatus": "ARRIVED",
    "notes": "MSC AURORA docked at Port of Los Angeles, Berth 302.",
    "triggeredBy": "wms.inbound.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T14:07:14"
    },
    {
    "id": 18,
    "eventType": "RECEIVING_COMPLETED",
    "previousStatus": "ARRIVED",
    "newStatus": "RECEIVED",
    "notes": "Accepted=249900 Damaged=50 Variance=-50",
    "triggeredBy": "warehouse.receiver.02",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T14:07:14"
    },
    {
    "id": 19,
    "eventType": "PUTAWAY_COMPLETED",
    "previousStatus": "RECEIVED",
    "newStatus": "PUTAWAY_COMPLETED",
    "notes": "Total putaway=249950 across 2 bins",
    "triggeredBy": "forklift.op.03",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-18T14:07:14"
    }
    ],
    "timestamp": "2026-03-18T14:07:14"
    }

══════════════════════════════════════
15. Filter ASNs by status=PUTAWAY_COMPLETED
    ══════════════════════════════════════
    {
    "success": true,
    "message": "ASNs retrieved for status: PUTAWAY_COMPLETED",
    "data": [
    {
    "externalId": "asn-001-uuid",
    "asnNumber": "ASN-2025-001",
    "poExternalId": "po-001-uuid",
    "poNumber": "PO-2025-001",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "vendorExternalId": "vnd-002-uuid",
    "vendorCode": "VND-VN-001",
    "vendorName": "Ho Chi Minh Playthings Ltd.",
    "vendorCountry": "VIETNAM",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "expectedQuantity": 500000,
    "unitOfMeasure": "PIECES",
    "carrierName": "OOCL Shipping",
    "trackingNumber": "OOCL-VIET-20250401-8821",
    "originPort": "Port of Ho Chi Minh City",
    "destinationPort": "Port of Los Angeles",
    "incoterms": "FOB",
    "estimatedArrivalDate": "2025-05-05",
    "actualArrivalDate": "2025-05-05",
    "dockAppointmentDate": "2025-05-06T03:00:00",
    "dockDoor": "DOOR-05",
    "status": "PUTAWAY_COMPLETED",
    "notes": "Vessel OOCL EUROPE arrived on schedule. 500k cartons offloaded. Awaiting dock receiving.",
    "createdBy": "wms.inbound.coordinator",
    "createdAt": "2026-03-18T09:04:15",
    "updatedAt": "2026-03-18T09:04:15"
    },
    {
    "externalId": "57b0fbbb-ae84-41d1-bb35-4b4fb0228360",
    "asnNumber": "ASN-2025-003",
    "poExternalId": "po-003-test-uuid",
    "poNumber": "PO-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "vendorExternalId": "vnd-004-uuid",
    "vendorCode": "VND-TH-001",
    "vendorName": "Bangkok Fun Factory Co. Ltd.",
    "vendorCountry": "THAILAND",
    "sku": "TOY-SPACE-MIX-001",
    "toyDescription": "Space Explorer Figure Series \u2014 Summer 2025",
    "expectedQuantity": 250000,
    "unitOfMeasure": "PIECES",
    "carrierName": "MSC Shipping",
    "trackingNumber": "MSC-THAI-20250420-7743",
    "originPort": "Laem Chabang Port, Thailand",
    "destinationPort": "Port of Los Angeles",
    "incoterms": "FOB",
    "estimatedArrivalDate": "2025-05-05",
    "actualArrivalDate": "2025-05-05",
    "dockAppointmentDate": "2025-05-06T08:00:00",
    "dockDoor": "DOOR-07",
    "status": "PUTAWAY_COMPLETED",
    "notes": "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
    "createdBy": "wms.inbound.coordinator",
    "createdAt": "2026-03-18T14:07:14",
    "updatedAt": "2026-03-18T14:07:14"
    }
    ],
    "timestamp": "2026-03-18T14:07:14"
    }

══════════════════════════════════════
16. Duplicate ASN for same PO (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "ASN already exists for PO: po-003-test-uuid",
    "data": null,
    "timestamp": "2026-03-18T14:07:14"
    }

══════════════════════════════════════
17. Attempt to receive SCHEDULED ASN-2025-002 (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "ASN must be ARRIVED to receive. Current: SCHEDULED",
    "data": null,
    "timestamp": "2026-03-18T14:07:14"
    }

══════════════════════════════════════
18. Mark seeded ASN-2025-002 (SCHEDULED) → IN_TRANSIT
    ══════════════════════════════════════
    {
    "success": true,
    "message": "ASN marked in transit",
    "data": {
    "externalId": "asn-002-uuid",
    "asnNumber": "ASN-2025-002",
    "poExternalId": "po-002-uuid",
    "poNumber": "PO-2025-002",
    "campaignExternalId": "camp-002-uuid",
    "campaignCode": "HOLIDAY25-TOY",
    "vendorExternalId": "vnd-001-uuid",
    "vendorCode": "VND-CN-001",
    "vendorName": "Shenzhen BrightToy Manufacturing Co.",
    "vendorCountry": "CHINA",
    "sku": "TOY-HOLIDAY-MIX-001",
    "toyDescription": "Holiday 2025 Collectible Figurines \u2014 6 Character Series",
    "expectedQuantity": 1200000,
    "unitOfMeasure": "PIECES",
    "carrierName": "COSCO Shipping",
    "trackingNumber": "COSCO-CN-20250915-4492",
    "originPort": "Port of Shenzhen",
    "destinationPort": "Port of Long Beach",
    "incoterms": "CIF",
    "estimatedArrivalDate": "2025-10-05",
    "actualArrivalDate": null,
    "dockAppointmentDate": "2025-10-06T02:00:00",
    "dockDoor": "DOOR-03",
    "status": "IN_TRANSIT",
    "notes": "Vessel departs Shenzhen Sept 15. ETA Long Beach Oct 5. Dock slot confirmed.",
    "createdBy": "wms.inbound.coordinator",
    "createdAt": "2026-03-18T09:04:15",
    "updatedAt": "2026-03-18T09:06:38"
    },
    "timestamp": "2026-03-18T14:07:14"
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
    "free": 894366842880,
    "threshold": 10485760,
    "path": "/Users/binit.datta/tms_enterprise_poc/cs-wms-inbound-api/.",
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
✔   erp.wms.inbound.asn.created          — ASN created from PO
✔   erp.wms.inbound.asn.scheduled        — dock appointment confirmed
✔   erp.wms.inbound.shipment.arrived     — vessel docked
✔   erp.wms.inbound.receiving.completed  — physical count done
✔   erp.wms.inbound.putaway.completed    — KEY: OMS marks inventory available
✔ Check: http://localhost:15672 → Queues → control-tower-test
binit.datta@C6NWKQ290Y cs-wms-inbound-api % 