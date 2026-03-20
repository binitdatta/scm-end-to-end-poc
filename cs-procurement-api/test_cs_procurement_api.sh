#!/bin/bash
# =============================================================================
# cs-procurement-api — curl test script
# Full PO + invoice lifecycle:
#   1.  List seeded POs
#   2.  Get PO by externalId
#   3.  Get PO audit events
#   4.  Create a new PO from scratch (DRAFT)
#   5.  Approve PO         → erp.procurement.po.approved
#   6.  Send to vendor     → erp.procurement.po.sent
#   7.  Vendor acknowledges→ erp.procurement.po.acknowledged
#   8.  Mark in production → erp.procurement.po.in-production
#   9.  Mark ready to ship → erp.procurement.po.ready-to-ship  (KEY WMS event)
#   10. Receive invoice    → erp.procurement.invoice.received
#   11. Approve invoice    → erp.procurement.invoice.approved
#   12. Pay invoice        → erp.procurement.invoice.paid
#   13. Complete PO        → erp.procurement.po.completed
#   14. Filter by status
#   15. Guard: approve already-APPROVED PO (expect 409)
#   16. Guard: duplicate PO number (expect 409)
#   17. Drive seeded PO-2025-001 (already APPROVED) forward one step
#   18. Actuator health
#
# Prerequisites:
#   - cs-procurement-api running on localhost:8083
#   - RabbitMQ running on localhost:5672
#   - cs_procurement DB seeded via 01_ddl + 02_seed scripts
#
# Usage: chmod +x test_cs_procurement_api.sh && ./test_cs_procurement_api.sh
# =============================================================================

BASE_URL="http://localhost:8083/api/v1"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; NC='\033[0m'
section() { echo -e "\n${YELLOW}══════════════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}══════════════════════════════════════${NC}"; }
ok()      { echo -e "${GREEN}✔ $1${NC}"; }

# ── 1. List seeded POs ────────────────────────────────────────────────────────
section "1. List all seeded POs"
curl -s "$BASE_URL/purchase-orders" | python3 -m json.tool

# ── 2. Get seeded PO-2025-001 ─────────────────────────────────────────────────
section "2. Get PO-2025-001 (seeded, APPROVED)"
curl -s "$BASE_URL/purchase-orders/po-001-uuid" | python3 -m json.tool

# ── 3. Audit trail ────────────────────────────────────────────────────────────
section "3. PO audit events for PO-2025-001"
curl -s "$BASE_URL/purchase-orders/po-001-uuid/events" | python3 -m json.tool

# ── 4. Create a new PO ────────────────────────────────────────────────────────
section "4. Create new PO (DRAFT) → publishes erp.procurement.po.created"
NEW_PO=$(curl -s -X POST "$BASE_URL/purchase-orders" \
  -H "Content-Type: application/json" \
  -d '{
    "poNumber":             "PO-2025-003",
    "rfqExternalId":        "rfq-003-ext-uuid",
    "rfqNumber":            "RFQ-2025-003",
    "campaignExternalId":   "camp-001-uuid",
    "campaignCode":         "SUMMER25-TOY",
    "awardExternalId":      "award-003-ext-uuid",
    "vendorExternalId":     "vnd-004-uuid",
    "vendorCode":           "VND-TH-001",
    "vendorName":           "Bangkok Fun Factory Co. Ltd.",
    "vendorCountry":        "THAILAND",
    "toyDescription":       "Space Explorer Figure Series — Summer 2025 (250k units)",
    "quantityOrdered":      250000,
    "unitPriceUsd":         0.93,
    "paymentTerms":         "NET30",
    "requiredDeliveryDate": "2025-05-15",
    "estimatedShipDate":    "2025-04-20",
    "incoterms":            "FOB",
    "destinationPort":      "Port of Los Angeles",
    "createdBy":            "procurement.manager",
    "notes":                "Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.",
    "lineItems": [
      {
        "itemCode":     "TOY-SPACE-MIX-001",
        "description":  "Space Explorer Figure Mystery Mix — 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)",
        "quantity":     240000,
        "unitPriceUsd": 0.93
      },
      {
        "itemCode":     "PKG-SURPRISE-BOX-002",
        "description":  "Space-themed surprise packaging box",
        "quantity":     250000,
        "unitPriceUsd": 0.032
      }
    ]
  }')
