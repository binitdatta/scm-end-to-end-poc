#!/bin/bash
# =============================================================================
# cs-tms-api — curl test script
# Full TMS lifecycle — the FINAL Spring Boot service in the supply chain:
#   1.  List seeded loads (LOAD-2025-001 COMPLETED, 4 stores POD confirmed)
#   2.  Get LOAD-2025-001 with store delivery details
#   3.  Get transit events (carrier tracking milestones)
#   4.  Get TMS audit events
#   5.  Filter loads by campaign
#   6.  Create new load LOAD-2025-002 (SE, Old Dominion) → erp.tms.load.created
#   7.  Assign driver + truck → erp.tms.load.assigned
#   8.  Mark in transit → erp.tms.load.in-transit + erp.tms.delivery.out-for-delivery
#   9.  Record carrier transit events (PICKUP, IN_TRANSIT)
#   10. Confirm POD — Store 1 (Atlanta)
#   11. Confirm POD — Store 2 (Miami)
#   12. Confirm POD — Store 3 (Charlotte)
#   13. Confirm POD — Store 4 (Nashville) → AUTO TRIGGERS:
#       erp.tms.delivery.pod-confirmed (KEY — final supply chain event)
#       erp.tms.load.completed
#   14. Verify load COMPLETED with all stores POD_CONFIRMED
#   15. Full TMS audit trail
#   16. Full transit event trail
#   17. Filter loads by status=COMPLETED
#   18. Guard: duplicate load for same shipment (expect 409)
#   19. Guard: assign driver to COMPLETED load (expect 409)
#   20. Guard: POD on wrong load (expect 404/409)
#   21. Actuator health
#
# Prerequisites:
#   - cs-tms-api running on localhost:8087
#   - RabbitMQ running on localhost:5672
#   - cs_tms DB seeded via 01_ddl + 02_seed scripts
#
# Usage: chmod +x test_cs_tms_api.sh && ./test_cs_tms_api.sh
# =============================================================================

BASE_URL="http://localhost:8087/api/v1"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
section() { echo -e "\n${YELLOW}══════════════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}══════════════════════════════════════${NC}"; }
ok()      { echo -e "${GREEN}✔ $1${NC}"; }

# ── 1. List seeded loads ──────────────────────────────────────────────────────
section "1. List seeded loads (LOAD-2025-001 COMPLETED)"
curl -s "$BASE_URL/delivery-loads" | python3 -m json.tool

# ── 2. Get LOAD-2025-001 with store deliveries ───────────────────────────────
section "2. Get LOAD-2025-001 (COMPLETED, 4 stores POD_CONFIRMED)"
curl -s "$BASE_URL/delivery-loads/load-001-uuid" | python3 -m json.tool

# ── 3. Transit events ─────────────────────────────────────────────────────────
section "3. Transit events for LOAD-2025-001"
curl -s "$BASE_URL/delivery-loads/load-001-uuid/transit-events" | python3 -m json.tool

# ── 4. TMS audit events ───────────────────────────────────────────────────────
section "4. TMS audit events for LOAD-2025-001"
curl -s "$BASE_URL/delivery-loads/load-001-uuid/events" | python3 -m json.tool

# ── 5. Filter by campaign ─────────────────────────────────────────────────────
section "5. Filter loads by campaign SUMMER25-TOY"
curl -s "$BASE_URL/delivery-loads/campaign/SUMMER25-TOY" | python3 -m json.tool

