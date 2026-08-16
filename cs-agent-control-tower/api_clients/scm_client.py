"""
api_clients/scm_client.py
Thin request wrappers for every Spring Boot SCM service.
All methods raise on non-2xx so callers can catch cleanly.
"""

from __future__ import annotations

import os
from typing import Any

import requests

from observability.http_logger import logged_request
from api_clients.keycloak_auth import auth_header

_BASES: dict[str, str] = {
    "crm":          os.getenv("CRM_URL",          "http://localhost:8081"),
    "vendor":       os.getenv("VENDOR_URL",       "http://localhost:8082"),
    "procurement":  os.getenv("PROCUREMENT_URL",  "http://localhost:8083"),
    "wms_inbound":  os.getenv("WMS_INBOUND_URL",  "http://localhost:8084"),
    "oms":          os.getenv("OMS_URL",          "http://localhost:8085"),
    "wms_outbound": os.getenv("WMS_OUTBOUND_URL", "http://localhost:8086"),
    "tms":          os.getenv("TMS_URL",          "http://localhost:8087"),
}

TIMEOUT = int(os.getenv("API_TIMEOUT_SECONDS", "10"))


def _get(service: str, path: str) -> dict[str, Any]:
    url = f"{_BASES[service]}{path}"
    r = logged_request("GET", service, url, timeout=TIMEOUT, headers=auth_header())
    return r.json()


def _post(service: str, path: str, body: dict[str, Any]) -> dict[str, Any]:
    url = f"{_BASES[service]}{path}"
    r = logged_request("POST", service, url, timeout=TIMEOUT, json_body=body, headers=auth_header())
    return r.json()


def _put(service: str, path: str, body: dict[str, Any] | None = None) -> dict[str, Any]:
    url = f"{_BASES[service]}{path}"
    r = logged_request("PUT", service, url, timeout=TIMEOUT, json_body=body or {}, headers=auth_header())
    return r.json()

# ---------------------------------------------------------------------------
# CRM  :8081
# ---------------------------------------------------------------------------
def crm_list_campaigns() -> list:
    return _get("crm", "/api/v1/campaigns")

def crm_create_campaign(name: str, target_region: str, budget: float) -> dict:
    import datetime, uuid
    today = datetime.date.today()
    code  = name.upper().replace(" ", "-")[:14] + "-" + uuid.uuid4().hex[:5].upper()
    return _post("crm", "/api/v1/campaigns", {
        "campaignName": name,
        "campaignCode": code,
        "campaignType": "PROMO",
        "targetRegion": target_region,
        "budgetUsd":    budget,
        "startDate":    str(today),
        "endDate":      str(today.replace(year=today.year + 1)),
        "createdBy":    "agent",
    })

def crm_launch_campaign(campaign_external_id: str) -> dict:
    return _post("crm", f"/api/v1/campaigns/{campaign_external_id}/launch", {
        "triggeredBy": "agent"
    })


# ---------------------------------------------------------------------------
# Vendor  :8082
# ---------------------------------------------------------------------------
def vendor_list_vendors() -> list:
    return _get("vendor", "/api/v1/vendors")

def vendor_create_rfq(title: str, description: str, deadline: str,
                      campaign_external_id: str = "camp-001-uuid",
                      campaign_code: str = "SUMMER25-TOY") -> dict:
    import datetime, uuid
    today = datetime.date.today()
    return _post("vendor", "/api/v1/rfqs", {
        "rfqNumber":          f"RFQ-AGENT-{uuid.uuid4().hex[:8].upper()}",
        "campaignExternalId": campaign_external_id,
        "campaignCode":       campaign_code,
        "title":              title,
        "description":        description,
        "toyCategory":        "Mixed Figures",
        "quantityRequired":   500,
        "unit":               "PIECES",
        "targetUnitCostUsd":  1.00,
        "requiredByDate":     str(today.replace(year=today.year + 1)),
        "submissionDeadline": deadline,
        "createdBy":          "agent",
    })

def vendor_open_rfq(rfq_external_id: str) -> dict:
    return _post("vendor", f"/api/v1/rfqs/{rfq_external_id}/open", {
        "triggeredBy": "agent"
    })

