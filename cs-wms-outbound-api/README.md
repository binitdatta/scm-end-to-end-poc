# cs-wms-outbound-api
**WMS Outbound — Pick Wave, Pack, Manifest, Dispatch**

Spring Boot 3.4.3 | JDK 21 | MySQL 8 | RabbitMQ | JPA | Port 8086

---

## Domain

Manages the physical outbound flow of toys from warehouse to restaurant stores:

```
erp.oms.store-order.allocated
        ↓
  Pick wave CREATED     ──→  erp.wms.outbound.wave.created
        ↓
  ASSIGNED → PICKING
        ↓
  COMPLETED              ──→  erp.wms.outbound.wave.completed
        ↓
  Shipment CREATED       ──→  erp.wms.outbound.shipment.created
        ↓
  PACKED                 ──→  erp.wms.outbound.shipment.packed
        ↓
  MANIFESTED             ──→  erp.wms.outbound.shipment.manifested
        ↓
  DISPATCHED             ──→  erp.wms.outbound.shipment.dispatched
                                      ↑ KEY EVENT consumed by cs-tms-api
                                        to track store delivery
```

---

## Setup

### Step 1 — MySQL Workbench
1. `db/01_ddl_cs_wms_outbound.sql` — creates `cs_wms_outbound`, `wms_outbound_app` user (no DDL), 5 tables
2. `db/02_seed_cs_wms_outbound.sql` — seeds WV-2025-001 (COMPLETED), SHP-2025-001 (DISPATCHED with 4 store lines)

### Step 2 — Fix pom.xml and run (port 8086)
```bash
sed -i '' 's|<n>cs-wms-outbound-api</n>|<name>cs-wms-outbound-api</name>|' pom.xml
mvn clean install -DskipTests
java -jar target/cs-wms-outbound-api-1.0.0-SNAPSHOT.jar
```

### Step 3 — Test
```bash
chmod +x test_cs_wms_outbound_api.sh && ./test_cs_wms_outbound_api.sh
```

---

## REST Endpoints

| Method | Path                                      | Description                              |
|--------|-------------------------------------------|------------------------------------------|
| POST   | /api/v1/pick-waves                        | Create pick wave                         |
| GET    | /api/v1/pick-waves                        | List all waves                           |
| GET    | /api/v1/pick-waves/{id}                   | Get wave with bin lines                  |
| GET    | /api/v1/pick-waves/status/{status}        | Filter by status                         |
| GET    | /api/v1/pick-waves/{id}/events            | Wave audit trail                         |
| POST   | /api/v1/pick-waves/{id}/assign            | → ASSIGNED                               |
| POST   | /api/v1/pick-waves/{id}/start             | → PICKING                                |
| POST   | /api/v1/pick-waves/{id}/complete          | → COMPLETED                              |
| POST   | /api/v1/shipments                         | Create shipment from wave                |
| GET    | /api/v1/shipments                         | List all shipments                       |
| GET    | /api/v1/shipments/{id}                    | Get shipment with store lines            |
| GET    | /api/v1/shipments/status/{status}         | Filter by status                         |
| GET    | /api/v1/shipments/campaign/{code}         | Filter by campaign                       |
| GET    | /api/v1/shipments/{id}/events             | Shipment audit trail                     |
| POST   | /api/v1/shipments/{id}/pack               | → PACKED                                 |
| POST   | /api/v1/shipments/{id}/manifest           | → MANIFESTED (assigns carrier + PRO)     |
| POST   | /api/v1/shipments/{id}/dispatch           | → DISPATCHED (**TMS trigger**)           |
| GET    | /actuator/health                          | Health check                             |

---

## RabbitMQ Events Published

| Event                   | Routing Key                                   |
|-------------------------|-----------------------------------------------|
| Pick wave created       | `erp.wms.outbound.wave.created`               |
| Pick wave completed     | `erp.wms.outbound.wave.completed`             |
| Shipment created        | `erp.wms.outbound.shipment.created`           |
| Shipment packed         | `erp.wms.outbound.shipment.packed`            |
| Shipment manifested     | `erp.wms.outbound.shipment.manifested`        |
| **Shipment dispatched** | **`erp.wms.outbound.shipment.dispatched`**    |

Exchange: `erp.topic.exchange` (shared across all ERP services)

---

## Seeded Data

| Entity       | Number       | Status      | Details                                    |
|--------------|--------------|-------------|---------------------------------------------|
| Pick Wave    | WV-2025-001  | COMPLETED   | 128,000 DINO toys from ZONE-A, 2 bin lines |
| Shipment     | SHP-2025-001 | DISPATCHED  | 4 Midwest store cartons, XPO carrier       |

