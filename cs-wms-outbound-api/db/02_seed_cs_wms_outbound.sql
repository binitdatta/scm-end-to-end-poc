-- =============================================================================
-- cs_wms_outbound SEED DATA
-- Run AFTER 01_ddl_cs_wms_outbound.sql
-- Seeds a pick wave and shipment mirroring the Midwest ORD-2025-001
-- that was already ALLOCATED in cs-oms-api.
-- =============================================================================

USE cs_wms_outbound;

-- ── Pick Wave for ORD-2025-001 (Midwest DINO toys) ───────────────────────────
INSERT INTO pick_waves (
    external_id, wave_number,
    store_order_external_id, store_order_number,
    campaign_external_id, campaign_code, region_code,
    sku, toy_description, total_quantity, picked_quantity,
    pick_zone, assigned_to,
    required_ship_date, started_at, completed_at,
    status, notes, created_by
) VALUES (
    'pw-001-uuid', 'WV-2025-001',
    'ord-001-uuid', 'ORD-2025-001',
    'camp-001-uuid', 'SUMMER25-TOY', 'US-MIDWEST',
    'TOY-DINO-MIX-001',
    'Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',
    128000, 128000,
    'ZONE-A', 'picker.team.01',
    '2025-05-20', '2025-05-18 07:00:00', '2025-05-18 16:00:00',
    'COMPLETED',
    'Full pick completed from ZONE-A. 128,000 units across 4 Midwest stores.',
    'wms.outbound.coordinator'
);

-- ── Pick wave lines (two bin sources from ZONE-A) ────────────────────────────
INSERT INTO pick_wave_lines (external_id, pick_wave_id, sku, warehouse_zone, warehouse_aisle,
                              warehouse_bin, quantity_to_pick, quantity_picked, status)
SELECT 'pwl-001-uuid', id, 'TOY-DINO-MIX-001', 'ZONE-A', 'A-01', 'BIN-A-01-001',
       64000, 64000, 'PICKED'
FROM pick_waves WHERE wave_number = 'WV-2025-001';

INSERT INTO pick_wave_lines (external_id, pick_wave_id, sku, warehouse_zone, warehouse_aisle,
                              warehouse_bin, quantity_to_pick, quantity_picked, status)
SELECT 'pwl-002-uuid', id, 'TOY-DINO-MIX-001', 'ZONE-A', 'A-02', 'BIN-A-02-001',
       64000, 64000, 'PICKED'
FROM pick_waves WHERE wave_number = 'WV-2025-001';

-- ── Outbound Shipment for WV-2025-001 ────────────────────────────────────────
INSERT INTO outbound_shipments (
    external_id, shipment_number,
    pick_wave_id, store_order_external_id, store_order_number,
    campaign_external_id, campaign_code, region_code, distribution_dc,
    sku, toy_description,
    total_cartons, total_units, units_per_carton,
    carrier_name, pro_number, destination_region,
    required_delivery_date, estimated_ship_date, actual_ship_date,
    status, notes, created_by
) SELECT
    'shp-001-uuid', 'SHP-2025-001',
    id, 'ord-001-uuid', 'ORD-2025-001',
    'camp-001-uuid', 'SUMMER25-TOY', 'US-MIDWEST', 'DC-CHICAGO',
    'TOY-DINO-MIX-001',
    'Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',
    4, 128000, 32000,
    'XPO Logistics', 'XPO-2025-MW-0441', 'Midwest United States',
    '2025-06-01', '2025-05-20', '2025-05-20',
    'DISPATCHED',
    'All 4 Midwest store cartons dispatched. XPO tracking XPO-2025-MW-0441.',
    'wms.outbound.coordinator'
FROM pick_waves WHERE wave_number = 'WV-2025-001';

-- ── Shipment store lines (4 Midwest stores seeded in cs-oms) ─────────────────
INSERT INTO shipment_store_lines (external_id, shipment_id, store_external_id, store_number,
                                   store_name, city, state_code, sku, quantity, carton_label, status)
SELECT 'ssl-001-uuid', s.id, 'str-001-uuid', 'STR-0001',
       'Burger Bliss Chicago Downtown', 'Chicago', 'IL',
       'TOY-DINO-MIX-001', 32000, 'CTN-MW-0001', 'DISPATCHED'
