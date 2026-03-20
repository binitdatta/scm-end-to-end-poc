#!/bin/bash
# =============================================================================
# cs-crm-api — curl test script
# Runs the full campaign lifecycle end-to-end:
#   1. Create customers
#   2. Create campaign
#   3. Launch campaign  → RabbitMQ: erp.crm.campaign.launched
#   4. Pause campaign   → RabbitMQ: erp.crm.campaign.paused
#   5. Complete campaign→ RabbitMQ: erp.crm.campaign.completed
#   6. Get status / list all
#
# Prerequisites:
#   - cs-crm-api running on localhost:8081
#   - RabbitMQ running on localhost:5672
#   - cs_crm DB seeded via 01_ddl and 02_seed scripts
#
# Usage:  chmod +x test_cs_crm_api.sh && ./test_cs_crm_api.sh
# =============================================================================

BASE_URL="http://localhost:8081/api/v1"

# Colour helpers
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

section()  { echo -e "\n${YELLOW}══════════════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}══════════════════════════════════════${NC}"; }
ok()       { echo -e "${GREEN}✔ $1${NC}"; }
fail()     { echo -e "${RED}✘ $1${NC}"; }

# ── 1. Create Customers ───────────────────────────────────────────────────────
section "1. Create Customers"

echo "→ Creating PLATINUM customer..."
CUST1=$(curl -s -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Jessica",
    "lastName":  "Park",
    "email":     "jessica.park@test.com",
    "phone":     "312-555-9001",
    "tier":      "PLATINUM"
  }')
echo "$CUST1" | python3 -m json.tool 2>/dev/null || echo "$CUST1"
CUST1_ID=$(echo "$CUST1" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "Customer 1 externalId: $CUST1_ID"

echo ""
echo "→ Creating GOLD customer..."
CUST2=$(curl -s -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Marcus",
    "lastName":  "Lee",
    "email":     "marcus.lee@test.com",
    "phone":     "773-555-9002",
    "tier":      "GOLD"
  }')
echo "$CUST2" | python3 -m json.tool 2>/dev/null || echo "$CUST2"
CUST2_ID=$(echo "$CUST2" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "Customer 2 externalId: $CUST2_ID"

# ── 2. List All Customers ─────────────────────────────────────────────────────
section "2. List All Customers"
curl -s -X GET "$BASE_URL/customers" | python3 -m json.tool 2>/dev/null

# ── 3. Get Single Customer ────────────────────────────────────────────────────
section "3. Get Customer by externalId"
if [ -n "$CUST1_ID" ]; then
  curl -s -X GET "$BASE_URL/customers/$CUST1_ID" | python3 -m json.tool 2>/dev/null
else
  echo "Skipping — no externalId captured (check python3 is available)"
fi

# ── 4. Create Campaign ────────────────────────────────────────────────────────
section "4. Create Campaign (DRAFT)"
CAMP=$(curl -s -X POST "$BASE_URL/campaigns" \
  -H "Content-Type: application/json" \
  -d '{
    "campaignName":  "Autumn Adventure 2025",
    "campaignCode":  "AUTUMN25-TOY",
    "description":   "Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.",
    "campaignType":  "TOY_SURPRISE",
    "budgetUsd":     850000.00,
    "startDate":     "2025-09-01",
    "endDate":       "2025-11-30",
    "targetRegion":  "US-MIDWEST",
    "createdBy":     "campaign.manager"
  }')
echo "$CAMP" | python3 -m json.tool 2>/dev/null || echo "$CAMP"
CAMP_ID=$(echo "$CAMP" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "Campaign externalId: $CAMP_ID"

# ── 5. List All Campaigns ─────────────────────────────────────────────────────
section "5. List All Campaigns"
curl -s -X GET "$BASE_URL/campaigns" | python3 -m json.tool 2>/dev/null

# ── 6. Get Single Campaign ────────────────────────────────────────────────────
section "6. Get Campaign by externalId"
if [ -n "$CAMP_ID" ]; then
  curl -s -X GET "$BASE_URL/campaigns/$CAMP_ID" | python3 -m json.tool 2>/dev/null
fi

# ── 7. Launch Campaign ────────────────────────────────────────────────────────
section "7. Launch Campaign → publishes erp.crm.campaign.launched"
if [ -n "$CAMP_ID" ]; then
  curl -s -X POST "$BASE_URL/campaigns/$CAMP_ID/launch" \
    -H "Content-Type: application/json" \
    -d '{
      "triggeredBy": "campaign.manager",
      "notes":       "All vendor contracts signed. Toy production confirmed. Launch approved."
    }' | python3 -m json.tool 2>/dev/null
  ok "Check RabbitMQ management UI: http://localhost:15672 → Exchanges → erp.topic.exchange"
else
  fail "No campaign ID — skipping launch"
fi

# ── 8. Pause Campaign ─────────────────────────────────────────────────────────
section "8. Pause Campaign → publishes erp.crm.campaign.paused"
if [ -n "$CAMP_ID" ]; then
  curl -s -X POST "$BASE_URL/campaigns/$CAMP_ID/pause" \
    -H "Content-Type: application/json" \
    -d '{
      "triggeredBy": "ops.manager",
      "notes":       "Supply delay from Vietnam vendor. Pausing for 2 weeks."
    }' | python3 -m json.tool 2>/dev/null
fi

# ── 9. Re-launch from PAUSED (should fail — only DRAFT → ACTIVE allowed) ──────
section "9. Attempt to launch a PAUSED campaign (expect 409 CONFLICT)"
if [ -n "$CAMP_ID" ]; then
  curl -s -X POST "$BASE_URL/campaigns/$CAMP_ID/launch" \
    -H "Content-Type: application/json" \
    -d '{"triggeredBy":"test","notes":"should fail"}' | python3 -m json.tool 2>/dev/null
fi

# ── 10. Complete Campaign ─────────────────────────────────────────────────────
section "10. Complete Campaign → publishes erp.crm.campaign.completed"
if [ -n "$CAMP_ID" ]; then
  curl -s -X POST "$BASE_URL/campaigns/$CAMP_ID/complete" \
    -H "Content-Type: application/json" \
    -d '{
      "triggeredBy": "campaign.manager",
      "notes":       "Campaign ran full season. All toys distributed to stores."
    }' | python3 -m json.tool 2>/dev/null
fi

# ── 11. Verify Final Status ───────────────────────────────────────────────────
section "11. Verify Final Campaign Status"
if [ -n "$CAMP_ID" ]; then
  curl -s -X GET "$BASE_URL/campaigns/$CAMP_ID" | python3 -m json.tool 2>/dev/null
fi

# ── 12. Duplicate customer (expect 409) ───────────────────────────────────────
section "12. Duplicate customer email (expect 409 CONFLICT)"
curl -s -X POST "$BASE_URL/customers" \
  -H "Content-Type: application/json" \
  -d '{
    "firstName": "Jessica",
    "lastName":  "Park",
    "email":     "jessica.park@test.com",
    "tier":      "STANDARD"
  }' | python3 -m json.tool 2>/dev/null

# ── 13. Actuator Health ───────────────────────────────────────────────────────
section "13. Actuator Health Check"
curl -s http://localhost:8081/actuator/health | python3 -m json.tool 2>/dev/null

echo ""
ok "All tests complete. Check RabbitMQ UI at http://localhost:15672 (guest/guest)"
ok "Exchange: erp.topic.exchange | Routing keys: erp.crm.campaign.* and erp.crm.customer.created"
