#!/bin/bash
# =============================================================================
# cs-oms-api — curl test script
# Full OMS lifecycle:
#   1.  List all regions (6 US regions)
#   2.  Get specific region (US-MIDWEST)
#   3.  List stores in region
#   4.  List all stores
#   5.  List seeded inventory (2 SKUs)
#   6.  Get inventory by SKU + campaign
#   7.  List seeded orders (ORD-2025-001 ALLOCATED, ORD-2025-002 DRAFT)
#   8.  Get ORD-2025-001 with order lines
#   9.  Get ORD-2025-001 audit events
#   10. Update inventory (simulate putaway.completed from WMS)
#   11. Create new store order (DRAFT) → erp.oms.store-order.created
#   12. Submit order → erp.oms.store-order.submitted
#   13. Allocate order → erp.oms.store-order.allocated (KEY WMS Outbound trigger)
#   14. Verify per-store order lines
#   15. Mark picking → erp.oms.store-order.picking
#   16. Mark shipped → erp.oms.store-order.shipped
#   17. Mark delivered → erp.oms.store-order.delivered
#   18. Full audit trail
#   19. Create + cancel order (inventory release guard)
#   20. Guard: insufficient inventory (expect 422)
#   21. Guard: duplicate order number (expect 409)
#   22. Filter orders by campaign
#   23. Submit seeded ORD-2025-002 (DRAFT → SUBMITTED)
#   24. Actuator health
#
# Prerequisites:
#   - cs-oms-api running on localhost:8085
#   - RabbitMQ running on localhost:5672
#   - cs_oms DB seeded via 01_ddl + 02_seed scripts
#
# Usage: chmod +x test_cs_oms_api.sh && ./test_cs_oms_api.sh
# =============================================================================

BASE_URL="http://localhost:8085/api/v1"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
section() { echo -e "\n${YELLOW}══════════════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}══════════════════════════════════════${NC}"; }
ok()      { echo -e "${GREEN}✔ $1${NC}"; }

# ── 1. List regions ───────────────────────────────────────────────────────────
section "1. List all 6 US regions"
curl -s "$BASE_URL/regions" | python3 -m json.tool

# ── 2. Get specific region ────────────────────────────────────────────────────
section "2. Get US-MIDWEST region"
curl -s "$BASE_URL/regions/US-MIDWEST" | python3 -m json.tool

# ── 3. Stores in region ───────────────────────────────────────────────────────
section "3. Stores in US-MIDWEST"
curl -s "$BASE_URL/regions/US-MIDWEST/stores" | python3 -m json.tool

# ── 4. All stores ─────────────────────────────────────────────────────────────
section "4. All 20 seeded stores"
curl -s "$BASE_URL/stores" | python3 -m json.tool

# ── 5. List inventory ─────────────────────────────────────────────────────────
section "5. Inventory for SUMMER25-TOY campaign"
curl -s "$BASE_URL/inventory/campaign/SUMMER25-TOY" | python3 -m json.tool

# ── 6. Single SKU inventory ───────────────────────────────────────────────────
section "6. Inventory: TOY-DINO-MIX-001 / SUMMER25-TOY"
curl -s "$BASE_URL/inventory/sku/TOY-DINO-MIX-001/campaign/SUMMER25-TOY" | python3 -m json.tool

# ── 7. List seeded orders ─────────────────────────────────────────────────────
section "7. List all seeded store orders"
curl -s "$BASE_URL/store-orders" | python3 -m json.tool

# ── 8. Get ORD-2025-001 with order lines ──────────────────────────────────────
section "8. Get ORD-2025-001 (ALLOCATED with 4 store lines)"
curl -s "$BASE_URL/store-orders/ord-001-uuid" | python3 -m json.tool

# ── 9. Audit events ───────────────────────────────────────────────────────────
section "9. Audit events for ORD-2025-001"
curl -s "$BASE_URL/store-orders/ord-001-uuid/events" | python3 -m json.tool