binit.datta@C6NWKQ290Y cs-wms-outbound-api % chmod +x test_cs_wms_outbound_api.sh && ./test_cs_wms_outbound_api.sh


══════════════════════════════════════
1. List seeded pick waves
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Pick waves retrieved",
   "data": [
   {
   "externalId": "pw-001-uuid",
   "waveNumber": "WV-2025-001",
   "storeOrderExternalId": "ord-001-uuid",
   "storeOrderNumber": "ORD-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-MIDWEST",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalQuantity": 128000,
   "pickedQuantity": 128000,
   "pickZone": "ZONE-A",
   "assignedTo": "picker.team.01",
   "requiredShipDate": "2025-05-20",
   "startedAt": "2025-05-18T02:00:00",
   "completedAt": "2025-05-18T11:00:00",
   "status": "COMPLETED",
   "notes": "Full pick completed from ZONE-A. 128,000 units across 4 Midwest stores.",
   "createdBy": "wms.outbound.coordinator",
   "createdAt": "2026-03-19T04:11:28",
   "lines": [
   {
   "externalId": "pwl-001-uuid",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityToPick": 64000,
   "quantityPicked": 64000,
   "status": "PICKED"
   },
   {
   "externalId": "pwl-002-uuid",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityToPick": 64000,
   "quantityPicked": 64000,
   "status": "PICKED"
   }
   ]
   }
   ],
   "timestamp": "2026-03-19T09:12:13"
   }

══════════════════════════════════════
2. Get WV-2025-001 (COMPLETED, 2 bin lines)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Pick wave retrieved",
   "data": {
   "externalId": "pw-001-uuid",
   "waveNumber": "WV-2025-001",
   "storeOrderExternalId": "ord-001-uuid",
   "storeOrderNumber": "ORD-2025-001",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-MIDWEST",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalQuantity": 128000,
   "pickedQuantity": 128000,
   "pickZone": "ZONE-A",
   "assignedTo": "picker.team.01",
   "requiredShipDate": "2025-05-20",
   "startedAt": "2025-05-18T02:00:00",
   "completedAt": "2025-05-18T11:00:00",
   "status": "COMPLETED",
   "notes": "Full pick completed from ZONE-A. 128,000 units across 4 Midwest stores.",
   "createdBy": "wms.outbound.coordinator",
   "createdAt": "2026-03-19T04:11:28",
   "lines": [
   {
   "externalId": "pwl-001-uuid",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityToPick": 64000,
   "quantityPicked": 64000,
   "status": "PICKED"
   },
   {
   "externalId": "pwl-002-uuid",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityToPick": 64000,
   "quantityPicked": 64000,
   "status": "PICKED"
   }
   ]
   },
   "timestamp": "2026-03-19T09:12:13"
   }

══════════════════════════════════════
3. Pick wave events for WV-2025-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Wave events retrieved",
   "data": [
   {
   "id": 1,
   "entityType": "PICK_WAVE",
   "eventType": "WAVE_CREATED",
   "previousStatus": null,
   "newStatus": "CREATED",
   "notes": "Pick wave created from ORD-2025-001 allocation event.",
   "triggeredBy": "wms.outbound.coordinator",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T04:11:28"
   },
   {
   "id": 2,
   "entityType": "PICK_WAVE",
   "eventType": "WAVE_ASSIGNED",
   "previousStatus": "CREATED",
   "newStatus": "ASSIGNED",
   "notes": "Assigned to picker.team.01.",
   "triggeredBy": "wms.outbound.coordinator",
   "rabbitmqPublished": false,
   "eventAt": "2026-03-19T04:11:28"
   },
   {
   "id": 3,
   "entityType": "PICK_WAVE",
   "eventType": "WAVE_COMPLETED",
   "previousStatus": "PICKING",
   "newStatus": "COMPLETED",
   "notes": "128,000 units picked from ZONE-A. 2 bin locations cleared.",
   "triggeredBy": "picker.team.01",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T04:11:28"
   }
   ],
   "timestamp": "2026-03-19T09:12:13"
   }