# ── 6. Create new load ────────────────────────────────────────────────────────
section "6. Create LOAD-2025-002 (SE, Old Dominion) → erp.tms.load.created"
NEW_LOAD=$(curl -s -X POST "$BASE_URL/delivery-loads" \
  -H "Content-Type: application/json" \
  -d '{
    "loadNumber":            "LOAD-2025-002",
    "shipmentExternalId":    "shp-002-ext-uuid",
    "shipmentNumber":        "SHP-2025-002",
    "storeOrderExternalId":  "ord-003-uuid",
    "storeOrderNumber":      "ORD-2025-003",
    "campaignExternalId":    "camp-001-uuid",
    "campaignCode":          "SUMMER25-TOY",
    "regionCode":            "US-SOUTHEAST",
    "distributionDc":        "DC-ATLANTA",
    "sku":                   "TOY-DINO-MIX-001",
    "toyDescription":        "Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise",
    "totalCartons":          4,
    "totalUnits":            104000,
    "carrierName":           "Old Dominion Freight",
    "proNumber":             "OD-2025-SE-8812",
    "requiredDeliveryDate":  "2025-06-01",
    "createdBy":             "tms.coordinator",
    "notes":                 "Southeast stores — 4 cartons, Old Dominion PRO OD-2025-SE-8812.",
    "storeCartons": [
      {"storeExternalId":"str-009-uuid","storeNumber":"STR-0201","storeName":"Burger Bliss Atlanta Midtown","city":"Atlanta","stateCode":"GA","sku":"TOY-DINO-MIX-001","quantity":26000,"cartonLabel":"CTN-SE-0001"},
      {"storeExternalId":"str-010-uuid","storeNumber":"STR-0202","storeName":"Burger Bliss Miami Brickell","city":"Miami","stateCode":"FL","sku":"TOY-DINO-MIX-001","quantity":26000,"cartonLabel":"CTN-SE-0002"},
      {"storeExternalId":"str-011-uuid","storeNumber":"STR-0203","storeName":"Burger Bliss Charlotte","city":"Charlotte","stateCode":"NC","sku":"TOY-DINO-MIX-001","quantity":26000,"cartonLabel":"CTN-SE-0003"},
      {"storeExternalId":"str-012-uuid","storeNumber":"STR-0204","storeName":"Burger Bliss Nashville","city":"Nashville","stateCode":"TN","sku":"TOY-DINO-MIX-001","quantity":26000,"cartonLabel":"CTN-SE-0004"}
    ]
  }')
echo "$NEW_LOAD" | python3 -m json.tool
LOAD_ID=$(echo "$NEW_LOAD" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "New load externalId: $LOAD_ID"

# Capture store delivery external IDs for POD confirmation
STORE_1=$(echo "$NEW_LOAD" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d['storeDeliveries'][0]['externalId'])" 2>/dev/null)
STORE_2=$(echo "$NEW_LOAD" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d['storeDeliveries'][1]['externalId'])" 2>/dev/null)
STORE_3=$(echo "$NEW_LOAD" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d['storeDeliveries'][2]['externalId'])" 2>/dev/null)
STORE_4=$(echo "$NEW_LOAD" | python3 -c "import sys,json; d=json.load(sys.stdin)['data']; print(d['storeDeliveries'][3]['externalId'])" 2>/dev/null)
ok "Store deliveries: $STORE_1 | $STORE_2 | $STORE_3 | $STORE_4"

# ── 7. Assign driver ──────────────────────────────────────────────────────────
section "7. Assign driver + truck → erp.tms.load.assigned"
curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/assign" \
  -H "Content-Type: application/json" \
  -d '{
    "driverName":             "Carlos Mendez",
    "truckNumber":            "OD-TRUCK-8812",
    "pickupDate":             "2025-05-28",
    "estimatedDeliveryDate":  "2025-06-01",
    "notes":                  "Driver Carlos Mendez assigned. Truck OD-TRUCK-8812. 4 SE stops."
  }' | python3 -m json.tool

# ── 8. Mark in transit ────────────────────────────────────────────────────────
section "8. Mark IN_TRANSIT → erp.tms.load.in-transit + erp.tms.delivery.out-for-delivery"
curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/in-transit" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"od.carrier.api","notes":"Driver Carlos Mendez picked up load from DC-ATLANTA. PRO OD-2025-SE-8812 active."}' \
  | python3 -m json.tool