def vendor_submit_quote(rfq_external_id: str, vendor_external_id: str,
                        unit_price: float, lead_days: int,
                        quantity: int = 500) -> dict:
    import datetime
    delivery = str(datetime.date.today() + datetime.timedelta(days=lead_days))
    return _post("vendor", f"/api/v1/rfqs/{rfq_external_id}/quotes", {
        "vendorExternalId":  vendor_external_id,
        "quotedQuantity":    quantity,
        "quotedUnitCostUsd": unit_price,
        "totalPriceUsd":     round(unit_price * quantity, 2),
        "deliveryDate":      delivery,
        "leadTimeDays":      lead_days,
        "notes":             "Quote submitted by agent",
    })

def vendor_award_contract(rfq_external_id: str, quote_external_id: str,
                          vendor_external_id: str, quantity: int = 500) -> dict:
    return _post("vendor", f"/api/v1/rfqs/{rfq_external_id}/award", {
        "winningQuoteExternalId":  quote_external_id,
        "winningVendorExternalId": vendor_external_id,
        "awardedQuantity":         quantity,
        "awardedBy":               "agent",
    })


# ---------------------------------------------------------------------------
# Procurement  :8083
# ---------------------------------------------------------------------------
def procurement_create_po(vendor_external_id: str, vendor_code: str,
                           vendor_name: str, vendor_country: str,
                           rfq_external_id: str, rfq_number: str,
                           campaign_external_id: str, campaign_code: str,
                           award_external_id: str, description: str,
                           quantity: int, unit_price: float) -> dict:
    import uuid, datetime
    today = datetime.date.today()
    total = round(quantity * unit_price, 2)
    return _post("procurement", "/api/v1/purchase-orders", {
        "poNumber":             f"PO-AGENT-{uuid.uuid4().hex[:8].upper()}",
        "rfqExternalId":        rfq_external_id,
        "rfqNumber":            rfq_number,
        "campaignExternalId":   campaign_external_id,
        "campaignCode":         campaign_code,
        "awardExternalId":      award_external_id,
        "vendorExternalId":     vendor_external_id,
        "vendorCode":           vendor_code,
        "vendorName":           vendor_name,
        "vendorCountry":        vendor_country,
        "toyDescription":       description,
        "quantityOrdered":      quantity,
        "unitPriceUsd":         unit_price,
        "totalValueUsd":        total,
        "currency":             "USD",
        "paymentTerms":         "NET30",
        "incoterms":            "FOB",
        "destinationPort":      "Port of Los Angeles",
        "requiredDeliveryDate": str(today + datetime.timedelta(days=90)),
        "estimatedShipDate":    str(today + datetime.timedelta(days=60)),
        "createdBy":            "agent",
    })

def procurement_approve_po(po_external_id: str) -> dict:
    return _post("procurement", f"/api/v1/purchase-orders/{po_external_id}/approve", {
        "approvedBy": "agent",
        "notes":      "Approved by agentic AI control tower",
    })

def procurement_send_po(po_external_id: str) -> dict:
    return _post("procurement", f"/api/v1/purchase-orders/{po_external_id}/send", {
        "triggeredBy": "agent",
    })

def procurement_acknowledge_po(po_external_id: str) -> dict:
    return _post("procurement", f"/api/v1/purchase-orders/{po_external_id}/acknowledge", {
        "triggeredBy": "agent",
    })

def procurement_ready_to_ship(po_external_id: str) -> dict:
    import datetime
    return _post("procurement", f"/api/v1/purchase-orders/{po_external_id}/ready-to-ship", {
        "triggeredBy":       "agent",
        "estimatedShipDate": str(datetime.date.today() + datetime.timedelta(days=30)),
    })

def procurement_complete_po(po_external_id: str) -> dict:
    return _post("procurement", f"/api/v1/purchase-orders/{po_external_id}/complete", {
        "triggeredBy": "agent",
    })