══════════════════════════════════════
4. List seeded shipments
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Shipments retrieved",
   "data": [
   {
   "externalId": "shp-001-uuid",
   "shipmentNumber": "SHP-2025-001",
   "waveNumber": "WV-2025-001",
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
   "unitsPerCarton": 32000,
   "carrierName": "XPO Logistics",
   "proNumber": "XPO-2025-MW-0441",
   "destinationRegion": "Midwest United States",
   "requiredDeliveryDate": "2025-06-01",
   "estimatedShipDate": "2025-05-20",
   "actualShipDate": "2025-05-20",
   "status": "DISPATCHED",
   "notes": "All 4 Midwest store cartons dispatched. XPO tracking XPO-2025-MW-0441.",
   "createdBy": "wms.outbound.coordinator",
   "createdAt": "2026-03-19T04:11:28",
   "updatedAt": "2026-03-19T04:11:28",
   "storeLines": [
   {
   "storeExternalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "city": "Chicago",
   "stateCode": "IL",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0001",
   "status": "DISPATCHED"
   },
   {
   "storeExternalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "city": "Naperville",
   "stateCode": "IL",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0002",
   "status": "DISPATCHED"
   },
   {
   "storeExternalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "city": "Milwaukee",
   "stateCode": "WI",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0003",
   "status": "DISPATCHED"
   },
   {
   "storeExternalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "city": "Indianapolis",
   "stateCode": "IN",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0004",
   "status": "DISPATCHED"
   }
   ]
   }
   ],
   "timestamp": "2026-03-19T09:12:13"
   }

══════════════════════════════════════
5. Get SHP-2025-001 (DISPATCHED, 4 store carton lines)
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Shipment retrieved",
   "data": {
   "externalId": "shp-001-uuid",
   "shipmentNumber": "SHP-2025-001",
   "waveNumber": "WV-2025-001",
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
   "unitsPerCarton": 32000,
   "carrierName": "XPO Logistics",
   "proNumber": "XPO-2025-MW-0441",
   "destinationRegion": "Midwest United States",
   "requiredDeliveryDate": "2025-06-01",
   "estimatedShipDate": "2025-05-20",
   "actualShipDate": "2025-05-20",
   "status": "DISPATCHED",
   "notes": "All 4 Midwest store cartons dispatched. XPO tracking XPO-2025-MW-0441.",
   "createdBy": "wms.outbound.coordinator",
   "createdAt": "2026-03-19T04:11:28",
   "updatedAt": "2026-03-19T04:11:28",
   "storeLines": [
   {
   "storeExternalId": "str-001-uuid",
   "storeNumber": "STR-0001",
   "storeName": "Burger Bliss Chicago Downtown",
   "city": "Chicago",
   "stateCode": "IL",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0001",
   "status": "DISPATCHED"
   },
   {
   "storeExternalId": "str-002-uuid",
   "storeNumber": "STR-0002",
   "storeName": "Burger Bliss Naperville",
   "city": "Naperville",
   "stateCode": "IL",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0002",
   "status": "DISPATCHED"
   },
   {
   "storeExternalId": "str-003-uuid",
   "storeNumber": "STR-0003",
   "storeName": "Burger Bliss Milwaukee",
   "city": "Milwaukee",
   "stateCode": "WI",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0003",
   "status": "DISPATCHED"
   },
   {
   "storeExternalId": "str-004-uuid",
   "storeNumber": "STR-0004",
   "storeName": "Burger Bliss Indianapolis",
   "city": "Indianapolis",
   "stateCode": "IN",
   "quantity": 32000,
   "cartonLabel": "CTN-MW-0004",
   "status": "DISPATCHED"
   }
   ]
   },
   "timestamp": "2026-03-19T09:12:13"
   }

══════════════════════════════════════
6. Shipment events for SHP-2025-001
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Shipment events retrieved",
   "data": [
   {
   "id": 4,
   "entityType": "SHIPMENT",
   "eventType": "SHIPMENT_CREATED",
   "previousStatus": null,
   "newStatus": "CREATED",
   "notes": "Shipment SHP-2025-001 created from completed pick wave WV-2025-001.",
   "triggeredBy": "wms.outbound.coordinator",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T04:11:28"
   },
   {
   "id": 5,
   "entityType": "SHIPMENT",
   "eventType": "SHIPMENT_PACKED",
   "previousStatus": "CREATED",
   "newStatus": "PACKED",
   "notes": "4 store cartons packed and labeled. Carton labels printed.",
   "triggeredBy": "wms.outbound.packer",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T04:11:28"
   },
   {
   "id": 6,
   "entityType": "SHIPMENT",
   "eventType": "SHIPMENT_MANIFESTED",
   "previousStatus": "PACKED",
   "newStatus": "MANIFESTED",
   "notes": "XPO manifest generated. PRO XPO-2025-MW-0441 assigned.",
   "triggeredBy": "wms.outbound.coordinator",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T04:11:28"
   },
   {
   "id": 7,
   "entityType": "SHIPMENT",
   "eventType": "SHIPMENT_DISPATCHED",
   "previousStatus": "MANIFESTED",
   "newStatus": "DISPATCHED",
   "notes": "XPO driver collected. 4 cartons en route to Midwest stores.",
   "triggeredBy": "wms.outbound.coordinator",
   "rabbitmqPublished": true,
   "eventAt": "2026-03-19T04:11:28"
   }
   ],
   "timestamp": "2026-03-19T09:12:13"
   }

