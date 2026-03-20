-- =============================================================================
-- cs_control_tower_bi SEED DATA
-- Run AFTER 01_ddl_cs_control_tower_bi.sql in MySQL Workbench
-- =============================================================================

USE cs_control_tower_bi;

-- ── erp_events ────────────────────────────────────────────────────────────────
INSERT INTO erp_events (routing_key, service, event_type, campaign_code, region_code, payload_json, received_at) VALUES
('erp.crm.campaign.launched',
 'crm', 'CAMPAIGN_LAUNCHED', 'SUMMER25-TOY', NULL,
 '{"source":"cs-crm-api","eventType":"CAMPAIGN_LAUNCHED","campaignCode":"SUMMER25-TOY","campaignName":"Summer 2025 Toy Surprise","status":"ACTIVE","targetStoreCount":3200}',
 '2025-04-01 09:00:00'),

('erp.vendor.rfq.awarded',
 'vendor', 'RFQ_AWARDED', 'SUMMER25-TOY', NULL,
 '{"source":"cs-vendor-api","eventType":"RFQ_AWARDED","rfqNumber":"RFQ-2025-001","campaignCode":"SUMMER25-TOY","winningVendorCode":"VND-VN-001","winningVendorName":"Hanoi Toys Manufacturing Co.","country":"VIETNAM","unitPrice":2.50,"quantityAwarded":500000}',
 '2025-04-05 14:30:00'),

('erp.procurement.po.ready-to-ship',
 'procurement', 'PO_READY_TO_SHIP', 'SUMMER25-TOY', NULL,
 '{"source":"cs-procurement-api","eventType":"PO_READY_TO_SHIP","poNumber":"PO-2025-001","campaignCode":"SUMMER25-TOY","vendorCode":"VND-VN-001","totalQuantity":500000,"sku":"TOY-DINO-MIX-001","status":"READY_TO_SHIP"}',
 '2025-05-01 08:00:00'),

('erp.wms.inbound.putaway.completed',
 'wms-inbound', 'PUTAWAY_COMPLETED', 'SUMMER25-TOY', NULL,
 '{"source":"cs-wms-inbound-api","eventType":"PUTAWAY_COMPLETED","asnNumber":"ASN-2025-001","campaignCode":"SUMMER25-TOY","sku":"TOY-DINO-MIX-001","receivedQuantity":499800,"warehouseZone":"ZONE-A"}',
 '2025-05-10 16:00:00'),

('erp.oms.store-order.allocated',
 'oms', 'STORE_ORDER_ALLOCATED', 'SUMMER25-TOY', 'US-MIDWEST',
 '{"source":"cs-oms-api","eventType":"STORE_ORDER_ALLOCATED","orderNumber":"ORD-2025-001","campaignCode":"SUMMER25-TOY","regionCode":"US-MIDWEST","sku":"TOY-DINO-MIX-001","quantityAllocated":128000,"storeCount":640}',
 '2025-05-15 10:00:00'),

('erp.oms.store-order.allocated',
 'oms', 'STORE_ORDER_ALLOCATED', 'SUMMER25-TOY', 'US-SOUTHEAST',
 '{"source":"cs-oms-api","eventType":"STORE_ORDER_ALLOCATED","orderNumber":"ORD-2025-003","campaignCode":"SUMMER25-TOY","regionCode":"US-SOUTHEAST","sku":"TOY-DINO-MIX-001","quantityAllocated":104000,"storeCount":520}',
 '2025-05-15 10:15:00'),

('erp.wms.outbound.shipment.dispatched',
 'wms-outbound', 'SHIPMENT_DISPATCHED', 'SUMMER25-TOY', 'US-MIDWEST',
 '{"source":"cs-wms-outbound-api","eventType":"SHIPMENT_DISPATCHED","shipmentNumber":"SHP-2025-001","campaignCode":"SUMMER25-TOY","regionCode":"US-MIDWEST","totalUnits":128000,"totalCartons":4,"carrierName":"XPO Logistics","proNumber":"XPO-2025-MW-0441"}',
 '2025-05-20 07:00:00'),

('erp.wms.outbound.shipment.dispatched',
 'wms-outbound', 'SHIPMENT_DISPATCHED', 'SUMMER25-TOY', 'US-SOUTHEAST',
 '{"source":"cs-wms-outbound-api","eventType":"SHIPMENT_DISPATCHED","shipmentNumber":"SHP-2025-002","campaignCode":"SUMMER25-TOY","regionCode":"US-SOUTHEAST","totalUnits":104000,"totalCartons":4,"carrierName":"Old Dominion Freight","proNumber":"OD-2025-SE-8812"}',
 '2025-05-21 07:30:00'),

('erp.tms.load.in-transit',
 'tms', 'LOAD_IN_TRANSIT', 'SUMMER25-TOY', 'US-MIDWEST',
 '{"source":"cs-tms-api","eventType":"LOAD_IN_TRANSIT","loadNumber":"LOAD-2025-001","campaignCode":"SUMMER25-TOY","regionCode":"US-MIDWEST","carrierName":"XPO Logistics","proNumber":"XPO-2025-MW-0441","driverName":"Mike Johnson"}',
 '2025-05-20 14:00:00'),