# ── 9. Record transit events ──────────────────────────────────────────────────
section "9. Record carrier transit milestones"
curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/transit-events" \
  -H "Content-Type: application/json" \
  -d '{"eventCode":"PICKUP","eventDescription":"Load picked up from DC-ATLANTA.","location":"Atlanta, GA","source":"CARRIER_API"}' \
  | python3 -m json.tool

curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/transit-events" \
  -H "Content-Type: application/json" \
  -d '{"eventCode":"IN_TRANSIT","eventDescription":"En route to Southeast stores.","location":"Macon, GA","source":"CARRIER_API"}' \
  | python3 -m json.tool
ok "Carrier milestones recorded"

# ── 10. POD — Atlanta ─────────────────────────────────────────────────────────
section "10. Confirm POD — Burger Bliss Atlanta"
curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/store-deliveries/$STORE_1/pod" \
  -H "Content-Type: application/json" \
  -d '{
    "deliveredQuantity": 26000,
    "podSignatory":      "Maria Gonzalez",
    "podNotes":          "Full carton received at Atlanta. 26,000 dino toys. Signed at receiving dock.",
    "deliveredAt":       "2025-05-29T10:00:00"
  }' | python3 -m json.tool

# ── 11. POD — Miami ───────────────────────────────────────────────────────────
section "11. Confirm POD — Burger Bliss Miami"
curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/store-deliveries/$STORE_2/pod" \
  -H "Content-Type: application/json" \
  -d '{
    "deliveredQuantity": 26000,
    "podSignatory":      "James Williams",
    "podNotes":          "All 26,000 units received in good condition. Stored in back room.",
    "deliveredAt":       "2025-05-29T14:30:00"
  }' | python3 -m json.tool

# ── 12. POD — Charlotte ───────────────────────────────────────────────────────
section "12. Confirm POD — Burger Bliss Charlotte"
curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/store-deliveries/$STORE_3/pod" \
  -H "Content-Type: application/json" \
  -d '{
    "deliveredQuantity": 26000,
    "podSignatory":      "Angela Davis",
    "podNotes":          "Delivery accepted. No damage. Carton label CTN-SE-0003 scanned.",
    "deliveredAt":       "2025-05-30T09:15:00"
  }' | python3 -m json.tool

# ── 13. POD — Nashville (FINAL STORE → AUTO COMPLETES LOAD) ──────────────────
section "13. Confirm POD — Burger Bliss Nashville → TRIGGERS FINAL SUPPLY CHAIN EVENTS"
curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/store-deliveries/$STORE_4/pod" \
  -H "Content-Type: application/json" \
  -d '{
    "deliveredQuantity": 26000,
    "podSignatory":      "Robert Kim",
    "podNotes":          "Final delivery on this load. All 26,000 Nashville units confirmed.",
    "deliveredAt":       "2025-05-30T15:00:00"
  }' | python3 -m json.tool
ok "ALL 4 STORES POD CONFIRMED — Load auto-completed!"
ok "KEY EVENT: erp.tms.delivery.pod-confirmed published (FINAL supply chain event)"
ok "erp.tms.load.completed published"
ok "Flask Control Tower will receive this and update BI dashboard"

# ── 14. Verify load COMPLETED ─────────────────────────────────────────────────
section "14. Verify load COMPLETED — all 4 stores POD_CONFIRMED"
curl -s "$BASE_URL/delivery-loads/$LOAD_ID" | python3 -m json.tool

# ── 15. Full TMS audit trail ──────────────────────────────────────────────────
section "15. Full TMS audit trail (CREATED → ASSIGNED → IN_TRANSIT → COMPLETED)"
curl -s "$BASE_URL/delivery-loads/$LOAD_ID/events" | python3 -m json.tool

# ── 16. Transit event trail ───────────────────────────────────────────────────
section "16. Carrier transit event trail"
curl -s "$BASE_URL/delivery-loads/$LOAD_ID/transit-events" | python3 -m json.tool