# ---------------------------------------------------------------------------
# WMS Inbound  :8084
# ---------------------------------------------------------------------------
def wms_inbound_create_asn(po_external_id: str, po_number: str,
                            campaign_external_id: str, campaign_code: str,
                            vendor_external_id: str, vendor_code: str,
                            vendor_name: str, vendor_country: str,
                            sku: str, description: str,
                            expected_qty: int) -> dict:
    import uuid, datetime
    arrival = str(datetime.date.today() + datetime.timedelta(days=30))
    return _post("wms_inbound", "/api/v1/asns", {
        "asnNumber":            f"ASN-AGENT-{uuid.uuid4().hex[:8].upper()}",
        "poExternalId":         po_external_id,
        "poNumber":             po_number,
        "campaignExternalId":   campaign_external_id,
        "campaignCode":         campaign_code,
        "vendorExternalId":     vendor_external_id,
        "vendorCode":           vendor_code,
        "vendorName":           vendor_name,
        "vendorCountry":        vendor_country,
        "sku":                  sku,
        "toyDescription":       description,
        "expectedQuantity":     expected_qty,
        "unitOfMeasure":        "PIECES",
        "carrierName":          "FedEx Freight",
        "trackingNumber":       f"FX-AGENT-{uuid.uuid4().hex[:6].upper()}",
        "originPort":           "Port of Ho Chi Minh City",
        "destinationPort":      "Port of Los Angeles",
        "incoterms":            "FOB",
        "estimatedArrivalDate": arrival,
        "createdBy":            "agent",
    })

def wms_inbound_schedule(asn_external_id: str) -> dict:
    import datetime
    # Use strftime to avoid microseconds which the API rejects
    appt = (datetime.datetime.now() + datetime.timedelta(days=1)).strftime("%Y-%m-%dT%H:%M:%S")
    return _post("wms_inbound", f"/api/v1/asns/{asn_external_id}/schedule", {
        "dockAppointmentDate": appt,
        "dockDoor":            "DOOR-01",
        "triggeredBy":         "agent",
    })

def wms_inbound_mark_in_transit(asn_external_id: str) -> dict:
    return _post("wms_inbound", f"/api/v1/asns/{asn_external_id}/in-transit", {
        "triggeredBy": "agent",
    })

def wms_inbound_mark_arrived(asn_external_id: str) -> dict:
    import datetime
    return _post("wms_inbound", f"/api/v1/asns/{asn_external_id}/arrived", {
        "triggeredBy": "agent",
        "arrivalDate": str(datetime.date.today()),
    })

def wms_inbound_receive(asn_external_id: str, received_qty: int) -> dict:
    return _post("wms_inbound", f"/api/v1/asns/{asn_external_id}/receive", {
        "receivedQuantity": received_qty,
        "receivedBy":       "agent",
        "notes":            "Received by agentic AI control tower",
    })

def wms_inbound_putaway(asn_external_id: str, sku: str,
                         quantity: int,
                         zone: str = "ZONE-A",
                         aisle: str = "AISLE-3",
                         bin_loc: str = "BIN-001") -> dict:
    return _post("wms_inbound", f"/api/v1/asns/{asn_external_id}/putaway", {
        "completedBy": "agent",
        "binAllocations": [{
            "sku":            sku,
            "quantity":       quantity,
            "warehouseZone":  zone,
            "warehouseAisle": aisle,
            "warehouseBin":   bin_loc,
        }],
        "notes": "Putaway by agentic AI control tower",
    })

def wms_inbound_list_inventory(campaign_code: str = "SUMMER25-TOY") -> dict:
    return _get("wms_inbound", f"/api/v1/inventory/campaign/{campaign_code}")

def wms_inbound_get_available_qty(sku: str) -> dict:
    return _get("wms_inbound", f"/api/v1/inventory/sku/{sku}/available")


# ---------------------------------------------------------------------------
# OMS  :8085
# ---------------------------------------------------------------------------
def oms_list_regions() -> list:
    return _get("oms", "/api/v1/regions")

def oms_update_inventory(sku: str, campaign_code: str, campaign_external_id: str,
                          quantity: int, zone: str = "ZONE-A",
                          aisle: str = "AISLE-3", bin_loc: str = "BIN-001") -> dict:
    return _post("oms", "/api/v1/inventory/update", {
        "sku":                sku,
        "campaignCode":       campaign_code,
        "campaignExternalId": campaign_external_id,
        "quantityAvailable":  quantity,
        "warehouseZone":      zone,
        "warehouseAisle":     aisle,
        "warehouseBin":       bin_loc,
        "updatedBy":          "agent",
    })

def oms_create_order(region_code: str, campaign_code: str, campaign_external_id: str,
                      sku: str, description: str, quantity: int) -> dict:
    import uuid, datetime
    return _post("oms", "/api/v1/store-orders", {
        "orderNumber":           f"ORD-AGENT-{uuid.uuid4().hex[:8].upper()}",
        "regionCode":            region_code,
        "campaignCode":          campaign_code,
        "campaignExternalId":    campaign_external_id,
        "sku":                   sku,
        "toyDescription":        description,
        "quantityOrdered":       quantity,
        "quantityRequested":     quantity,
        "requestedDeliveryDate": str(datetime.date.today() + datetime.timedelta(days=30)),
        "createdBy":             "agent",
    })