echo "$NEW_PO" | python3 -m json.tool
PO_ID=$(echo "$NEW_PO" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "New PO externalId: $PO_ID"

# ── 5. Approve PO ─────────────────────────────────────────────────────────────
section "5. Approve PO → publishes erp.procurement.po.approved"
curl -s -X POST "$BASE_URL/purchase-orders/$PO_ID/approve" \
  -H "Content-Type: application/json" \
  -d '{"approvedBy":"procurement.director","notes":"Budget confirmed. Toy specs verified. Approved."}' \
  | python3 -m json.tool

# ── 6. Send to vendor ─────────────────────────────────────────────────────────
section "6. Send to vendor → publishes erp.procurement.po.sent"
curl -s -X POST "$BASE_URL/purchase-orders/$PO_ID/send" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"procurement.manager","notes":"PO emailed and uploaded to vendor portal."}' \
  | python3 -m json.tool

# ── 7. Vendor acknowledges ────────────────────────────────────────────────────
section "7. Vendor acknowledges PO → publishes erp.procurement.po.acknowledged"
curl -s -X POST "$BASE_URL/purchase-orders/$PO_ID/acknowledge" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"vnd-th-001.portal","notes":"Bangkok Fun Factory confirmed receipt. Production slot reserved."}' \
  | python3 -m json.tool

# ── 8. In production ──────────────────────────────────────────────────────────
section "8. Mark in production → publishes erp.procurement.po.in-production"
curl -s -X POST "$BASE_URL/purchase-orders/$PO_ID/in-production" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"vnd-th-001.portal","notes":"Molds ready. First production run started. ETA 35 days."}' \
  | python3 -m json.tool

# ── 9. Ready to ship — KEY WMS EVENT ─────────────────────────────────────────
section "9. Ready to ship → publishes erp.procurement.po.ready-to-ship (WMS trigger)"
curl -s -X POST "$BASE_URL/purchase-orders/$PO_ID/ready-to-ship" \
  -H "Content-Type: application/json" \
  -d '{
    "triggeredBy":       "vnd-th-001.portal",
    "estimatedShipDate": "2025-04-20",
    "notes":             "All 250k units QC passed. Loaded on vessel MSC AURORA. ETA LAX 2025-05-05."
  }' | python3 -m json.tool
ok "KEY EVENT: erp.procurement.po.ready-to-ship — WMS Inbound will create ASN from this"

# ── 10. Receive invoice ───────────────────────────────────────────────────────
section "10. Receive vendor invoice → publishes erp.procurement.invoice.received"
INV=$(curl -s -X POST "$BASE_URL/purchase-orders/$PO_ID/invoices" \
  -H "Content-Type: application/json" \
  -d '{
    "invoiceNumber":    "INV-TH-2025-0042",
    "invoiceAmountUsd": 232500.00,
    "taxAmountUsd":     0.00,
    "invoiceDate":      "2025-04-20",
    "dueDate":          "2025-05-20",
    "notes":            "Final invoice for PO-2025-003. 250,000 Space Explorer figures. Payment due NET30."
  }')
