-- =============================================================================
-- cs_tms SEED DATA
-- Run AFTER 01_ddl_cs_tms.sql
-- Seeds LOAD-2025-001 (COMPLETED with POD confirmed) mirroring SHP-2025-001
-- which was dispatched by cs-wms-outbound-api for the Midwest ORD-2025-001.
-- =============================================================================

USE cs_tms;

-- ── Delivery Load for SHP-2025-001 (Midwest, XPO) ────────────────────────────
INSERT INTO delivery_loads (
    external_id, load_number,
    shipment_external_id, shipment_number,
    store_order_external_id, store_order_number,
    campaign_external_id, campaign_code,
    region_code, distribution_dc,
    sku, toy_description,
    total_cartons, total_units,
    carrier_name, pro_number, driver_name, truck_number,
    required_delivery_date, pickup_date, estimated_delivery_date,
    status, notes, created_by
) VALUES (
    'load-001-uuid', 'LOAD-2025-001',
    'shp-001-uuid', 'SHP-2025-001',
    'ord-001-uuid', 'ORD-2025-001',
    'camp-001-uuid', 'SUMMER25-TOY',
    'US-MIDWEST', 'DC-CHICAGO',
    'TOY-DINO-MIX-001',
    'Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',
    4, 128000,
    'XPO Logistics', 'XPO-2025-MW-0441', 'Mike Johnson', 'XPO-TRUCK-5521',
    '2025-06-01', '2025-05-20', '2025-05-30',
    'COMPLETED',
    'All 4 Midwest store deliveries completed. POD confirmed at all locations.',
    'tms.coordinator'
);

-- ── Store deliveries (4 Midwest stores, all POD_CONFIRMED) ───────────────────
INSERT INTO store_deliveries (
    external_id, delivery_load_id,
    store_external_id, store_number, store_name, city, state_code,
    sku, quantity, carton_label,
    delivered_quantity, pod_signatory, pod_notes,
    delivered_at, pod_confirmed_at, status
)
SELECT
    'sd-001-uuid', dl.id,
    'str-001-uuid', 'STR-0001', 'Burger Bliss Chicago Downtown', 'Chicago', 'IL',
    'TOY-DINO-MIX-001', 32000, 'CTN-MW-0001',
    32000, 'Sarah Chen', 'All 32,000 units received in good condition. Signed at dock.',
    '2025-05-28 10:30:00', '2025-05-28 11:00:00', 'POD_CONFIRMED'
FROM delivery_loads dl WHERE dl.load_number = 'LOAD-2025-001';

INSERT INTO store_deliveries (
    external_id, delivery_load_id,
    store_external_id, store_number, store_name, city, state_code,
    sku, quantity, carton_label,
    delivered_quantity, pod_signatory, pod_notes,
    delivered_at, pod_confirmed_at, status
)
SELECT
    'sd-002-uuid', dl.id,
    'str-002-uuid', 'STR-0002', 'Burger Bliss Naperville', 'Naperville', 'IL',
    'TOY-DINO-MIX-001', 32000, 'CTN-MW-0002',
    32000, 'Tom Richards', 'Full carton received. Stored in back stockroom.',
    '2025-05-28 13:15:00', '2025-05-28 13:45:00', 'POD_CONFIRMED'
FROM delivery_loads dl WHERE dl.load_number = 'LOAD-2025-001';

INSERT INTO store_deliveries (
    external_id, delivery_load_id,
    store_external_id, store_number, store_name, city, state_code,
    sku, quantity, carton_label,
    delivered_quantity, pod_signatory, pod_notes,
    delivered_at, pod_confirmed_at, status
)
SELECT
    'sd-003-uuid', dl.id,
    'str-003-uuid', 'STR-0003', 'Burger Bliss Milwaukee', 'Milwaukee', 'WI',
    'TOY-DINO-MIX-001', 32000, 'CTN-MW-0003',
    32000, 'Jessica Park', 'Delivered to store manager. No damage reported.',
    '2025-05-29 09:00:00', '2025-05-29 09:30:00', 'POD_CONFIRMED'