('erp.tms.load.in-transit',
 'tms', 'LOAD_IN_TRANSIT', 'SUMMER25-TOY', 'US-SOUTHEAST',
 '{"source":"cs-tms-api","eventType":"LOAD_IN_TRANSIT","loadNumber":"LOAD-2025-002","campaignCode":"SUMMER25-TOY","regionCode":"US-SOUTHEAST","carrierName":"Old Dominion Freight","proNumber":"OD-2025-SE-8812","driverName":"Carlos Mendez"}',
 '2025-05-21 14:00:00'),

('erp.tms.delivery.pod-confirmed',
 'tms', 'DELIVERY_POD_CONFIRMED', 'SUMMER25-TOY', 'US-MIDWEST',
 '{"source":"cs-tms-api","eventType":"DELIVERY_POD_CONFIRMED","loadNumber":"LOAD-2025-001","loadStatus":"COMPLETED","campaignCode":"SUMMER25-TOY","regionCode":"US-MIDWEST","sku":"TOY-DINO-MIX-001","totalUnits":128000,"totalUnitsDelivered":128000,"totalStoresDelivered":4,"carrierName":"XPO Logistics","proNumber":"XPO-2025-MW-0441"}',
 '2025-05-30 15:00:00'),

('erp.tms.delivery.pod-confirmed',
 'tms', 'DELIVERY_POD_CONFIRMED', 'SUMMER25-TOY', 'US-SOUTHEAST',
 '{"source":"cs-tms-api","eventType":"DELIVERY_POD_CONFIRMED","loadNumber":"LOAD-2025-002","loadStatus":"COMPLETED","campaignCode":"SUMMER25-TOY","regionCode":"US-SOUTHEAST","sku":"TOY-DINO-MIX-001","totalUnits":104000,"totalUnitsDelivered":104000,"totalStoresDelivered":4,"carrierName":"Old Dominion Freight","proNumber":"OD-2025-SE-8812"}',
 '2025-05-31 15:00:00');

-- ── campaign_summaries ────────────────────────────────────────────────────────
INSERT INTO campaign_summaries (
    campaign_code, campaign_status,
    total_pos, total_units_ordered, total_units_received,
    total_orders, total_units_allocated,
    total_shipments, total_units_shipped,
    total_loads, total_units_delivered, stores_delivered,
    last_event_at
) VALUES (
    'SUMMER25-TOY', 'ACTIVE',
    1, 500000, 499800,
    2, 232000,
    2, 232000,
    2, 232000, 8,
    '2025-05-31 15:00:00'
);

-- ── delivery_tracking ─────────────────────────────────────────────────────────
INSERT INTO delivery_tracking (
    campaign_code, region_code, load_number,
    carrier_name, pro_number, sku,
    total_units, delivered_units, stores_count,
    load_status, pod_confirmed_at
) VALUES
('SUMMER25-TOY', 'US-MIDWEST',   'LOAD-2025-001', 'XPO Logistics',      'XPO-2025-MW-0441', 'TOY-DINO-MIX-001', 128000, 128000, 4, 'COMPLETED', '2025-05-30 15:00:00'),
('SUMMER25-TOY', 'US-SOUTHEAST', 'LOAD-2025-002', 'Old Dominion Freight','OD-2025-SE-8812',  'TOY-DINO-MIX-001', 104000, 104000, 4, 'COMPLETED', '2025-05-31 15:00:00');

-- ── chat_history ──────────────────────────────────────────────────────────────
INSERT INTO chat_history (user_question, ai_response, service_called, api_endpoint, created_at) VALUES
('How many toys have been delivered?',
 'For SUMMER25-TOY, a total of 232,000 mystery dinosaur figures have been delivered and POD confirmed across 8 Burger Bliss locations — 128,000 units to 4 Midwest stores via XPO Logistics, and 104,000 units to 4 Southeast stores via Old Dominion Freight. All stores have signed.',
 'tms', 'GET /api/v1/delivery-loads/status/COMPLETED', '2025-05-31 16:00:00'),
('What is the campaign status?',
 'SUMMER25-TOY is ACTIVE. 500,000 units were ordered from Vietnam, 499,800 received, 232,000 allocated across 2 regions, all shipped and POD confirmed at 8 stores.',
 'crm', 'GET /api/v1/campaigns', '2025-05-31 16:05:00');

-- ── verify ────────────────────────────────────────────────────────────────────
SELECT 'erp_events'         AS tbl, COUNT(*) AS row_count FROM erp_events
UNION ALL
SELECT 'campaign_summaries',         COUNT(*) FROM campaign_summaries
UNION ALL
SELECT 'delivery_tracking',          COUNT(*) FROM delivery_tracking
UNION ALL
SELECT 'chat_history',               COUNT(*) FROM chat_history;
-- Expected: 12, 1, 2, 2