FROM outbound_shipments s WHERE s.shipment_number = 'SHP-2025-001';

INSERT INTO shipment_store_lines (external_id, shipment_id, store_external_id, store_number,
                                   store_name, city, state_code, sku, quantity, carton_label, status)
SELECT 'ssl-002-uuid', s.id, 'str-002-uuid', 'STR-0002',
       'Burger Bliss Naperville', 'Naperville', 'IL',
       'TOY-DINO-MIX-001', 32000, 'CTN-MW-0002', 'DISPATCHED'
FROM outbound_shipments s WHERE s.shipment_number = 'SHP-2025-001';

INSERT INTO shipment_store_lines (external_id, shipment_id, store_external_id, store_number,
                                   store_name, city, state_code, sku, quantity, carton_label, status)
SELECT 'ssl-003-uuid', s.id, 'str-003-uuid', 'STR-0003',
       'Burger Bliss Milwaukee', 'Milwaukee', 'WI',
       'TOY-DINO-MIX-001', 32000, 'CTN-MW-0003', 'DISPATCHED'
FROM outbound_shipments s WHERE s.shipment_number = 'SHP-2025-001';

INSERT INTO shipment_store_lines (external_id, shipment_id, store_external_id, store_number,
                                   store_name, city, state_code, sku, quantity, carton_label, status)
SELECT 'ssl-004-uuid', s.id, 'str-004-uuid', 'STR-0004',
       'Burger Bliss Indianapolis', 'Indianapolis', 'IN',
       'TOY-DINO-MIX-001', 32000, 'CTN-MW-0004', 'DISPATCHED'
FROM outbound_shipments s WHERE s.shipment_number = 'SHP-2025-001';

-- ── Outbound events audit trail ───────────────────────────────────────────────
INSERT INTO outbound_events (entity_type, entity_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT 'PICK_WAVE', id, 'WAVE_CREATED', NULL, 'CREATED',
       'Pick wave created from ORD-2025-001 allocation event.', 'wms.outbound.coordinator', 1
FROM pick_waves WHERE wave_number = 'WV-2025-001';

INSERT INTO outbound_events (entity_type, entity_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT 'PICK_WAVE', id, 'WAVE_ASSIGNED', 'CREATED', 'ASSIGNED',
       'Assigned to picker.team.01.', 'wms.outbound.coordinator', 0
FROM pick_waves WHERE wave_number = 'WV-2025-001';

INSERT INTO outbound_events (entity_type, entity_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT 'PICK_WAVE', id, 'WAVE_COMPLETED', 'PICKING', 'COMPLETED',
       '128,000 units picked from ZONE-A. 2 bin locations cleared.', 'picker.team.01', 1
FROM pick_waves WHERE wave_number = 'WV-2025-001';

INSERT INTO outbound_events (entity_type, entity_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT 'SHIPMENT', id, 'SHIPMENT_CREATED', NULL, 'CREATED',
       'Shipment SHP-2025-001 created from completed pick wave WV-2025-001.', 'wms.outbound.coordinator', 1
FROM outbound_shipments WHERE shipment_number = 'SHP-2025-001';

INSERT INTO outbound_events (entity_type, entity_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT 'SHIPMENT', id, 'SHIPMENT_PACKED', 'CREATED', 'PACKED',
       '4 store cartons packed and labeled. Carton labels printed.', 'wms.outbound.packer', 1
FROM outbound_shipments WHERE shipment_number = 'SHP-2025-001';

INSERT INTO outbound_events (entity_type, entity_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT 'SHIPMENT', id, 'SHIPMENT_MANIFESTED', 'PACKED', 'MANIFESTED',
       'XPO manifest generated. PRO XPO-2025-MW-0441 assigned.', 'wms.outbound.coordinator', 1
FROM outbound_shipments WHERE shipment_number = 'SHP-2025-001';

INSERT INTO outbound_events (entity_type, entity_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT 'SHIPMENT', id, 'SHIPMENT_DISPATCHED', 'MANIFESTED', 'DISPATCHED',
       'XPO driver collected. 4 cartons en route to Midwest stores.', 'wms.outbound.coordinator', 1
FROM outbound_shipments WHERE shipment_number = 'SHP-2025-001';