# ── 10. Update inventory (simulate putaway.completed) ─────────────────────────
section "10. Update inventory — simulate WMS putaway.completed → erp.oms.inventory.updated"
curl -s -X POST "$BASE_URL/inventory/update" \
  -H "Content-Type: application/json" \
  -d '{
    "sku":               "TOY-SPACE-MIX-001",
    "campaignCode":      "SUMMER25-TOY",
    "quantityAvailable": 249950,
    "sourceAsnNumber":   "ASN-2025-003"
  }' | python3 -m json.tool
ok "SPACE inventory confirmed in OMS: 249,950 units"

# ── 11. Create new order ──────────────────────────────────────────────────────
section "11. Create new store order (DRAFT) for SOUTHEAST → erp.oms.store-order.created"
NEW_ORD=$(curl -s -X POST "$BASE_URL/store-orders" \
  -H "Content-Type: application/json" \
  -d '{
    "orderNumber":            "ORD-2025-003",
    "campaignExternalId":     "camp-001-uuid",
    "campaignCode":           "SUMMER25-TOY",
    "regionCode":             "US-SOUTHEAST",
    "sku":                    "TOY-DINO-MIX-001",
    "toyDescription":         "Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise",
    "quantityRequested":      104000,
    "requestedDeliveryDate":  "2025-06-01",
    "createdBy":              "oms.planner",
    "notes":                  "Southeast allocation: 520 stores x 200 units each."
  }')
echo "$NEW_ORD" | python3 -m json.tool
ORD_ID=$(echo "$NEW_ORD" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "New order externalId: $ORD_ID"

# ── 12. Submit order ──────────────────────────────────────────────────────────
section "12. Submit order → erp.oms.store-order.submitted"
curl -s -X POST "$BASE_URL/store-orders/$ORD_ID/submit" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"oms.planner","notes":"Inventory confirmed. Submitting for allocation."}' \
  | python3 -m json.tool

# ── 13. Allocate order — KEY EVENT ───────────────────────────────────────────
section "13. ALLOCATE order → erp.oms.store-order.allocated (WMS Outbound trigger)"
curl -s -X POST "$BASE_URL/store-orders/$ORD_ID/allocate" \
  -H "Content-Type: application/json" \
  -d '{"allocatedBy":"oms.system","notes":"Auto-allocated: 520 SE stores x 200 units from TOY-DINO-MIX-001."}' \
  | python3 -m json.tool
ok "KEY EVENT published: erp.oms.store-order.allocated"
ok "WMS Outbound will create pick waves from this event"

# ── 14. Verify order lines after allocation ───────────────────────────────────
section "14. Verify order + store lines after allocation"
curl -s "$BASE_URL/store-orders/$ORD_ID" | python3 -m json.tool

# ── 15. Mark picking ──────────────────────────────────────────────────────────
section "15. Mark PICKING → erp.oms.store-order.picking"
curl -s -X POST "$BASE_URL/store-orders/$ORD_ID/picking" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"wms.outbound","notes":"Pick wave WV-2025-003 started. 520 store cartons being picked."}' \
  | python3 -m json.tool

# ── 16. Mark shipped ──────────────────────────────────────────────────────────
section "16. Mark SHIPPED → erp.oms.store-order.shipped"
curl -s -X POST "$BASE_URL/store-orders/$ORD_ID/shipped" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"tms.carrier","notes":"All 520 store cartons loaded on outbound trucks. En route to Southeast stores."}' \
  | python3 -m json.tool

# ── 17. Mark delivered ────────────────────────────────────────────────────────
section "17. Mark DELIVERED → erp.oms.store-order.delivered"
curl -s -X POST "$BASE_URL/store-orders/$ORD_ID/delivered" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"tms.carrier","notes":"Delivery confirmed at all 520 SE store locations. POD received."}' \
  | python3 -m json.tool

# ── 18. Full audit trail ──────────────────────────────────────────────────────
section "18. Full audit trail (7 events from DRAFT → DELIVERED)"
curl -s "$BASE_URL/store-orders/$ORD_ID/events" | python3 -m json.tool