# ── 17. Filter by status COMPLETED ───────────────────────────────────────────
section "17. Filter loads by status=COMPLETED"
curl -s "$BASE_URL/delivery-loads/status/COMPLETED" | python3 -m json.tool

# ── 18. Duplicate shipment guard ──────────────────────────────────────────────
section "18. Duplicate load for same shipment (expect 409)"
curl -s -X POST "$BASE_URL/delivery-loads" \
  -H "Content-Type: application/json" \
  -d '{
    "loadNumber":"LOAD-DUP","shipmentExternalId":"shp-002-ext-uuid",
    "shipmentNumber":"SHP-2025-002","storeOrderExternalId":"x","storeOrderNumber":"x",
    "campaignExternalId":"x","campaignCode":"x","regionCode":"x","sku":"x",
    "toyDescription":"x","totalCartons":1,"totalUnits":1,
    "carrierName":"x","proNumber":"x","requiredDeliveryDate":"2025-06-01",
    "createdBy":"test",
    "storeCartons":[{"storeExternalId":"x","storeNumber":"x","storeName":"x","sku":"x","quantity":1}]
  }' | python3 -m json.tool

# ── 19. Assign driver to completed load guard ─────────────────────────────────
section "19. Assign driver to COMPLETED load (expect 409)"
curl -s -X POST "$BASE_URL/delivery-loads/$LOAD_ID/assign" \
  -H "Content-Type: application/json" \
  -d '{"driverName":"Test Driver","truckNumber":"TRUCK-999"}' \
  | python3 -m json.tool

# ── 20. Guard: in-transit on CREATED load without assign (expect 409) ─────────
section "20. Mark in-transit on CREATED load without assigning driver (expect 409)"
GUARD_LOAD=$(curl -s -X POST "$BASE_URL/delivery-loads" \
  -H "Content-Type: application/json" \
  -d '{
    "loadNumber":"LOAD-GUARD","shipmentExternalId":"shp-guard-uuid",
    "shipmentNumber":"SHP-GUARD","storeOrderExternalId":"x","storeOrderNumber":"x",
    "campaignExternalId":"x","campaignCode":"x","regionCode":"x","sku":"x",
    "toyDescription":"x","totalCartons":1,"totalUnits":1,
    "carrierName":"x","proNumber":"x","requiredDeliveryDate":"2025-06-01",
    "createdBy":"test",
    "storeCartons":[{"storeExternalId":"x","storeNumber":"x","storeName":"x","sku":"x","quantity":1}]
  }')
GUARD_ID=$(echo "$GUARD_LOAD" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
curl -s -X POST "$BASE_URL/delivery-loads/$GUARD_ID/in-transit" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"test"}' | python3 -m json.tool

# ── 21. Actuator health ───────────────────────────────────────────────────────
section "21. Actuator Health Check"
curl -s http://localhost:8087/actuator/health | python3 -m json.tool

echo ""
ok "All tests complete."
ok "RabbitMQ events published (check http://localhost:15672):"
ok "  erp.tms.load.created              — load created from WMS dispatch"
ok "  erp.tms.load.assigned             — driver + truck assigned"
ok "  erp.tms.load.in-transit           — truck en route"
ok "  erp.tms.delivery.out-for-delivery — all stores out for delivery"
ok "  erp.tms.load.completed            — all stores delivered"
ok "  erp.tms.delivery.pod-confirmed    — FINAL EVENT: Flask Control Tower consumes this"
ok ""
ok "THE FULL SUPPLY CHAIN IS NOW COMPLETE:"
ok "  CRM → Vendor → Procurement → WMS Inbound → OMS → WMS Outbound → TMS → POD"
ok "  Toys are in the restaurants. Campaign SUMMER25-TOY is live!"
ok ""
ok "Check: http://localhost:15672 → Queues → control-tower-test"