def oms_submit_order(order_external_id: str) -> dict:
    return _post("oms", f"/api/v1/store-orders/{order_external_id}/submit", {
        "triggeredBy": "agent",
    })

def oms_allocate_order(order_external_id: str) -> dict:
    return _post("oms", f"/api/v1/store-orders/{order_external_id}/allocate", {
        "allocatedBy": "agent",
        "notes":       "Allocated by agentic AI control tower",
    })

def oms_mark_picking(order_external_id: str) -> dict:
    return _post("oms", f"/api/v1/store-orders/{order_external_id}/picking", {
        "triggeredBy": "agent",
    })

def oms_mark_shipped(order_external_id: str) -> dict:
    return _post("oms", f"/api/v1/store-orders/{order_external_id}/shipped", {
        "triggeredBy": "agent",
    })

def oms_mark_delivered(order_external_id: str) -> dict:
    return _post("oms", f"/api/v1/store-orders/{order_external_id}/delivered", {
        "triggeredBy": "agent",
    })


# ---------------------------------------------------------------------------
# WMS Outbound  :8086
# ---------------------------------------------------------------------------
def wms_outbound_create_wave(order_external_id: str, order_number: str,
                              campaign_external_id: str, campaign_code: str,
                              region_code: str, sku: str, description: str,
                              total_qty: int, distribution_dc: str = "DC-CHICAGO") -> dict:
    import uuid, datetime
    return _post("wms_outbound", "/api/v1/pick-waves", {
        "waveNumber":           f"WV-AGENT-{uuid.uuid4().hex[:8].upper()}",
        "storeOrderExternalId": order_external_id,
        "storeOrderNumber":     order_number,
        "campaignExternalId":   campaign_external_id,
        "campaignCode":         campaign_code,
        "regionCode":           region_code,
        "sku":                  sku,
        "toyDescription":       description,
        "totalQuantity":        total_qty,
        "pickZone":             "ZONE-A",
        "requiredShipDate":     str(datetime.date.today() + datetime.timedelta(days=7)),
        "createdBy":            "agent",
    })

def wms_outbound_assign_wave(wave_external_id: str) -> dict:
    return _post("wms_outbound", f"/api/v1/pick-waves/{wave_external_id}/assign", {
        "assignedTo": "agent",
        "notes":      "Assigned by agentic AI control tower",
    })

def wms_outbound_start_wave(wave_external_id: str) -> dict:
    return _post("wms_outbound", f"/api/v1/pick-waves/{wave_external_id}/start", {
        "triggeredBy": "agent",
    })

def wms_outbound_complete_wave(wave_external_id: str, picked_qty: int) -> dict:
    return _post("wms_outbound", f"/api/v1/pick-waves/{wave_external_id}/complete", {
        "triggeredBy":    "agent",
        "pickedQuantity": picked_qty,
    })

def wms_outbound_create_shipment(wave_external_id: str, campaign_code: str,
                                  region_code: str, sku: str,
                                  distribution_dc: str, carrier: str,
                                  store_lines: list[dict]) -> dict:
    import uuid, datetime
    today = datetime.date.today()
    return _post("wms_outbound", "/api/v1/shipments", {
        "shipmentNumber":       f"SHP-AGENT-{uuid.uuid4().hex[:8].upper()}",
        "pickWaveExternalId":   wave_external_id,
        "campaignCode":         campaign_code,
        "regionCode":           region_code,
        "distributionDc":       distribution_dc,
        "carrierName":          carrier,
        "proNumber":            f"PRO-AGENT-{uuid.uuid4().hex[:6].upper()}",
        "requiredDeliveryDate": str(today + datetime.timedelta(days=7)),
        "estimatedShipDate":    str(today + datetime.timedelta(days=2)),
        "createdBy":            "agent",
        "storeCartons":         store_lines,
    })

def wms_outbound_pack_shipment(shipment_external_id: str) -> dict:
    return _post("wms_outbound", f"/api/v1/shipments/{shipment_external_id}/pack", {
        "triggeredBy": "agent",
    })