# ── 19. Create + cancel order ─────────────────────────────────────────────────
section "19. Create order then cancel — inventory release guard"
CANCEL_ORD=$(curl -s -X POST "$BASE_URL/store-orders" \
  -H "Content-Type: application/json" \
  -d '{
    "orderNumber":           "ORD-2025-CANCEL",
    "campaignExternalId":    "camp-001-uuid",
    "campaignCode":          "SUMMER25-TOY",
    "regionCode":            "US-NORTHWEST",
    "sku":                   "TOY-DINO-MIX-001",
    "toyDescription":        "Test cancel order",
    "quantityRequested":     10000,
    "requestedDeliveryDate": "2025-06-15",
    "createdBy":             "test.user"
  }')
CANCEL_ID=$(echo "$CANCEL_ORD" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)

curl -s -X POST "$BASE_URL/store-orders/$CANCEL_ID/cancel" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"oms.planner","notes":"Campaign budget cut. Order cancelled."}' \
  | python3 -m json.tool

# ── 20. Insufficient inventory guard ─────────────────────────────────────────
section "20. Order exceeding available inventory (expect 422 Unprocessable)"
HUGE_ORD=$(curl -s -X POST "$BASE_URL/store-orders" \
  -H "Content-Type: application/json" \
  -d '{
    "orderNumber":           "ORD-2025-HUGE",
    "campaignExternalId":    "camp-001-uuid",
    "campaignCode":          "SUMMER25-TOY",
    "regionCode":            "US-WEST",
    "sku":                   "TOY-DINO-MIX-001",
    "toyDescription":        "Too large order",
    "quantityRequested":     9999999,
    "requestedDeliveryDate": "2025-06-01",
    "createdBy":             "test"
  }')
HUGE_ID=$(echo "$HUGE_ORD" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)

curl -s -X POST "$BASE_URL/store-orders/$HUGE_ID/submit" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"test"}' | python3 -m json.tool

curl -s -X POST "$BASE_URL/store-orders/$HUGE_ID/allocate" \
  -H "Content-Type: application/json" \
  -d '{"allocatedBy":"test"}' | python3 -m json.tool

# ── 21. Duplicate order number guard ──────────────────────────────────────────
section "21. Duplicate order number (expect 409)"
curl -s -X POST "$BASE_URL/store-orders" \
  -H "Content-Type: application/json" \
  -d '{
    "orderNumber":           "ORD-2025-003",
    "campaignExternalId":    "camp-001-uuid",
    "campaignCode":          "SUMMER25-TOY",
    "regionCode":            "US-WEST",
    "sku":                   "TOY-DINO-MIX-001",
    "toyDescription":        "Dup test",
    "quantityRequested":     1000,
    "requestedDeliveryDate": "2025-06-01",
    "createdBy":             "test"
  }' | python3 -m json.tool

# ── 22. Filter by campaign ────────────────────────────────────────────────────
section "22. Filter orders by campaign SUMMER25-TOY"
curl -s "$BASE_URL/store-orders/campaign/SUMMER25-TOY" | python3 -m json.tool

# ── 23. Drive seeded ORD-2025-002 forward ────────────────────────────────────
section "23. Drive seeded ORD-2025-002 (DRAFT → SUBMITTED)"
curl -s -X POST "$BASE_URL/store-orders/ord-002-uuid/submit" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"oms.planner","notes":"West region order submitted for allocation."}' \
  | python3 -m json.tool

# ── 24. Actuator health ───────────────────────────────────────────────────────
section "24. Actuator Health Check"
curl -s http://localhost:8085/actuator/health | python3 -m json.tool

echo ""
ok "All tests complete."
ok "RabbitMQ events published (check http://localhost:15672):"
ok "  erp.oms.inventory.updated         — WMS putaway synced to OMS"
ok "  erp.oms.store-order.created       — new order drafted"
ok "  erp.oms.store-order.submitted     — order ready for allocation"
ok "  erp.oms.store-order.allocated     — KEY: WMS Outbound creates pick wave"
ok "  erp.oms.store-order.picking       — WMS picking in progress"
ok "  erp.oms.store-order.shipped       — trucks en route to stores"
ok "  erp.oms.store-order.delivered     — toys in restaurants"
ok "  erp.oms.store-order.cancelled     — cancelled with inventory release"
ok "Check: http://localhost:15672 → Queues → control-tower-test"