══════════════════════════════════════
7. Create pick wave WV-2025-002 (SE ORD-2025-003) → erp.wms.outbound.wave.created
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Pick wave created",
   "data": {
   "externalId": "0d0c6b98-867c-49d8-9dd7-9fd55268f2b3",
   "waveNumber": "WV-2025-002",
   "storeOrderExternalId": "ord-003-ext-uuid",
   "storeOrderNumber": "ORD-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-SOUTHEAST",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalQuantity": 104000,
   "pickedQuantity": 0,
   "pickZone": "ZONE-A",
   "assignedTo": null,
   "requiredShipDate": "2025-05-28",
   "startedAt": null,
   "completedAt": null,
   "status": "CREATED",
   "notes": "Southeast allocation pick \u2014 4 stores x 26,000 units from ZONE-A.",
   "createdBy": "wms.outbound.coordinator",
   "createdAt": "2026-03-19T09:12:13",
   "lines": [
   {
   "externalId": "e37888af-dc7a-481c-a51a-f46d00c70a69",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityToPick": 52000,
   "quantityPicked": 0,
   "status": "PENDING"
   },
   {
   "externalId": "69afc906-e37a-414b-b740-8a98b8d6e09f",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityToPick": 52000,
   "quantityPicked": 0,
   "status": "PENDING"
   }
   ]
   },
   "timestamp": "2026-03-19T09:12:13"
   }
   ✔ New wave externalId: 0d0c6b98-867c-49d8-9dd7-9fd55268f2b3

══════════════════════════════════════
8. Assign wave to picker team
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Wave assigned",
   "data": {
   "externalId": "0d0c6b98-867c-49d8-9dd7-9fd55268f2b3",
   "waveNumber": "WV-2025-002",
   "storeOrderExternalId": "ord-003-ext-uuid",
   "storeOrderNumber": "ORD-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-SOUTHEAST",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalQuantity": 104000,
   "pickedQuantity": 0,
   "pickZone": "ZONE-A",
   "assignedTo": "picker.team.02",
   "requiredShipDate": "2025-05-28",
   "startedAt": null,
   "completedAt": null,
   "status": "ASSIGNED",
   "notes": "Southeast allocation pick \u2014 4 stores x 26,000 units from ZONE-A.",
   "createdBy": "wms.outbound.coordinator",
   "createdAt": "2026-03-19T09:12:14",
   "lines": [
   {
   "externalId": "e37888af-dc7a-481c-a51a-f46d00c70a69",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityToPick": 52000,
   "quantityPicked": 0,
   "status": "PENDING"
   },
   {
   "externalId": "69afc906-e37a-414b-b740-8a98b8d6e09f",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityToPick": 52000,
   "quantityPicked": 0,
   "status": "PENDING"
   }
   ]
   },
   "timestamp": "2026-03-19T09:12:13"
   }

══════════════════════════════════════
9. Start picking
   ══════════════════════════════════════
   {
   "success": true,
   "message": "Picking started",
   "data": {
   "externalId": "0d0c6b98-867c-49d8-9dd7-9fd55268f2b3",
   "waveNumber": "WV-2025-002",
   "storeOrderExternalId": "ord-003-ext-uuid",
   "storeOrderNumber": "ORD-2025-003",
   "campaignExternalId": "camp-001-uuid",
   "campaignCode": "SUMMER25-TOY",
   "regionCode": "US-SOUTHEAST",
   "sku": "TOY-DINO-MIX-001",
   "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
   "totalQuantity": 104000,
   "pickedQuantity": 0,
   "pickZone": "ZONE-A",
   "assignedTo": "picker.team.02",
   "requiredShipDate": "2025-05-28",
   "startedAt": "2026-03-19T09:12:13",
   "completedAt": null,
   "status": "PICKING",
   "notes": "Southeast allocation pick \u2014 4 stores x 26,000 units from ZONE-A.",
   "createdBy": "wms.outbound.coordinator",
   "createdAt": "2026-03-19T09:12:14",
   "lines": [
   {
   "externalId": "e37888af-dc7a-481c-a51a-f46d00c70a69",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-01",
   "warehouseBin": "BIN-A-01-001",
   "quantityToPick": 52000,
   "quantityPicked": 0,
   "status": "PENDING"
   },
   {
   "externalId": "69afc906-e37a-414b-b740-8a98b8d6e09f",
   "warehouseZone": "ZONE-A",
   "warehouseAisle": "A-02",
   "warehouseBin": "BIN-A-02-001",
   "quantityToPick": 52000,
   "quantityPicked": 0,
   "status": "PENDING"
   }
   ]
   },
   "timestamp": "2026-03-19T09:12:13"
   }

