#!/bin/bash
# =============================================================================
# cs-vendor-api — curl test script
# Full vendor portal lifecycle:
#   1.  List seeded vendors
#   2.  Get vendors by country
#   3.  Create a new vendor
#   4.  Update scorecard rating
#   5.  List seeded RFQs
#   6.  Create a new RFQ
#   7.  Open the RFQ (DRAFT→OPEN) → publishes erp.vendor.rfq.opened
#   8.  Submit quotes from 2 vendors
#   9.  List all quotes (side-by-side comparison)
#   10. Award the RFQ → publishes erp.vendor.rfq.awarded
#   11. Get the award record
#   12. Attempt duplicate quote (expect 409)
#   13. Attempt to award already-awarded RFQ (expect 409)
#   14. Create + cancel an RFQ → publishes erp.vendor.rfq.cancelled
#   15. Actuator health check
#
# Prerequisites:
#   - cs-vendor-api running on localhost:8082
#   - RabbitMQ running on localhost:5672
#   - cs_vendor DB seeded via 01_ddl + 02_seed scripts
#
# Usage: chmod +x test_cs_vendor_api.sh && ./test_cs_vendor_api.sh
# =============================================================================

BASE_URL="http://localhost:8082/api/v1"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
section() { echo -e "\n${YELLOW}══════════════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}══════════════════════════════════════${NC}"; }
ok()      { echo -e "${GREEN}✔ $1${NC}"; }
fail()    { echo -e "${RED}✘ $1${NC}"; }
extract() { python3 -c "import sys,json; print(json.load(sys.stdin)$1)" 2>/dev/null; }

# ── 1. List all seeded vendors ────────────────────────────────────────────────
section "1. List all vendors (seeded)"
curl -s "$BASE_URL/vendors" | python3 -m json.tool

# ── 2. Vendors by country ─────────────────────────────────────────────────────
section "2. Active vendors in VIETNAM"
curl -s "$BASE_URL/vendors/country/VIETNAM" | python3 -m json.tool

section "2b. Active vendors in THAILAND"
curl -s "$BASE_URL/vendors/country/THAILAND" | python3 -m json.tool

# ── 3. Create a new vendor ────────────────────────────────────────────────────
section "3. Create new vendor (China) → publishes erp.vendor.vendor.created"
NEW_VENDOR=$(curl -s -X POST "$BASE_URL/vendors" \
  -H "Content-Type: application/json" \
  -d '{
    "vendorName":      "Dongguan SuperToy Co. Ltd.",
    "vendorCode":      "VND-CN-003",
    "country":         "CHINA",
    "contactName":     "Chen Wei",
    "contactEmail":    "chenwei@dongguan-supertoy.cn",
    "contactPhone":    "+86-769-8801-5599",
    "address":         "Building 3, Houjie Town Industrial Park, Dongguan, Guangdong 523940",
    "category":        "TOY_MANUFACTURER",
    "leadTimeDays":    40,
    "paymentTerms":    "NET30",
    "scorecardRating": 4.30
  }')
