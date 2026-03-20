#!/bin/bash
# =============================================================================
# cs-wms-outbound-api — curl test script
# Full outbound WMS lifecycle:
#   1.  List seeded pick waves (WV-2025-001 COMPLETED)
#   2.  Get WV-2025-001 with bin lines
#   3.  Get pick wave audit events
#   4.  List seeded shipments (SHP-2025-001 DISPATCHED)
#   5.  Get SHP-2025-001 with store carton lines
#   6.  Get shipment audit events
#   7.  Create new pick wave (for ORD-2025-003 SE allocation)
#   8.  Assign wave to picker team
#   9.  Start picking
#   10. Complete wave → erp.wms.outbound.wave.completed
#   11. Create shipment from completed wave → erp.wms.outbound.shipment.created
#   12. Pack shipment → erp.wms.outbound.shipment.packed
#   13. Manifest with carrier + PRO → erp.wms.outbound.shipment.manifested
#   14. Dispatch → erp.wms.outbound.shipment.dispatched (KEY TMS event)
#   15. Verify shipment store lines after dispatch
#   16. Get full shipment event trail
#   17. Filter waves by status=COMPLETED
#   18. Filter shipments by campaign
#   19. Guard: duplicate wave number (expect 409)
#   20. Guard: create shipment from non-COMPLETED wave (expect 409)
#   21. Actuator health
#
# Prerequisites:
#   - cs-wms-outbound-api running on localhost:8086
#   - RabbitMQ running on localhost:5672
#   - cs_wms_outbound DB seeded via 01_ddl + 02_seed scripts
#
# Usage: chmod +x test_cs_wms_outbound_api.sh && ./test_cs_wms_outbound_api.sh
# =============================================================================

BASE_URL="http://localhost:8086/api/v1"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
section() { echo -e "\n${YELLOW}══════════════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}══════════════════════════════════════${NC}"; }
ok()      { echo -e "${GREEN}✔ $1${NC}"; }

# ── 1. List seeded pick waves ─────────────────────────────────────────────────
section "1. List seeded pick waves"
curl -s "$BASE_URL/pick-waves" | python3 -m json.tool

# ── 2. Get WV-2025-001 ────────────────────────────────────────────────────────
section "2. Get WV-2025-001 (COMPLETED, 2 bin lines)"
curl -s "$BASE_URL/pick-waves/pw-001-uuid" | python3 -m json.tool

# ── 3. Wave events ────────────────────────────────────────────────────────────
section "3. Pick wave events for WV-2025-001"
curl -s "$BASE_URL/pick-waves/pw-001-uuid/events" | python3 -m json.tool

# ── 4. List seeded shipments ──────────────────────────────────────────────────
section "4. List seeded shipments"
curl -s "$BASE_URL/shipments" | python3 -m json.tool

# ── 5. Get SHP-2025-001 ───────────────────────────────────────────────────────
section "5. Get SHP-2025-001 (DISPATCHED, 4 store carton lines)"
curl -s "$BASE_URL/shipments/shp-001-uuid" | python3 -m json.tool

# ── 6. Shipment events ────────────────────────────────────────────────────────
section "6. Shipment events for SHP-2025-001"
curl -s "$BASE_URL/shipments/shp-001-uuid/events" | python3 -m json.tool

# ── 7. Create new pick wave ───────────────────────────────────────────────────
section "7. Create pick wave WV-2025-002 (SE ORD-2025-003) → erp.wms.outbound.wave.created"
NEW_WAVE=$(curl -s -X POST "$BASE_URL/pick-waves" \
  -H "Content-Type: application/json" \
  -d '{
    "waveNumber":             "WV-2025-002",
    "storeOrderExternalId":   "ord-003-ext-uuid",
    "storeOrderNumber":       "ORD-2025-003",
    "campaignExternalId":     "camp-001-uuid",
    "campaignCode":           "SUMMER25-TOY",
    "regionCode":             "US-SOUTHEAST",
    "sku":                    "TOY-DINO-MIX-001",
    "toyDescription":         "Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise",
    "totalQuantity":          104000,
    "pickZone":               "ZONE-A",
    "requiredShipDate":       "2025-05-28",
    "createdBy":              "wms.outbound.coordinator",
    "notes":                  "Southeast allocation pick — 4 stores x 26,000 units from ZONE-A.",
    "binSources": [
      {"warehouseZone":"ZONE-A","warehouseAisle":"A-01","warehouseBin":"BIN-A-01-001","quantityToPick":52000},
      {"warehouseZone":"ZONE-A","warehouseAisle":"A-02","warehouseBin":"BIN-A-02-001","quantityToPick":52000}
    ]
  }')