══════════════════════════════════════
10. Complete wave → erp.wms.outbound.wave.completed
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Wave completed",
    "data": {
    "externalId": "0d0c6b98-867c-49d8-9dd7-9fd55268f2b3",
    "waveNumber": "WV-2025-002",
    "storeOrderExternalId": "ord-003-ext-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalQuantity": 104000,
    "pickedQuantity": 104000,
    "pickZone": "ZONE-A",
    "assignedTo": "picker.team.02",
    "requiredShipDate": "2025-05-28",
    "startedAt": "2026-03-19T09:12:14",
    "completedAt": "2026-03-19T09:12:13",
    "status": "COMPLETED",
    "notes": "Southeast allocation pick \u2014 4 stores x 26,000 units from ZONE-A.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T09:12:14",
    "lines": [
    {
    "externalId": "e37888af-dc7a-481c-a51a-f46d00c70a69",
    "warehouseZone": "ZONE-A",
    "warehouseAisle": "A-01",
    "warehouseBin": "BIN-A-01-001",
    "quantityToPick": 52000,
    "quantityPicked": 52000,
    "status": "PICKED"
    },
    {
    "externalId": "69afc906-e37a-414b-b740-8a98b8d6e09f",
    "warehouseZone": "ZONE-A",
    "warehouseAisle": "A-02",
    "warehouseBin": "BIN-A-02-001",
    "quantityToPick": 52000,
    "quantityPicked": 52000,
    "status": "PICKED"
    }
    ]
    },
    "timestamp": "2026-03-19T09:12:13"
    }
    ✔ Wave completed — ready for shipment creation

══════════════════════════════════════
11. Create shipment SHP-2025-002 → erp.wms.outbound.shipment.created
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment created successfully",
    "data": {
    "externalId": "c957c0dd-418b-4c81-b4ec-731606bb2727",
    "shipmentNumber": "SHP-2025-002",
    "waveNumber": "WV-2025-002",
    "storeOrderExternalId": "ord-003-ext-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 104000,
    "unitsPerCarton": 26000,
    "carrierName": "Old Dominion Freight",
    "proNumber": null,
    "destinationRegion": null,
    "requiredDeliveryDate": "2025-06-01",
    "estimatedShipDate": "2025-05-28",
    "actualShipDate": null,
    "status": "CREATED",
    "notes": "Southeast store cartons \u2014 4 stores.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T09:12:13",
    "updatedAt": "2026-03-19T09:12:13",
    "storeLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "status": "PENDING"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "status": "PENDING"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "status": "PENDING"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "status": "PENDING"
    }
    ]
    },
    "timestamp": "2026-03-19T09:12:13"
    }
    ✔ New shipment externalId: c957c0dd-418b-4c81-b4ec-731606bb2727

══════════════════════════════════════
12. Pack shipment → erp.wms.outbound.shipment.packed
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment packed",
    "data": {
    "externalId": "c957c0dd-418b-4c81-b4ec-731606bb2727",
    "shipmentNumber": "SHP-2025-002",
    "waveNumber": "WV-2025-002",
    "storeOrderExternalId": "ord-003-ext-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 104000,
    "unitsPerCarton": 26000,
    "carrierName": "Old Dominion Freight",
    "proNumber": null,
    "destinationRegion": null,
    "requiredDeliveryDate": "2025-06-01",
    "estimatedShipDate": "2025-05-28",
    "actualShipDate": null,
    "status": "PACKED",
    "notes": "Southeast store cartons \u2014 4 stores.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T09:12:14",
    "updatedAt": "2026-03-19T09:12:13",
    "storeLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "status": "PACKED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "status": "PACKED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "status": "PACKED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "status": "PACKED"
    }
    ]
    },
    "timestamp": "2026-03-19T09:12:13"
    }