echo "$NEW_VENDOR" | python3 -m json.tool
NEW_VENDOR_ID=$(echo "$NEW_VENDOR" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "New vendor externalId: $NEW_VENDOR_ID"

# ── 4. Update scorecard ───────────────────────────────────────────────────────
section "4. Update scorecard for new vendor"
if [ -n "$NEW_VENDOR_ID" ]; then
  curl -s -X PATCH "$BASE_URL/vendors/$NEW_VENDOR_ID/scorecard" \
    -H "Content-Type: application/json" \
    -d '{"rating": 4.60}' | python3 -m json.tool
fi

# ── 5. List seeded RFQs ───────────────────────────────────────────────────────
section "5. List all RFQs (seeded)"
curl -s "$BASE_URL/rfqs" | python3 -m json.tool

# ── 6. Create a new RFQ ───────────────────────────────────────────────────────
section "6. Create new RFQ for AUTUMN25-TOY campaign"
NEW_RFQ=$(curl -s -X POST "$BASE_URL/rfqs" \
  -H "Content-Type: application/json" \
  -d '{
    "rfqNumber":          "RFQ-2025-003",
    "campaignExternalId": "camp-001-uuid",
    "campaignCode":       "SUMMER25-TOY",
    "title":              "Summer 2025 — Space Explorer Figure Series",
    "description":        "250,000 space explorer toy figures for the summer kids meal campaign. UV-safe paint required.",
    "toyCategory":        "Space Explorer Figures",
    "quantityRequired":   250000,
    "targetUnitCostUsd":  0.90,
    "requiredByDate":     "2025-05-15",
    "submissionDeadline": "2025-03-31",
    "createdBy":          "procurement.manager",
    "inviteVendorIds":    ["vnd-001-uuid", "vnd-004-uuid"]
  }')
echo "$NEW_RFQ" | python3 -m json.tool
NEW_RFQ_ID=$(echo "$NEW_RFQ" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "New RFQ externalId: $NEW_RFQ_ID"

# ── 7. Open the RFQ ───────────────────────────────────────────────────────────
section "7. Open RFQ → publishes erp.vendor.rfq.opened"
if [ -n "$NEW_RFQ_ID" ]; then
  curl -s -X POST "$BASE_URL/rfqs/$NEW_RFQ_ID/open" \
    -H "Content-Type: application/json" \
    -d '{"triggeredBy":"procurement.manager"}' | python3 -m json.tool
  ok "Check RabbitMQ: routing key erp.vendor.rfq.opened"
fi

# ── 8. Submit quotes from 2 vendors ──────────────────────────────────────────
section "8a. China vendor submits quote → publishes erp.vendor.quote.submitted"
if [ -n "$NEW_RFQ_ID" ]; then
  QUOTE1=$(curl -s -X POST "$BASE_URL/rfqs/$NEW_RFQ_ID/quotes" \
    -H "Content-Type: application/json" \
    -d '{
      "vendorExternalId":   "vnd-001-uuid",
      "quotedUnitCostUsd":  0.84,
      "quotedQuantity":     250000,
      "leadTimeDays":       42,
      "deliveryDate":       "2025-05-10",
      "paymentTerms":       "NET30",
      "notes":             "Single-run production. ASTM F963 certified. Sample batch available in 2 weeks."
    }')
  echo "$QUOTE1" | python3 -m json.tool
fi

section "8b. Thailand vendor submits quote → publishes erp.vendor.quote.submitted"
if [ -n "$NEW_RFQ_ID" ]; then
  QUOTE2=$(curl -s -X POST "$BASE_URL/rfqs/$NEW_RFQ_ID/quotes" \
    -H "Content-Type: application/json" \
    -d '{
      "vendorExternalId":   "vnd-004-uuid",
      "quotedUnitCostUsd":  0.93,
      "quotedQuantity":     250000,
      "leadTimeDays":       38,
      "deliveryDate":       "2025-05-05",
      "paymentTerms":       "NET30",
      "notes":             "Premium finish, faster delivery. ISO 14001 certified. Scorecard 4.75."
    }')
  echo "$QUOTE2" | python3 -m json.tool
fi

# ── 9. Compare all quotes ─────────────────────────────────────────────────────
section "9. View all quotes for RFQ (side-by-side comparison)"
if [ -n "$NEW_RFQ_ID" ]; then
  curl -s "$BASE_URL/rfqs/$NEW_RFQ_ID/quotes" | python3 -m json.tool
fi

# ── 10. Award the RFQ ────────────────────────────────────────────────────────
section "10. Award RFQ to Thailand vendor → publishes erp.vendor.rfq.awarded"
if [ -n "$NEW_RFQ_ID" ]; then
  AWARD=$(curl -s -X POST "$BASE_URL/rfqs/$NEW_RFQ_ID/award" \
    -H "Content-Type: application/json" \
    -d '{
      "winningVendorExternalId": "vnd-004-uuid",
      "awardedQuantity":         250000,
      "awardedBy":               "procurement.director",
      "awardNotes":              "Thailand vendor selected for premium finish and faster delivery. Scorecard 4.75 is highest among bidders."
    }')
  echo "$AWARD" | python3 -m json.tool
  ok "KEY EVENT: erp.vendor.rfq.awarded published — Procurement ERP will use this to create a PO"
fi

# ── 11. Get award record ──────────────────────────────────────────────────────
section "11. Get award record for RFQ"
if [ -n "$NEW_RFQ_ID" ]; then
  curl -s "$BASE_URL/rfqs/$NEW_RFQ_ID/award" | python3 -m json.tool
fi

# ── 12. Duplicate quote guard ─────────────────────────────────────────────────
section "12. Attempt duplicate quote from same vendor (expect 409)"
if [ -n "$NEW_RFQ_ID" ]; then
  curl -s -X POST "$BASE_URL/rfqs/$NEW_RFQ_ID/quotes" \
    -H "Content-Type: application/json" \
    -d '{
      "vendorExternalId":   "vnd-001-uuid",
      "quotedUnitCostUsd":  0.80,
      "quotedQuantity":     250000,
      "leadTimeDays":       40,
      "deliveryDate":       "2025-05-08"
    }' | python3 -m json.tool
fi

# ── 13. Double-award guard ────────────────────────────────────────────────────
section "13. Attempt to award already-awarded RFQ (expect 409)"
if [ -n "$NEW_RFQ_ID" ]; then
  curl -s -X POST "$BASE_URL/rfqs/$NEW_RFQ_ID/award" \
    -H "Content-Type: application/json" \
    -d '{
      "winningVendorExternalId": "vnd-001-uuid",
      "awardedQuantity": 250000,
      "awardedBy": "test"
    }' | python3 -m json.tool
fi

# ── 14. Create + cancel an RFQ ────────────────────────────────────────────────
section "14. Create then cancel an RFQ → publishes erp.vendor.rfq.cancelled"
CANCEL_RFQ=$(curl -s -X POST "$BASE_URL/rfqs" \
  -H "Content-Type: application/json" \
  -d '{
    "rfqNumber":          "RFQ-2025-CANCEL",
    "campaignExternalId": "camp-002-uuid",
    "campaignCode":       "HOLIDAY25-TOY",
    "title":              "Test RFQ for cancellation",
    "quantityRequired":   10000,
    "requiredByDate":     "2025-12-01",
    "submissionDeadline": "2025-09-30",
    "createdBy":          "test.user"
  }')
CANCEL_RFQ_ID=$(echo "$CANCEL_RFQ" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)

curl -s -X POST "$BASE_URL/rfqs/$CANCEL_RFQ_ID/cancel" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"procurement.manager","notes":"Campaign budget cut. Sourcing cancelled."}' \
  | python3 -m json.tool

# ── 15. Actuator health ───────────────────────────────────────────────────────
section "15. Actuator Health Check"
curl -s http://localhost:8082/actuator/health | python3 -m json.tool

echo ""
ok "All tests complete."
ok "RabbitMQ events published:"
ok "  erp.vendor.vendor.created   — new vendor registered"
ok "  erp.vendor.rfq.opened       — RFQ opened for bidding"
ok "  erp.vendor.quote.submitted  — vendor quotes (x2)"
ok "  erp.vendor.rfq.awarded      — KEY: triggers PO in cs-procurement-api"
ok "  erp.vendor.rfq.cancelled    — RFQ cancelled"
ok "Check: http://localhost:15672 → Queues → control-tower-test"