def wms_outbound_manifest_shipment(shipment_external_id: str, carrier: str) -> dict:
    import uuid
    return _post("wms_outbound", f"/api/v1/shipments/{shipment_external_id}/manifest", {
        "carrierName":  carrier,
        "proNumber":    f"PRO-AGENT-{uuid.uuid4().hex[:6].upper()}",
        "manifestedBy": "agent",
    })

def wms_outbound_dispatch_shipment(shipment_external_id: str) -> dict:
    return _post("wms_outbound", f"/api/v1/shipments/{shipment_external_id}/dispatch", {
        "triggeredBy": "agent",
    })


# ---------------------------------------------------------------------------
# TMS  :8087
# ---------------------------------------------------------------------------
def tms_create_load(shipment_external_id: str, shipment_number: str,
                     order_external_id: str, order_number: str,
                     campaign_external_id: str, campaign_code: str,
                     region_code: str, distribution_dc: str,
                     carrier: str, pro_number: str,
                     sku: str, description: str,
                     total_units: int, store_lines: list[dict]) -> dict:
    import uuid, datetime
    today = datetime.date.today()
    return _post("tms", "/api/v1/delivery-loads", {
        "loadNumber":           f"LOAD-AGENT-{uuid.uuid4().hex[:8].upper()}",
        "shipmentExternalId":   shipment_external_id,
        "shipmentNumber":       shipment_number,
        "storeOrderExternalId": order_external_id,
        "storeOrderNumber":     order_number,
        "campaignExternalId":   campaign_external_id,
        "campaignCode":         campaign_code,
        "regionCode":           region_code,
        "distributionDc":       distribution_dc,
        "carrierName":          carrier,
        "proNumber":            pro_number,
        "sku":                  sku,
        "toyDescription":       description,
        "totalUnits":           total_units,
        "totalCartons":         len(store_lines),
        "requiredDeliveryDate": str(today + datetime.timedelta(days=7)),
        "createdBy":            "agent",
        "storeCartons":         store_lines,
    })

def tms_assign_driver(load_external_id: str) -> dict:
    import datetime
    today = datetime.date.today()
    return _post("tms", f"/api/v1/delivery-loads/{load_external_id}/assign", {
        "driverName":            "Agent Driver",
        "truckNumber":           "TRK-AGENT-001",
        "pickupDate":            str(today),
        "estimatedDeliveryDate": str(today + datetime.timedelta(days=5)),
        "notes":                 "Assigned by agentic AI control tower",
    })

def tms_mark_in_transit(load_external_id: str) -> dict:
    return _post("tms", f"/api/v1/delivery-loads/{load_external_id}/in-transit", {
        "triggeredBy": "agent",
    })

def tms_record_transit_event(load_external_id: str, event_code: str,
                              location: str, description: str = "") -> dict:
    import datetime
    return _post("tms", f"/api/v1/delivery-loads/{load_external_id}/transit-events", {
        "eventCode":        event_code,
        "eventDescription": description,
        "location":         location,
        "eventAt":          datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
        "source":           "agent",
    })

def tms_confirm_pod(load_external_id: str,
                     store_delivery_external_id: str,
                     store_number: str,
                     quantity: int) -> dict:
    import datetime
    return _post("tms",
        f"/api/v1/delivery-loads/{load_external_id}/store-deliveries/{store_delivery_external_id}/pod",
        {
            "deliveredQuantity": quantity,
            "podSignatory":      f"Store Manager {store_number}",
            "podNotes":          "POD confirmed by agentic AI control tower",
            "deliveredAt":       datetime.datetime.now().strftime("%Y-%m-%dT%H:%M:%S"),
        }
    )


# ---------------------------------------------------------------------------
# Health check helper
#
# Deliberately NOT routed through logged_request/audit logging: this is a
# frequent (every 30s from the UI's auto-refresh, plus every manual
# refresh click) low-value operational ping, not a business call. Logging
# it would flood the audit trail with noise Security/Finance don't need.
# ---------------------------------------------------------------------------
def health_check_all() -> dict[str, bool]:
    results: dict[str, bool] = {}
    for svc, base in _BASES.items():
        try:
            r = requests.get(f"{base}/actuator/health", timeout=3)
            results[svc] = r.status_code == 200
        except Exception:
            results[svc] = False
    return results