══════════════════════════════════════
13. Manifest shipment → erp.wms.outbound.shipment.manifested
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment manifested",
    "data": {
    "externalId": "c957c0dd-418b-4c81-b4ec-731606bb2727",
    "shipmentNumber": "SHP-2025-002",
    "waveNumber": "WV-2025-002",
    "storeOrderExternalId": "ord-003-ext-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 104000,
    "unitsPerCarton": 26000,
    "carrierName": "Old Dominion Freight",
    "proNumber": "OD-2025-SE-8812",
    "destinationRegion": null,
    "requiredDeliveryDate": "2025-06-01",
    "estimatedShipDate": "2025-05-28",
    "actualShipDate": null,
    "status": "MANIFESTED",
    "notes": "Southeast store cartons \u2014 4 stores.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T09:12:14",
    "updatedAt": "2026-03-19T09:12:13",
    "storeLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "status": "PACKED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "status": "PACKED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "status": "PACKED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "status": "PACKED"
    }
    ]
    },
    "timestamp": "2026-03-19T09:12:13"
    }

══════════════════════════════════════
14. DISPATCH shipment → erp.wms.outbound.shipment.dispatched (TMS trigger)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment dispatched",
    "data": {
    "externalId": "c957c0dd-418b-4c81-b4ec-731606bb2727",
    "shipmentNumber": "SHP-2025-002",
    "waveNumber": "WV-2025-002",
    "storeOrderExternalId": "ord-003-ext-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 104000,
    "unitsPerCarton": 26000,
    "carrierName": "Old Dominion Freight",
    "proNumber": "OD-2025-SE-8812",
    "destinationRegion": null,
    "requiredDeliveryDate": "2025-06-01",
    "estimatedShipDate": "2025-05-28",
    "actualShipDate": "2026-03-19",
    "status": "DISPATCHED",
    "notes": "Southeast store cartons \u2014 4 stores.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T09:12:14",
    "updatedAt": "2026-03-19T09:12:13",
    "storeLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "status": "DISPATCHED"
    }
    ]
    },
    "timestamp": "2026-03-19T09:12:13"
    }
    ✔ KEY EVENT: erp.wms.outbound.shipment.dispatched published
    ✔ TMS will track delivery of 4 store cartons across Southeast

══════════════════════════════════════
15. Verify shipment store lines (all DISPATCHED)
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment retrieved",
    "data": {
    "externalId": "c957c0dd-418b-4c81-b4ec-731606bb2727",
    "shipmentNumber": "SHP-2025-002",
    "waveNumber": "WV-2025-002",
    "storeOrderExternalId": "ord-003-ext-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 104000,
    "unitsPerCarton": 26000,
    "carrierName": "Old Dominion Freight",
    "proNumber": "OD-2025-SE-8812",
    "destinationRegion": null,
    "requiredDeliveryDate": "2025-06-01",
    "estimatedShipDate": "2025-05-28",
    "actualShipDate": "2026-03-19",
    "status": "DISPATCHED",
    "notes": "Southeast store cartons \u2014 4 stores.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T09:12:14",
    "updatedAt": "2026-03-19T09:12:14",
    "storeLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "status": "DISPATCHED"
    }
    ]
    },
    "timestamp": "2026-03-19T09:12:13"
    }

══════════════════════════════════════
16. Full shipment event trail
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipment events retrieved",
    "data": [
    {
    "id": 12,
    "entityType": "SHIPMENT",
    "eventType": "SHIPMENT_CREATED",
    "previousStatus": null,
    "newStatus": "CREATED",
    "notes": "Shipment created from wave WV-2025-002",
    "triggeredBy": "wms.outbound.coordinator",
    "rabbitmqPublished": false,
    "eventAt": "2026-03-19T09:12:14"
    },
    {
    "id": 13,
    "entityType": "SHIPMENT",
    "eventType": "SHIPMENT_PACKED",
    "previousStatus": "CREATED",
    "newStatus": "PACKED",
    "notes": "All 4 SE store cartons packed and labeled.",
    "triggeredBy": "wms.outbound.packer",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T09:12:14"
    },
    {
    "id": 14,
    "entityType": "SHIPMENT",
    "eventType": "SHIPMENT_MANIFESTED",
    "previousStatus": "PACKED",
    "newStatus": "MANIFESTED",
    "notes": "Carrier: Old Dominion Freight PRO: OD-2025-SE-8812",
    "triggeredBy": "wms.outbound.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T09:12:14"
    },
    {
    "id": 15,
    "entityType": "SHIPMENT",
    "eventType": "SHIPMENT_DISPATCHED",
    "previousStatus": "MANIFESTED",
    "newStatus": "DISPATCHED",
    "notes": "4 cartons dispatched via Old Dominion Freight PRO OD-2025-SE-8812",
    "triggeredBy": "wms.outbound.coordinator",
    "rabbitmqPublished": true,
    "eventAt": "2026-03-19T09:12:14"
    }
    ],
    "timestamp": "2026-03-19T09:12:14"
    }

