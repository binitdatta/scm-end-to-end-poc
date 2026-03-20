-- =============================================================================
-- cs_oms SEED DATA
-- Run AFTER 01_ddl_cs_oms.sql
-- Seeds 6 US regions, 20 representative stores, inventory availability
-- mirroring what cs-wms-inbound-api has put away, and 2 seeded store orders.
-- =============================================================================

USE cs_oms;

-- ── Store Regions ─────────────────────────────────────────────────────────────
INSERT INTO store_regions (external_id, region_code, region_name, store_count, distribution_dc, status) VALUES
('reg-001-uuid', 'US-MIDWEST',    'Midwest United States',      640, 'DC-CHICAGO',       'ACTIVE'),
('reg-002-uuid', 'US-WEST',       'Western United States',       580, 'DC-LOS-ANGELES',   'ACTIVE'),
('reg-003-uuid', 'US-SOUTHEAST',  'Southeast United States',     520, 'DC-ATLANTA',       'ACTIVE'),
('reg-004-uuid', 'US-NORTHEAST',  'Northeast United States',     480, 'DC-NEW-YORK',      'ACTIVE'),
('reg-005-uuid', 'US-SOUTHWEST',  'Southwest United States',     440, 'DC-DALLAS',        'ACTIVE'),
('reg-006-uuid', 'US-NORTHWEST',  'Northwest United States',     540, 'DC-SEATTLE',       'ACTIVE');

-- ── Stores — representative sample across all regions ─────────────────────────
-- Midwest (reg-001)
INSERT INTO stores (external_id, store_number, store_name, region_id, address, city, state_code, zip_code, status) VALUES
('str-001-uuid','STR-0001','Burger Bliss Chicago Downtown',   (SELECT id FROM store_regions WHERE region_code='US-MIDWEST'),  '100 N Michigan Ave',     'Chicago',       'IL','60601','ACTIVE'),
('str-002-uuid','STR-0002','Burger Bliss Naperville',          (SELECT id FROM store_regions WHERE region_code='US-MIDWEST'),  '204 S Washington St',    'Naperville',    'IL','60540','ACTIVE'),
('str-003-uuid','STR-0003','Burger Bliss Milwaukee',           (SELECT id FROM store_regions WHERE region_code='US-MIDWEST'),  '780 N Water St',         'Milwaukee',     'WI','53202','ACTIVE'),
('str-004-uuid','STR-0004','Burger Bliss Indianapolis',        (SELECT id FROM store_regions WHERE region_code='US-MIDWEST'),  '1 Monument Circle',      'Indianapolis',  'IN','46204','ACTIVE');

-- West (reg-002)
INSERT INTO stores (external_id, store_number, store_name, region_id, address, city, state_code, zip_code, status) VALUES
('str-005-uuid','STR-0101','Burger Bliss Los Angeles Downtown',(SELECT id FROM store_regions WHERE region_code='US-WEST'),    '333 S Grand Ave',        'Los Angeles',   'CA','90071','ACTIVE'),
('str-006-uuid','STR-0102','Burger Bliss San Francisco',       (SELECT id FROM store_regions WHERE region_code='US-WEST'),    '1 Market St',            'San Francisco', 'CA','94105','ACTIVE'),
('str-007-uuid','STR-0103','Burger Bliss Las Vegas Strip',     (SELECT id FROM store_regions WHERE region_code='US-WEST'),    '3700 Las Vegas Blvd S',  'Las Vegas',     'NV','89109','ACTIVE'),
('str-008-uuid','STR-0104','Burger Bliss Phoenix',             (SELECT id FROM store_regions WHERE region_code='US-WEST'),    '201 E Washington St',    'Phoenix',       'AZ','85004','ACTIVE');

-- Southeast (reg-003)
INSERT INTO stores (external_id, store_number, store_name, region_id, address, city, state_code, zip_code, status) VALUES
('str-009-uuid','STR-0201','Burger Bliss Atlanta Midtown',     (SELECT id FROM store_regions WHERE region_code='US-SOUTHEAST'),'848 Peachtree St NE',   'Atlanta',       'GA','30308','ACTIVE'),
('str-010-uuid','STR-0202','Burger Bliss Miami Brickell',      (SELECT id FROM store_regions WHERE region_code='US-SOUTHEAST'),'1221 Brickell Ave',     'Miami',         'FL','33131','ACTIVE'),
('str-011-uuid','STR-0203','Burger Bliss Charlotte',           (SELECT id FROM store_regions WHERE region_code='US-SOUTHEAST'),'100 N Tryon St',        'Charlotte',     'NC','28202','ACTIVE'),
('str-012-uuid','STR-0204','Burger Bliss Nashville',           (SELECT id FROM store_regions WHERE region_code='US-SOUTHEAST'),'209 10th Ave S',        'Nashville',     'TN','37203','ACTIVE');

-- Northeast (reg-004)
INSERT INTO stores (external_id, store_number, store_name, region_id, address, city, state_code, zip_code, status) VALUES
('str-013-uuid','STR-0301','Burger Bliss New York Midtown',    (SELECT id FROM store_regions WHERE region_code='US-NORTHEAST'),'1 Times Square',        'New York',      'NY','10036','ACTIVE'),
('str-014-uuid','STR-0302','Burger Bliss Boston',              (SELECT id FROM store_regions WHERE region_code='US-NORTHEAST'),'100 Boylston St',       'Boston',        'MA','02116','ACTIVE'),
('str-015-uuid','STR-0303','Burger Bliss Philadelphia',        (SELECT id FROM store_regions WHERE region_code='US-NORTHEAST'),'1700 Market St',        'Philadelphia',  'PA','19103','ACTIVE'),
('str-016-uuid','STR-0304','Burger Bliss Washington DC',       (SELECT id FROM store_regions WHERE region_code='US-NORTHEAST'),'1000 Vermont Ave NW',   'Washington',    'DC','20005','ACTIVE');

