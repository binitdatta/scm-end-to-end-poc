-- =============================================================================
-- cs_procurement SEED DATA
-- Run AFTER 01_ddl_cs_procurement.sql
-- Mirrors the awarded RFQs from cs_vendor seed data so the simulation
-- has pre-existing POs to work with from day one.
-- =============================================================================

USE cs_procurement;

-- ── Purchase Orders ───────────────────────────────────────────────────────────
-- PO-2025-001: Matches RFQ-2025-001 award (Vietnam vendor, 500k dinosaur figures)
-- We seed this as APPROVED so the test script can drive it forward
INSERT INTO purchase_orders (
    external_id, po_number,
    rfq_external_id, rfq_number, campaign_external_id, campaign_code, award_external_id,
    vendor_external_id, vendor_code, vendor_name, vendor_country,
    toy_description, quantity_ordered, unit_price_usd, total_value_usd, currency,
    payment_terms, required_delivery_date, estimated_ship_date,
    incoterms, destination_port, status, created_by, approved_by, approved_at, notes
) VALUES (
    'po-001-uuid', 'PO-2025-001',
    'rfq-001-uuid', 'RFQ-2025-001', 'camp-001-uuid', 'SUMMER25-TOY', 'award-001-uuid',
    'vnd-002-uuid', 'VND-VN-001', 'Ho Chi Minh Playthings Ltd.', 'VIETNAM',
    'Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise (500k units)',
    500000, 0.8200, 410000.00, 'USD',
    '50% upfront, 50% on shipment', '2025-04-30', '2025-04-01',
    'FOB', 'Port of Los Angeles', 'APPROVED',
    'procurement.manager', 'procurement.director', '2026-01-15 09:00:00',
    'Vietnam vendor awarded for fastest lead time (35 days) and ISO 9001 certification.'
);

-- PO-2025-002: Holiday 2025 collectibles (China vendor, 1.2M figurines) — DRAFT
INSERT INTO purchase_orders (
    external_id, po_number,
    rfq_external_id, rfq_number, campaign_external_id, campaign_code, award_external_id,
    vendor_external_id, vendor_code, vendor_name, vendor_country,
    toy_description, quantity_ordered, unit_price_usd, total_value_usd, currency,
    payment_terms, required_delivery_date, estimated_ship_date,
    incoterms, destination_port, status, created_by, notes
) VALUES (
    'po-002-uuid', 'PO-2025-002',
    'rfq-002-uuid', 'RFQ-2025-002', 'camp-002-uuid', 'HOLIDAY25-TOY', 'award-002-uuid',
    'vnd-001-uuid', 'VND-CN-001', 'Shenzhen BrightToy Manufacturing Co.', 'CHINA',
    'Holiday 2025 Collectible Figurines — 6 Character Series (1.2M units)',
    1200000, 0.7800, 936000.00, 'USD',
    'NET30', '2025-10-15', '2025-09-15',
    'CIF', 'Port of Long Beach', 'DRAFT',
    'procurement.manager',
    'Pending final approval from CFO due to order value exceeding $900k threshold.'
);

-- ── PO Line Items for PO-2025-001 ─────────────────────────────────────────────
INSERT INTO po_line_items (external_id, po_id, line_number, item_code, description, quantity, unit, unit_price_usd, line_total_usd)
VALUES
(
    'poli-001-uuid',
    (SELECT id FROM purchase_orders WHERE po_number = 'PO-2025-001'),
    1, 'TOY-DINO-MIX-001',
    'Dinosaur Figure Mystery Mix — 8 Variants (T-Rex, Triceratops, Brachiosaurus, Stegosaurus, Velociraptor, Pterodactyl, Ankylosaurus, Spinosaurus)',
    480000, 'PIECES', 0.8200, 393600.00
),
(
    'poli-002-uuid',
    (SELECT id FROM purchase_orders WHERE po_number = 'PO-2025-001'),
    2, 'PKG-SURPRISE-BOX-001',
    'Branded Surprise Box Packaging — printed cardboard with mystery design',
    500000, 'PIECES', 0.0320, 16000.00
),
(
    'poli-003-uuid',
    (SELECT id FROM purchase_orders WHERE po_number = 'PO-2025-001'),
    3, 'TOY-DINO-BONUS-001',
    'Bonus Rare Holographic Variant — limited 1-in-25 inclusion',
    20000, 'PIECES', 0.0200, 400.00
);

-- ── PO Events (audit trail) ───────────────────────────────────────────────────
INSERT INTO po_events (po_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'CREATED', NULL, 'DRAFT',
       'PO created from RFQ-2025-001 award. Vietnam vendor Ho Chi Minh Playthings selected.',
       'procurement.manager', 0
FROM purchase_orders WHERE po_number = 'PO-2025-001';

INSERT INTO po_events (po_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'APPROVED', 'DRAFT', 'APPROVED',
       'PO approved by procurement director. Budget confirmed. Ready to send to vendor.',
       'procurement.director', 1
FROM purchase_orders WHERE po_number = 'PO-2025-001';

INSERT INTO po_events (po_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'CREATED', NULL, 'DRAFT',
       'PO created from RFQ-2025-002 award. Pending CFO approval.',
       'procurement.manager', 0
FROM purchase_orders WHERE po_number = 'PO-2025-002';