══════════════════════════════════════
17. Filter pick waves by status=COMPLETED
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Waves for status: COMPLETED",
    "data": [
    {
    "externalId": "pw-001-uuid",
    "waveNumber": "WV-2025-001",
    "storeOrderExternalId": "ord-001-uuid",
    "storeOrderNumber": "ORD-2025-001",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-MIDWEST",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalQuantity": 128000,
    "pickedQuantity": 128000,
    "pickZone": "ZONE-A",
    "assignedTo": "picker.team.01",
    "requiredShipDate": "2025-05-20",
    "startedAt": "2025-05-18T02:00:00",
    "completedAt": "2025-05-18T11:00:00",
    "status": "COMPLETED",
    "notes": "Full pick completed from ZONE-A. 128,000 units across 4 Midwest stores.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T04:11:28",
    "lines": [
    {
    "externalId": "pwl-001-uuid",
    "warehouseZone": "ZONE-A",
    "warehouseAisle": "A-01",
    "warehouseBin": "BIN-A-01-001",
    "quantityToPick": 64000,
    "quantityPicked": 64000,
    "status": "PICKED"
    },
    {
    "externalId": "pwl-002-uuid",
    "warehouseZone": "ZONE-A",
    "warehouseAisle": "A-02",
    "warehouseBin": "BIN-A-02-001",
    "quantityToPick": 64000,
    "quantityPicked": 64000,
    "status": "PICKED"
    }
    ]
    },
    {
    "externalId": "0d0c6b98-867c-49d8-9dd7-9fd55268f2b3",
    "waveNumber": "WV-2025-002",
    "storeOrderExternalId": "ord-003-ext-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalQuantity": 104000,
    "pickedQuantity": 104000,
    "pickZone": "ZONE-A",
    "assignedTo": "picker.team.02",
    "requiredShipDate": "2025-05-28",
    "startedAt": "2026-03-19T09:12:14",
    "completedAt": "2026-03-19T09:12:14",
    "status": "COMPLETED",
    "notes": "Southeast allocation pick \u2014 4 stores x 26,000 units from ZONE-A.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T09:12:14",
    "lines": [
    {
    "externalId": "e37888af-dc7a-481c-a51a-f46d00c70a69",
    "warehouseZone": "ZONE-A",
    "warehouseAisle": "A-01",
    "warehouseBin": "BIN-A-01-001",
    "quantityToPick": 52000,
    "quantityPicked": 52000,
    "status": "PICKED"
    },
    {
    "externalId": "69afc906-e37a-414b-b740-8a98b8d6e09f",
    "warehouseZone": "ZONE-A",
    "warehouseAisle": "A-02",
    "warehouseBin": "BIN-A-02-001",
    "quantityToPick": 52000,
    "quantityPicked": 52000,
    "status": "PICKED"
    }
    ]
    }
    ],
    "timestamp": "2026-03-19T09:12:14"
    }

