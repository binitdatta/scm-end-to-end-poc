#!/bin/bash
# =============================================================================
# cs-wms-inbound-api — curl test script
# Full inbound WMS lifecycle:
#   1.  List seeded ASNs
#   2.  Get ASN-2025-001 (PUTAWAY_COMPLETED, seeded)
#   3.  Get receiving record for ASN-2025-001
#   4.  Get inventory by SKU (seeded data)
#   5.  Get inventory by campaign
#   6.  Get total available quantity
#   7.  Create new ASN (for PO-2025-003) → erp.wms.inbound.asn.created
#   8.  Schedule dock appointment         → erp.wms.inbound.asn.scheduled
#   9.  Mark in transit
#   10. Mark arrived                      → erp.wms.inbound.shipment.arrived
#   11. Receive shipment                  → erp.wms.inbound.receiving.completed
#   12. Complete putaway (2 bins)         → erp.wms.inbound.putaway.completed (KEY)
#   13. Get putaway inventory result
#   14. Full ASN audit trail
#   15. Filter ASNs by status
#   16. Guard: duplicate ASN for same PO (expect 409)
#   17. Guard: receive SCHEDULED ASN (expect 409)
#   18. Drive seeded ASN-2025-002 (SCHEDULED) → ARRIVED
#   19. Actuator health
#
# Prerequisites:
#   - cs-wms-inbound-api running on localhost:8084
#   - RabbitMQ running on localhost:5672
#   - cs_wms_inbound DB seeded via 01_ddl + 02_seed scripts
#
# Usage: chmod +x test_cs_wms_inbound_api.sh && ./test_cs_wms_inbound_api.sh
# =============================================================================

BASE_URL="http://localhost:8084/api/v1"
GREEN='\033[0;32m'; YELLOW='\033[1;33m'; NC='\033[0m'
section() { echo -e "\n${YELLOW}══════════════════════════════════════${NC}"; echo -e "${YELLOW}  $1${NC}"; echo -e "${YELLOW}══════════════════════════════════════${NC}"; }
ok()      { echo -e "${GREEN}✔ $1${NC}"; }

# ── 1. List seeded ASNs ───────────────────────────────────────────────────────
section "1. List all seeded ASNs"
curl -s "$BASE_URL/asns" | python3 -m json.tool

# ── 2. Get ASN-2025-001 ───────────────────────────────────────────────────────
section "2. Get ASN-2025-001 (PUTAWAY_COMPLETED)"
curl -s "$BASE_URL/asns/asn-001-uuid" | python3 -m json.tool

# ── 3. Get receiving record ───────────────────────────────────────────────────
section "3. Receiving record for ASN-2025-001"
curl -s "$BASE_URL/asns/asn-001-uuid/receiving" | python3 -m json.tool

# ── 4. Inventory by SKU ───────────────────────────────────────────────────────
section "4. Inventory by SKU (TOY-DINO-MIX-001)"
curl -s "$BASE_URL/inventory/sku/TOY-DINO-MIX-001" | python3 -m json.tool

# ── 5. Inventory by campaign ──────────────────────────────────────────────────
section "5. Inventory by campaign (SUMMER25-TOY)"
curl -s "$BASE_URL/inventory/campaign/SUMMER25-TOY" | python3 -m json.tool

# ── 6. Total available ────────────────────────────────────────────────────────
section "6. Total available quantity for TOY-DINO-MIX-001"
curl -s "$BASE_URL/inventory/sku/TOY-DINO-MIX-001/available" | python3 -m json.tool

# ── 7. Create new ASN ─────────────────────────────────────────────────────────
section "7. Create new ASN for PO-2025-003 → publishes erp.wms.inbound.asn.created"
NEW_ASN=$(curl -s -X POST "$BASE_URL/asns" \
  -H "Content-Type: application/json" \
  -d '{
    "asnNumber":            "ASN-2025-003",
    "poExternalId":         "po-003-test-uuid",
    "poNumber":             "PO-2025-003",
    "campaignExternalId":   "camp-001-uuid",
    "campaignCode":         "SUMMER25-TOY",
    "vendorExternalId":     "vnd-004-uuid",
    "vendorCode":           "VND-TH-001",
    "vendorName":           "Bangkok Fun Factory Co. Ltd.",
    "vendorCountry":        "THAILAND",
    "sku":                  "TOY-SPACE-MIX-001",
    "toyDescription":       "Space Explorer Figure Series — Summer 2025",
    "expectedQuantity":     250000,
    "carrierName":          "MSC Shipping",
    "trackingNumber":       "MSC-THAI-20250420-7743",
    "originPort":           "Laem Chabang Port, Thailand",
    "destinationPort":      "Port of Los Angeles",
    "incoterms":            "FOB",
    "estimatedArrivalDate": "2025-05-05",
    "dockAppointmentDate":  "2025-05-06T08:00:00",
    "dockDoor":             "DOOR-07",
    "notes":                "MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.",
    "createdBy":            "wms.inbound.coordinator"
  }')
echo "$NEW_ASN" | python3 -m json.tool
ASN_ID=$(echo "$NEW_ASN" | python3 -c "import sys,json; print(json.load(sys.stdin)['data']['externalId'])" 2>/dev/null)
ok "New ASN externalId: $ASN_ID"

# ── 8. Schedule dock ──────────────────────────────────────────────────────────
section "8. Schedule dock appointment → publishes erp.wms.inbound.asn.scheduled"
curl -s -X POST "$BASE_URL/asns/$ASN_ID/schedule" \
  -H "Content-Type: application/json" \
  -d '{
    "dockAppointmentDate": "2025-05-06T08:00:00",
    "dockDoor":            "DOOR-07",
    "triggeredBy":         "wms.inbound.coordinator"
  }' | python3 -m json.tool