echo "$INV" | python3 -m json.tool
INV_ID=$(echo "$INV" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "Invoice externalId: $INV_ID"

# ── 11. Approve invoice ───────────────────────────────────────────────────────
section "11. Approve invoice → publishes erp.procurement.invoice.approved"
curl -s -X POST "$BASE_URL/invoices/$INV_ID/approve" \
  -H "Content-Type: application/json" \
  -d '{"approvedBy":"ap.manager","notes":"Invoice matches PO amount. 3-way match complete."}' \
  | python3 -m json.tool

# ── 12. Pay invoice ───────────────────────────────────────────────────────────
section "12. Pay invoice → publishes erp.procurement.invoice.paid"
curl -s -X POST "$BASE_URL/invoices/$INV_ID/pay" \
  -H "Content-Type: application/json" \
  -d '{"paidBy":"treasury","notes":"Wire transfer initiated. Reference: TRF-2025-0891."}' \
  | python3 -m json.tool

# ── 13. Complete PO ───────────────────────────────────────────────────────────
section "13. Complete PO → publishes erp.procurement.po.completed"
curl -s -X POST "$BASE_URL/purchase-orders/$PO_ID/complete" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"procurement.manager","notes":"All toys received at DC. Invoice paid. PO closed."}' \
  | python3 -m json.tool

# ── 14. Filter by status ──────────────────────────────────────────────────────
section "14. Filter POs by status=DRAFT"
curl -s "$BASE_URL/purchase-orders/status/DRAFT" | python3 -m json.tool

section "14b. Filter POs by status=COMPLETED"
curl -s "$BASE_URL/purchase-orders/status/COMPLETED" | python3 -m json.tool

# ── 15. Guard: invalid state transition ───────────────────────────────────────
section "15. Attempt to approve already-COMPLETED PO (expect 409)"
curl -s -X POST "$BASE_URL/purchase-orders/$PO_ID/approve" \
  -H "Content-Type: application/json" \
  -d '{"approvedBy":"test"}' | python3 -m json.tool

# ── 16. Guard: duplicate PO number ───────────────────────────────────────────
section "16. Attempt duplicate PO number (expect 409)"
curl -s -X POST "$BASE_URL/purchase-orders" \
  -H "Content-Type: application/json" \
  -d '{
    "poNumber":"PO-2025-003","rfqExternalId":"x","rfqNumber":"x",
    "campaignExternalId":"x","campaignCode":"x","awardExternalId":"award-dup-uuid",
    "vendorExternalId":"x","vendorCode":"x","vendorName":"x","vendorCountry":"CHINA",
    "toyDescription":"dup","quantityOrdered":1,"unitPriceUsd":1.00,
    "requiredDeliveryDate":"2025-12-31","createdBy":"test"
  }' | python3 -m json.tool

# ── 17. Drive seeded PO-2025-001 forward ─────────────────────────────────────
section "17. Drive seeded PO-2025-001 (APPROVED) → SENT_TO_VENDOR"
curl -s -X POST "$BASE_URL/purchase-orders/po-001-uuid/send" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"procurement.manager","notes":"PO transmitted to Ho Chi Minh Playthings via EDI."}' \
  | python3 -m json.tool

# ── 18. Full audit trail ──────────────────────────────────────────────────────
section "18. Full audit trail for new PO"
curl -s "$BASE_URL/purchase-orders/$PO_ID/events" | python3 -m json.tool

# ── 19. Actuator health ───────────────────────────────────────────────────────
section "19. Actuator Health Check"
curl -s http://localhost:8083/actuator/health | python3 -m json.tool

echo ""
ok "All tests complete."
ok "RabbitMQ events published (check http://localhost:15672):"
ok "  erp.procurement.po.created       — new PO drafted"
ok "  erp.procurement.po.approved      — PO budget cleared"
ok "  erp.procurement.po.sent          — PO transmitted to vendor"
ok "  erp.procurement.po.acknowledged  — vendor confirmed"
ok "  erp.procurement.po.in-production — toys being manufactured"
ok "  erp.procurement.po.ready-to-ship — KEY: WMS inbound creates ASN from this"
ok "  erp.procurement.invoice.received — vendor invoice arrived"
ok "  erp.procurement.invoice.approved — 3-way match complete"
ok "  erp.procurement.invoice.paid     — wire transfer sent"
ok "  erp.procurement.po.completed     — PO fully closed"