══════════════════════════════════════
18. Filter shipments by campaign SUMMER25-TOY
    ══════════════════════════════════════
    {
    "success": true,
    "message": "Shipments for campaign: SUMMER25-TOY",
    "data": [
    {
    "externalId": "shp-001-uuid",
    "shipmentNumber": "SHP-2025-001",
    "waveNumber": "WV-2025-001",
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
    "unitsPerCarton": 32000,
    "carrierName": "XPO Logistics",
    "proNumber": "XPO-2025-MW-0441",
    "destinationRegion": "Midwest United States",
    "requiredDeliveryDate": "2025-06-01",
    "estimatedShipDate": "2025-05-20",
    "actualShipDate": "2025-05-20",
    "status": "DISPATCHED",
    "notes": "All 4 Midwest store cartons dispatched. XPO tracking XPO-2025-MW-0441.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T04:11:28",
    "updatedAt": "2026-03-19T04:11:28",
    "storeLines": [
    {
    "storeExternalId": "str-001-uuid",
    "storeNumber": "STR-0001",
    "storeName": "Burger Bliss Chicago Downtown",
    "city": "Chicago",
    "stateCode": "IL",
    "quantity": 32000,
    "cartonLabel": "CTN-MW-0001",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-002-uuid",
    "storeNumber": "STR-0002",
    "storeName": "Burger Bliss Naperville",
    "city": "Naperville",
    "stateCode": "IL",
    "quantity": 32000,
    "cartonLabel": "CTN-MW-0002",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-003-uuid",
    "storeNumber": "STR-0003",
    "storeName": "Burger Bliss Milwaukee",
    "city": "Milwaukee",
    "stateCode": "WI",
    "quantity": 32000,
    "cartonLabel": "CTN-MW-0003",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-004-uuid",
    "storeNumber": "STR-0004",
    "storeName": "Burger Bliss Indianapolis",
    "city": "Indianapolis",
    "stateCode": "IN",
    "quantity": 32000,
    "cartonLabel": "CTN-MW-0004",
    "status": "DISPATCHED"
    }
    ]
    },
    {
    "externalId": "c957c0dd-418b-4c81-b4ec-731606bb2727",
    "shipmentNumber": "SHP-2025-002",
    "waveNumber": "WV-2025-002",
    "storeOrderExternalId": "ord-003-ext-uuid",
    "storeOrderNumber": "ORD-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode": "SUMMER25-TOY",
    "regionCode": "US-SOUTHEAST",
    "distributionDc": "DC-ATLANTA",
    "sku": "TOY-DINO-MIX-001",
    "toyDescription": "Mystery Dinosaur Figures \u2014 Summer 2025 Kids Meal Toy Surprise",
    "totalCartons": 4,
    "totalUnits": 104000,
    "unitsPerCarton": 26000,
    "carrierName": "Old Dominion Freight",
    "proNumber": "OD-2025-SE-8812",
    "destinationRegion": null,
    "requiredDeliveryDate": "2025-06-01",
    "estimatedShipDate": "2025-05-28",
    "actualShipDate": "2026-03-19",
    "status": "DISPATCHED",
    "notes": "Southeast store cartons \u2014 4 stores.",
    "createdBy": "wms.outbound.coordinator",
    "createdAt": "2026-03-19T09:12:14",
    "updatedAt": "2026-03-19T09:12:14",
    "storeLines": [
    {
    "storeExternalId": "str-009-uuid",
    "storeNumber": "STR-0201",
    "storeName": "Burger Bliss Atlanta Midtown",
    "city": "Atlanta",
    "stateCode": "GA",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0001",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-010-uuid",
    "storeNumber": "STR-0202",
    "storeName": "Burger Bliss Miami Brickell",
    "city": "Miami",
    "stateCode": "FL",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0002",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-011-uuid",
    "storeNumber": "STR-0203",
    "storeName": "Burger Bliss Charlotte",
    "city": "Charlotte",
    "stateCode": "NC",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0003",
    "status": "DISPATCHED"
    },
    {
    "storeExternalId": "str-012-uuid",
    "storeNumber": "STR-0204",
    "storeName": "Burger Bliss Nashville",
    "city": "Nashville",
    "stateCode": "TN",
    "quantity": 26000,
    "cartonLabel": "CTN-SE-0004",
    "status": "DISPATCHED"
    }
    ]
    }
    ],
    "timestamp": "2026-03-19T09:12:14"
    }

══════════════════════════════════════
19. Duplicate wave number (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "Wave number already exists: WV-2025-002",
    "data": null,
    "timestamp": "2026-03-19T09:12:14"
    }

══════════════════════════════════════
20. Create shipment from CREATED wave (expect 409)
    ══════════════════════════════════════
    {
    "success": false,
    "message": "Pick wave must be COMPLETED before creating shipment. Current: CREATED",
    "data": null,
    "timestamp": "2026-03-19T09:12:14"
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
    "free": 893661536256,
    "threshold": 10485760,
    "path": "/Users/binit.datta/tms_enterprise_poc/cs-wms-outbound-api/.",
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
✔   erp.wms.outbound.wave.created        — pick wave initiated
✔   erp.wms.outbound.wave.completed      — picking done, ready for pack
✔   erp.wms.outbound.shipment.created    — cartons staged
✔   erp.wms.outbound.shipment.packed     — cartons sealed and labeled
✔   erp.wms.outbound.shipment.manifested — carrier PRO assigned
✔   erp.wms.outbound.shipment.dispatched — KEY: TMS tracks store delivery
✔ Check: http://localhost:15672 → Queues → control-tower-test
binit.datta@C6NWKQ290Y cs-wms-outbound-api % 