FROM delivery_loads dl WHERE dl.load_number = 'LOAD-2025-001';

INSERT INTO store_deliveries (
    external_id, delivery_load_id,
    store_external_id, store_number, store_name, city, state_code,
    sku, quantity, carton_label,
    delivered_quantity, pod_signatory, pod_notes,
    delivered_at, pod_confirmed_at, status
)
SELECT
    'sd-004-uuid', dl.id,
    'str-004-uuid', 'STR-0004', 'Burger Bliss Indianapolis', 'Indianapolis', 'IN',
    'TOY-DINO-MIX-001', 32000, 'CTN-MW-0004',
    32000, 'David Torres', 'Final delivery on this load. All 32,000 units confirmed.',
    '2025-05-30 14:00:00', '2025-05-30 14:30:00', 'POD_CONFIRMED'
FROM delivery_loads dl WHERE dl.load_number = 'LOAD-2025-001';

-- ── Transit events (carrier tracking milestones) ──────────────────────────────
INSERT INTO transit_events (delivery_load_id, event_code, event_description, location, event_at, source)
SELECT dl.id, 'PICKUP', 'Shipment picked up from DC-CHICAGO.', 'Chicago, IL', '2025-05-20 14:00:00', 'CARRIER_API'
FROM delivery_loads dl WHERE dl.load_number = 'LOAD-2025-001';

INSERT INTO transit_events (delivery_load_id, event_code, event_description, location, event_at, source)
SELECT dl.id, 'IN_TRANSIT', 'En route to Midwest stores.', 'Gary, IN', '2025-05-20 16:30:00', 'CARRIER_API'
FROM delivery_loads dl WHERE dl.load_number = 'LOAD-2025-001';

INSERT INTO transit_events (delivery_load_id, event_code, event_description, location, event_at, source)
SELECT dl.id, 'OUT_FOR_DELIVERY', 'Driver beginning Chicago stops.', 'Chicago, IL', '2025-05-28 08:00:00', 'CARRIER_API'
FROM delivery_loads dl WHERE dl.load_number = 'LOAD-2025-001';

INSERT INTO transit_events (delivery_load_id, event_code, event_description, location, event_at, source)
SELECT dl.id, 'DELIVERED', 'All Midwest stops completed.', 'Indianapolis, IN', '2025-05-30 14:30:00', 'CARRIER_API'
FROM delivery_loads dl WHERE dl.load_number = 'LOAD-2025-001';

-- ── TMS audit events ──────────────────────────────────────────────────────────
INSERT INTO tms_events (delivery_load_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'LOAD_CREATED', NULL, 'CREATED', 'Load created from WMS shipment dispatch event.', 'tms.coordinator', 1
FROM delivery_loads WHERE load_number = 'LOAD-2025-001';

INSERT INTO tms_events (delivery_load_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'LOAD_ASSIGNED', 'CREATED', 'ASSIGNED', 'Assigned to driver Mike Johnson, truck XPO-TRUCK-5521.', 'tms.coordinator', 0
FROM delivery_loads WHERE load_number = 'LOAD-2025-001';

INSERT INTO tms_events (delivery_load_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'LOAD_IN_TRANSIT', 'ASSIGNED', 'IN_TRANSIT', 'Driver picked up load from DC-CHICAGO. PRO XPO-2025-MW-0441.', 'xpo.carrier.api', 1
FROM delivery_loads WHERE load_number = 'LOAD-2025-001';

INSERT INTO tms_events (delivery_load_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'LOAD_COMPLETED', 'IN_TRANSIT', 'COMPLETED', 'All 4 Midwest stores delivered and POD confirmed.', 'tms.coordinator', 1
FROM delivery_loads WHERE load_number = 'LOAD-2025-001';