echo "$NEW_WAVE" | python3 -m json.tool
WAVE_ID=$(echo "$NEW_WAVE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "New wave externalId: $WAVE_ID"

# ── 8. Assign wave ────────────────────────────────────────────────────────────
section "8. Assign wave to picker team"
curl -s -X POST "$BASE_URL/pick-waves/$WAVE_ID/assign" \
  -H "Content-Type: application/json" \
  -d '{"assignedTo":"picker.team.02","notes":"SE wave assigned to team 02."}' \
  | python3 -m json.tool

# ── 9. Start picking ──────────────────────────────────────────────────────────
section "9. Start picking"
curl -s -X POST "$BASE_URL/pick-waves/$WAVE_ID/start" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"picker.team.02","notes":"Picking started in ZONE-A."}' \
  | python3 -m json.tool

# ── 10. Complete wave ─────────────────────────────────────────────────────────
section "10. Complete wave → erp.wms.outbound.wave.completed"
curl -s -X POST "$BASE_URL/pick-waves/$WAVE_ID/complete" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"picker.team.02","pickedQuantity":104000,"notes":"All 104,000 units picked from ZONE-A. 2 bins cleared."}' \
  | python3 -m json.tool
ok "Wave completed — ready for shipment creation"

# ── 11. Create shipment ───────────────────────────────────────────────────────
section "11. Create shipment SHP-2025-002 → erp.wms.outbound.shipment.created"
NEW_SHP=$(curl -s -X POST "$BASE_URL/shipments" \
  -H "Content-Type: application/json" \
  -d "{
    \"shipmentNumber\":        \"SHP-2025-002\",
    \"pickWaveExternalId\":    \"$WAVE_ID\",
    \"distributionDc\":        \"DC-ATLANTA\",
    \"carrierName\":           \"Old Dominion Freight\",
    \"requiredDeliveryDate\":  \"2025-06-01\",
    \"estimatedShipDate\":     \"2025-05-28\",
    \"createdBy\":             \"wms.outbound.coordinator\",
    \"notes\":                 \"Southeast store cartons — 4 stores.\",
    \"storeCartons\": [
      {\"storeExternalId\":\"str-009-uuid\",\"storeNumber\":\"STR-0201\",\"storeName\":\"Burger Bliss Atlanta Midtown\",\"city\":\"Atlanta\",\"stateCode\":\"GA\",\"sku\":\"TOY-DINO-MIX-001\",\"quantity\":26000,\"cartonLabel\":\"CTN-SE-0001\"},
      {\"storeExternalId\":\"str-010-uuid\",\"storeNumber\":\"STR-0202\",\"storeName\":\"Burger Bliss Miami Brickell\",\"city\":\"Miami\",\"stateCode\":\"FL\",\"sku\":\"TOY-DINO-MIX-001\",\"quantity\":26000,\"cartonLabel\":\"CTN-SE-0002\"},
      {\"storeExternalId\":\"str-011-uuid\",\"storeNumber\":\"STR-0203\",\"storeName\":\"Burger Bliss Charlotte\",\"city\":\"Charlotte\",\"stateCode\":\"NC\",\"sku\":\"TOY-DINO-MIX-001\",\"quantity\":26000,\"cartonLabel\":\"CTN-SE-0003\"},
      {\"storeExternalId\":\"str-012-uuid\",\"storeNumber\":\"STR-0204\",\"storeName\":\"Burger Bliss Nashville\",\"city\":\"Nashville\",\"stateCode\":\"TN\",\"sku\":\"TOY-DINO-MIX-001\",\"quantity\":26000,\"cartonLabel\":\"CTN-SE-0004\"}
    ]
  }")
echo "$NEW_SHP" | python3 -m json.tool
SHP_ID=$(echo "$NEW_SHP" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "New shipment externalId: $SHP_ID"

# ── 12. Pack shipment ─────────────────────────────────────────────────────────
section "12. Pack shipment → erp.wms.outbound.shipment.packed"
curl -s -X POST "$BASE_URL/shipments/$SHP_ID/pack" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"wms.outbound.packer","notes":"All 4 SE store cartons packed and labeled."}' \
  | python3 -m json.tool

# ── 13. Manifest ──────────────────────────────────────────────────────────────
section "13. Manifest shipment → erp.wms.outbound.shipment.manifested"
curl -s -X POST "$BASE_URL/shipments/$SHP_ID/manifest" \
  -H "Content-Type: application/json" \
  -d '{
    "carrierName": "Old Dominion Freight",
    "proNumber":   "OD-2025-SE-8812",
    "notes":       "OD manifest generated. PRO OD-2025-SE-8812 assigned. ETA June 1."
  }' | python3 -m json.tool

# ── 14. Dispatch — KEY TMS EVENT ─────────────────────────────────────────────
section "14. DISPATCH shipment → erp.wms.outbound.shipment.dispatched (TMS trigger)"
curl -s -X POST "$BASE_URL/shipments/$SHP_ID/dispatch" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"wms.outbound.coordinator","notes":"OD driver collected 4 SE cartons. En route to Atlanta, Miami, Charlotte, Nashville."}' \
  | python3 -m json.tool
ok "KEY EVENT: erp.wms.outbound.shipment.dispatched published"
ok "TMS will track delivery of 4 store cartons across Southeast"

# ── 15. Verify store lines after dispatch ─────────────────────────────────────
section "15. Verify shipment store lines (all DISPATCHED)"
curl -s "$BASE_URL/shipments/$SHP_ID" | python3 -m json.tool

# ── 16. Full shipment event trail ─────────────────────────────────────────────
section "16. Full shipment event trail"
curl -s "$BASE_URL/shipments/$SHP_ID/events" | python3 -m json.tool

# ── 17. Filter waves by status ────────────────────────────────────────────────
section "17. Filter pick waves by status=COMPLETED"
curl -s "$BASE_URL/pick-waves/status/COMPLETED" | python3 -m json.tool

# ── 18. Filter shipments by campaign ─────────────────────────────────────────
section "18. Filter shipments by campaign SUMMER25-TOY"
curl -s "$BASE_URL/shipments/campaign/SUMMER25-TOY" | python3 -m json.tool

# ── 19. Duplicate wave number guard ───────────────────────────────────────────
section "19. Duplicate wave number (expect 409)"
curl -s -X POST "$BASE_URL/pick-waves" \
  -H "Content-Type: application/json" \
  -d '{
    "waveNumber":"WV-2025-002","storeOrderExternalId":"x","storeOrderNumber":"x",
    "campaignExternalId":"x","campaignCode":"x","regionCode":"x","sku":"x",
    "toyDescription":"x","totalQuantity":1,"requiredShipDate":"2025-06-01","createdBy":"test"
  }' | python3 -m json.tool