# ── 9. Mark in transit ────────────────────────────────────────────────────────
section "9. Mark in transit"
curl -s -X POST "$BASE_URL/asns/$ASN_ID/in-transit" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"msc.tracking.api","notes":"Vessel MSC AURORA departed Laem Chabang. ETA 15 days."}' \
  | python3 -m json.tool

# ── 10. Mark arrived ─────────────────────────────────────────────────────────
section "10. Mark arrived → publishes erp.wms.inbound.shipment.arrived"
curl -s -X POST "$BASE_URL/asns/$ASN_ID/arrived" \
  -H "Content-Type: application/json" \
  -d '{
    "triggeredBy": "wms.inbound.coordinator",
    "arrivalDate": "2025-05-05",
    "notes":       "MSC AURORA docked at Port of Los Angeles, Berth 302."
  }' | python3 -m json.tool

# ── 11. Receive shipment ──────────────────────────────────────────────────────
section "11. Receive shipment → publishes erp.wms.inbound.receiving.completed"
curl -s -X POST "$BASE_URL/asns/$ASN_ID/receive" \
  -H "Content-Type: application/json" \
  -d '{
    "receivedQuantity": 249950,
    "damagedQuantity":  50,
    "rejectedQuantity": 0,
    "receivedBy":       "warehouse.receiver.02",
    "qcPassed":         true,
    "qcNotes":          "50 units with minor paint defects isolated. 249,950 units accepted. All safety certifications verified. QC PASSED."
  }' | python3 -m json.tool

# ── 12. Complete putaway — KEY EVENT ─────────────────────────────────────────
section "12. Complete putaway (2 bins) → publishes erp.wms.inbound.putaway.completed (OMS trigger)"
curl -s -X POST "$BASE_URL/asns/$ASN_ID/putaway" \
  -H "Content-Type: application/json" \
  -d '{
    "binAllocations": [
      {
        "warehouseZone":  "ZONE-B",
        "warehouseAisle": "B-01",
        "warehouseBin":   "BIN-B-01-001",
        "quantity":       125000
      },
      {
        "warehouseZone":  "ZONE-B",
        "warehouseAisle": "B-02",
        "warehouseBin":   "BIN-B-02-001",
        "quantity":       124950
      }
    ],
    "completedBy": "forklift.op.03",
    "notes":       "249,950 Space Explorer figures stowed in ZONE-B. Ready for store allocation."
  }' | python3 -m json.tool
ok "KEY EVENT: erp.wms.inbound.putaway.completed — OMS will mark this inventory available"

# ── 13. Inventory after putaway ───────────────────────────────────────────────
section "13. Inventory for SPACE SKU after putaway"
curl -s "$BASE_URL/inventory/sku/TOY-SPACE-MIX-001" | python3 -m json.tool
curl -s "$BASE_URL/inventory/sku/TOY-SPACE-MIX-001/available" | python3 -m json.tool

# ── 14. Full audit trail ──────────────────────────────────────────────────────
section "14. Full ASN audit trail"
curl -s "$BASE_URL/asns/$ASN_ID/events" | python3 -m json.tool

# ── 15. Filter by status ──────────────────────────────────────────────────────
section "15. Filter ASNs by status=PUTAWAY_COMPLETED"
curl -s "$BASE_URL/asns/status/PUTAWAY_COMPLETED" | python3 -m json.tool

# ── 16. Duplicate ASN guard ───────────────────────────────────────────────────
section "16. Duplicate ASN for same PO (expect 409)"
curl -s -X POST "$BASE_URL/asns" \
  -H "Content-Type: application/json" \
  -d '{
    "asnNumber":"ASN-2025-DUP","poExternalId":"po-003-test-uuid",
    "poNumber":"PO-2025-003","campaignExternalId":"camp-001-uuid",
    "campaignCode":"SUMMER25-TOY","vendorExternalId":"vnd-004-uuid",
    "vendorCode":"VND-TH-001","vendorName":"Test","vendorCountry":"THAILAND",
    "sku":"TEST-SKU","toyDescription":"Test","expectedQuantity":1,
    "createdBy":"test"
  }' | python3 -m json.tool

# ── 17. Invalid state guard ───────────────────────────────────────────────────
section "17. Attempt to receive SCHEDULED ASN-2025-002 (expect 409)"
curl -s -X POST "$BASE_URL/asns/asn-002-uuid/receive" \
  -H "Content-Type: application/json" \
  -d '{"receivedQuantity":100,"receivedBy":"test"}' | python3 -m json.tool

# ── 18. Drive ASN-2025-002 forward ────────────────────────────────────────────
section "18. Mark seeded ASN-2025-002 (SCHEDULED) → IN_TRANSIT"
curl -s -X POST "$BASE_URL/asns/asn-002-uuid/in-transit" \
  -H "Content-Type: application/json" \
  -d '{"triggeredBy":"cosco.tracking","notes":"COSCO vessel departed Shenzhen. ETA Long Beach Oct 5."}' \
  | python3 -m json.tool

# ── 19. Actuator health ───────────────────────────────────────────────────────
section "19. Actuator Health Check"
curl -s http://localhost:8084/actuator/health | python3 -m json.tool

echo ""
ok "All tests complete."
ok "RabbitMQ events published:"
ok "  erp.wms.inbound.asn.created          — ASN created from PO"
ok "  erp.wms.inbound.asn.scheduled        — dock appointment confirmed"
ok "  erp.wms.inbound.shipment.arrived     — vessel docked"
ok "  erp.wms.inbound.receiving.completed  — physical count done"
ok "  erp.wms.inbound.putaway.completed    — KEY: OMS marks inventory available"
ok "Check: http://localhost:15672 → Queues → control-tower-test"
