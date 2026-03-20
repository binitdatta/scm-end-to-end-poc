-- =============================================================================
-- cs_wms_inbound SEED DATA
-- Run AFTER 01_ddl_cs_wms_inbound.sql
-- Seeds two ASNs mirroring the procurement POs:
--   ASN-2025-001 → PO-2025-001 (Vietnam, 500k dino toys) — status ARRIVED
--   ASN-2025-002 → PO-2025-002 (China, 1.2M figurines)   — status SCHEDULED
-- =============================================================================

USE cs_wms_inbound;

-- ── ASNs ──────────────────────────────────────────────────────────────────────
INSERT INTO advance_shipment_notices (
    external_id, asn_number,
    po_external_id, po_number, campaign_external_id, campaign_code,
    vendor_external_id, vendor_code, vendor_name, vendor_country,
    sku, toy_description, expected_quantity, unit_of_measure,
    carrier_name, tracking_number, origin_port, destination_port, incoterms,
    estimated_arrival_date, actual_arrival_date, dock_appointment_date, dock_door,
    status, notes, created_by
) VALUES
(
    'asn-001-uuid', 'ASN-2025-001',
    'po-001-uuid', 'PO-2025-001', 'camp-001-uuid', 'SUMMER25-TOY',
    'vnd-002-uuid', 'VND-VN-001', 'Ho Chi Minh Playthings Ltd.', 'VIETNAM',
    'TOY-DINO-MIX-001',
    'Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',
    500000, 'PIECES',
    'OOCL Shipping', 'OOCL-VIET-20250401-8821',
    'Port of Ho Chi Minh City', 'Port of Los Angeles', 'FOB',
    '2025-05-05', '2025-05-05', '2025-05-06 08:00:00', 'DOOR-05',
    'ARRIVED',
    'Vessel OOCL EUROPE arrived on schedule. 500k cartons offloaded. Awaiting dock receiving.',
    'wms.inbound.coordinator'
),
(
    'asn-002-uuid', 'ASN-2025-002',
    'po-002-uuid', 'PO-2025-002', 'camp-002-uuid', 'HOLIDAY25-TOY',
    'vnd-001-uuid', 'VND-CN-001', 'Shenzhen BrightToy Manufacturing Co.', 'CHINA',
    'TOY-HOLIDAY-MIX-001',
    'Holiday 2025 Collectible Figurines — 6 Character Series',
    1200000, 'PIECES',
    'COSCO Shipping', 'COSCO-CN-20250915-4492',
    'Port of Shenzhen', 'Port of Long Beach', 'CIF',
    '2025-10-05', NULL, '2025-10-06 07:00:00', 'DOOR-03',
    'SCHEDULED',
    'Vessel departs Shenzhen Sept 15. ETA Long Beach Oct 5. Dock slot confirmed.',
    'wms.inbound.coordinator'
);

-- ── Receiving record for ASN-2025-001 ────────────────────────────────────────
-- We seed this with a small variance (-200 damaged) to make it realistic
INSERT INTO receiving_records (
    external_id, asn_id,
    received_quantity, damaged_quantity, rejected_quantity, accepted_quantity,
    variance_quantity, received_by, received_at, qc_passed, qc_notes
)
SELECT
    'rr-001-uuid',
    (SELECT id FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-001'),
    499800, 200, 0, 499800,
    -200,
    'warehouse.receiver.01', '2025-05-06 10:30:00',
    1,
    'Minor damage on 200 units from moisture. All rejected units documented. 499,800 accepted. QC PASSED.'
;

-- ── Putaway tasks for ASN-2025-001 ───────────────────────────────────────────
INSERT INTO putaway_tasks (external_id, asn_id, sku, quantity_to_putaway, quantity_putaway,
                           warehouse_zone, warehouse_aisle, warehouse_bin,
                           status, assigned_to, started_at, completed_at)
SELECT
    'pt-001-uuid',
    (SELECT id FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-001'),
    'TOY-DINO-MIX-001', 250000, 250000,
    'ZONE-A', 'A-01', 'BIN-A-01-001',
    'COMPLETED', 'forklift.op.01',
    '2025-05-06 11:00:00', '2025-05-06 14:00:00';

INSERT INTO putaway_tasks (external_id, asn_id, sku, quantity_to_putaway, quantity_putaway,
                           warehouse_zone, warehouse_aisle, warehouse_bin,
                           status, assigned_to, started_at, completed_at)
SELECT
    'pt-002-uuid',
    (SELECT id FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-001'),
    'TOY-DINO-MIX-001', 249800, 249800,
    'ZONE-A', 'A-02', 'BIN-A-02-001',
    'COMPLETED', 'forklift.op.02',
    '2025-05-06 11:00:00', '2025-05-06 15:30:00';

-- ── Update ASN-2025-001 to PUTAWAY_COMPLETED ──────────────────────────────────
UPDATE advance_shipment_notices
SET status = 'PUTAWAY_COMPLETED', actual_arrival_date = '2025-05-05'
WHERE asn_number = 'ASN-2025-001';

-- ── Inventory locations for putaway-completed ASN ────────────────────────────
INSERT INTO inventory_locations (sku, campaign_code, warehouse_zone, warehouse_aisle,
                                  warehouse_bin, quantity_on_hand, quantity_reserved,
                                  quantity_available, last_receipt_date)
VALUES
('TOY-DINO-MIX-001', 'SUMMER25-TOY', 'ZONE-A', 'A-01', 'BIN-A-01-001',
 250000, 0, 250000, '2025-05-06'),
('TOY-DINO-MIX-001', 'SUMMER25-TOY', 'ZONE-A', 'A-02', 'BIN-A-02-001',
 249800, 0, 249800, '2025-05-06');

-- ── ASN Events audit trail ────────────────────────────────────────────────────
INSERT INTO asn_events (asn_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'ASN_CREATED', NULL, 'CREATED',
       'ASN created from PO-2025-001 ready-to-ship event.', 'wms.inbound.coordinator', 1
FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-001';

INSERT INTO asn_events (asn_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'DOCK_SCHEDULED', 'CREATED', 'SCHEDULED',
       'Dock appointment confirmed: DOOR-05, 2025-05-06 08:00.', 'wms.inbound.coordinator', 1
FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-001';

INSERT INTO asn_events (asn_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'VESSEL_ARRIVED', 'SCHEDULED', 'ARRIVED',
       'OOCL EUROPE docked at Port of Los Angeles.', 'wms.inbound.coordinator', 1
FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-001';

INSERT INTO asn_events (asn_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'RECEIVING_COMPLETED', 'ARRIVED', 'RECEIVED',
       '499,800 units accepted. 200 damaged/rejected. QC passed.', 'warehouse.receiver.01', 1
FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-001';

INSERT INTO asn_events (asn_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'PUTAWAY_COMPLETED', 'RECEIVED', 'PUTAWAY_COMPLETED',
       '499,800 units stowed across ZONE-A BIN-A-01-001 and BIN-A-02-001.', 'warehouse.receiver.01', 1
FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-001';

-- ASN-2025-002 events
INSERT INTO asn_events (asn_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'ASN_CREATED', NULL, 'CREATED',
       'ASN created from PO-2025-002 ready-to-ship event.', 'wms.inbound.coordinator', 1
FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-002';

INSERT INTO asn_events (asn_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'DOCK_SCHEDULED', 'CREATED', 'SCHEDULED',
       'Dock appointment confirmed: DOOR-03, 2025-10-06 07:00.', 'wms.inbound.coordinator', 1
FROM advance_shipment_notices WHERE asn_number = 'ASN-2025-002';