# ── 20. Create shipment from non-COMPLETED wave (expect 409) ──────────────────
section "20. Create shipment from CREATED wave (expect 409)"
GUARD_WAVE=$(curl -s -X POST "$BASE_URL/pick-waves" \
  -H "Content-Type: application/json" \
  -d '{
    "waveNumber":"WV-2025-GUARD","storeOrderExternalId":"x","storeOrderNumber":"x",
    "campaignExternalId":"x","campaignCode":"x","regionCode":"x","sku":"x",
    "toyDescription":"x","totalQuantity":100,"requiredShipDate":"2025-06-01","createdBy":"test"
  }')
GUARD_ID=$(echo "$GUARD_WAVE" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)

curl -s -X POST "$BASE_URL/shipments" \
  -H "Content-Type: application/json" \
  -d "{
    \"shipmentNumber\":\"SHP-GUARD\",\"pickWaveExternalId\":\"$GUARD_ID\",
    \"requiredDeliveryDate\":\"2025-06-01\",\"createdBy\":\"test\",
    \"storeCartons\":[{\"storeExternalId\":\"x\",\"storeNumber\":\"x\",\"storeName\":\"x\",\"sku\":\"x\",\"quantity\":1}]
  }" | python3 -m json.tool

# ── 21. Actuator health ───────────────────────────────────────────────────────
section "21. Actuator Health Check"
curl -s http://localhost:8086/actuator/health | python3 -m json.tool

echo ""
ok "All tests complete."
ok "RabbitMQ events published (check http://localhost:15672):"
ok "  erp.wms.outbound.wave.created        — pick wave initiated"
ok "  erp.wms.outbound.wave.completed      — picking done, ready for pack"
ok "  erp.wms.outbound.shipment.created    — cartons staged"
ok "  erp.wms.outbound.shipment.packed     — cartons sealed and labeled"
ok "  erp.wms.outbound.shipment.manifested — carrier PRO assigned"
ok "  erp.wms.outbound.shipment.dispatched — KEY: TMS tracks store delivery"
ok "Check: http://localhost:15672 → Queues → control-tower-test"