-- Southwest (reg-005)
INSERT INTO stores (external_id, store_number, store_name, region_id, address, city, state_code, zip_code, status) VALUES
('str-017-uuid','STR-0401','Burger Bliss Dallas Uptown',       (SELECT id FROM store_regions WHERE region_code='US-SOUTHWEST'),'3699 McKinney Ave',     'Dallas',        'TX','75204','ACTIVE'),
('str-018-uuid','STR-0402','Burger Bliss Houston Galleria',    (SELECT id FROM store_regions WHERE region_code='US-SOUTHWEST'),'5015 Westheimer Rd',    'Houston',       'TX','77056','ACTIVE');

-- Northwest (reg-006)
INSERT INTO stores (external_id, store_number, store_name, region_id, address, city, state_code, zip_code, status) VALUES
('str-019-uuid','STR-0501','Burger Bliss Seattle Pike Place',  (SELECT id FROM store_regions WHERE region_code='US-NORTHWEST'),'1428 Post Alley',       'Seattle',       'WA','98101','ACTIVE'),
('str-020-uuid','STR-0502','Burger Bliss Portland',            (SELECT id FROM store_regions WHERE region_code='US-NORTHWEST'),'SW 5th & Morrison',     'Portland',      'OR','97204','ACTIVE');

-- ── Inventory Availability ────────────────────────────────────────────────────
-- Mirrors what cs-wms-inbound-api put away (putaway.completed events)
INSERT INTO inventory_availability (sku, campaign_code, quantity_available, quantity_reserved, quantity_remaining, source_asn_number) VALUES
('TOY-DINO-MIX-001',  'SUMMER25-TOY', 499800, 0, 499800, 'ASN-2025-001'),
('TOY-SPACE-MIX-001', 'SUMMER25-TOY', 249950, 0, 249950, 'ASN-2025-003');

-- ── Seeded Store Orders ───────────────────────────────────────────────────────
-- ORD-2025-001: Midwest allocation of DINO toys — already ALLOCATED
INSERT INTO store_orders (
    external_id, order_number, campaign_external_id, campaign_code,
    region_id, sku, toy_description,
    quantity_requested, quantity_allocated, quantity_per_store,
    requested_delivery_date, allocated_at, status, created_by, notes
) VALUES (
    'ord-001-uuid', 'ORD-2025-001', 'camp-001-uuid', 'SUMMER25-TOY',
    (SELECT id FROM store_regions WHERE region_code = 'US-MIDWEST'),
    'TOY-DINO-MIX-001',
    'Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',
    128000, 128000, 200,
    '2025-06-01', '2026-01-20 09:00:00',
    'ALLOCATED', 'oms.planner',
    'Midwest allocation: 640 stores x 200 units each. Reserved from ASN-2025-001.'
);

-- ORD-2025-002: West allocation of DINO toys — DRAFT, pending submission
INSERT INTO store_orders (
    external_id, order_number, campaign_external_id, campaign_code,
    region_id, sku, toy_description,
    quantity_requested, quantity_allocated, quantity_per_store,
    requested_delivery_date, status, created_by, notes
) VALUES (
    'ord-002-uuid', 'ORD-2025-002', 'camp-001-uuid', 'SUMMER25-TOY',
    (SELECT id FROM store_regions WHERE region_code = 'US-WEST'),
    'TOY-DINO-MIX-001',
    'Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',
    116000, 0, NULL,
    '2025-06-01',
    'DRAFT', 'oms.planner',
    'West allocation: 580 stores x 200 units each. Pending submission and allocation.'
);

-- ── Seed order lines for ORD-2025-001 (Midwest, 4 sample stores) ─────────────
INSERT INTO store_order_lines (external_id, store_order_id, store_id, sku, quantity_allocated, status)
SELECT
    CONCAT('sol-', s.store_number, '-001'),
    (SELECT id FROM store_orders WHERE order_number = 'ORD-2025-001'),
    s.id,
    'TOY-DINO-MIX-001',
    200,
    'ALLOCATED'
FROM stores s
WHERE s.region_id = (SELECT id FROM store_regions WHERE region_code = 'US-MIDWEST');

-- ── Reserve inventory for ORD-2025-001 ───────────────────────────────────────
UPDATE inventory_availability
SET quantity_reserved  = 128000,
    quantity_remaining = quantity_available - 128000
WHERE sku = 'TOY-DINO-MIX-001' AND campaign_code = 'SUMMER25-TOY';

-- ── Order events for seeded orders ───────────────────────────────────────────
INSERT INTO order_events (store_order_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'ORDER_CREATED', NULL, 'DRAFT', 'Store order created for Midwest region.', 'oms.planner', 0
FROM store_orders WHERE order_number = 'ORD-2025-001';

INSERT INTO order_events (store_order_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'ORDER_SUBMITTED', 'DRAFT', 'SUBMITTED', 'Order submitted for allocation.', 'oms.planner', 0
FROM store_orders WHERE order_number = 'ORD-2025-001';

INSERT INTO order_events (store_order_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'ORDER_ALLOCATED', 'SUBMITTED', 'ALLOCATED',
    '640 stores x 200 units. Total 128,000 units reserved from TOY-DINO-MIX-001.',
    'oms.system', 1
FROM store_orders WHERE order_number = 'ORD-2025-001';

INSERT INTO order_events (store_order_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'ORDER_CREATED', NULL, 'DRAFT', 'Store order created for West region.', 'oms.planner', 0
FROM store_orders WHERE order_number = 'ORD-2025-002';
