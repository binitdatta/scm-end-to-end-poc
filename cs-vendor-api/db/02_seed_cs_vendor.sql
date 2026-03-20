-- =============================================================================
-- cs_vendor SEED DATA
-- Run AFTER 01_ddl_cs_vendor.sql
-- =============================================================================

USE cs_vendor;

-- ── Vendors ───────────────────────────────────────────────────────────────────
INSERT INTO vendors (external_id, vendor_name, vendor_code, country, contact_name, contact_email,
                     contact_phone, address, status, category, lead_time_days, payment_terms, scorecard_rating)
VALUES
(
    'vnd-001-uuid', 'Shenzhen BrightToy Manufacturing Co.', 'VND-CN-001', 'CHINA',
    'Wei Zhang', 'wei.zhang@brighttoy.cn', '+86-755-8801-2233',
    '18 Longhua Industrial Zone, Shenzhen, Guangdong, China 518109',
    'ACTIVE', 'TOY_MANUFACTURER', 45, 'NET30', 4.20
),
(
    'vnd-002-uuid', 'Ho Chi Minh Playthings Ltd.', 'VND-VN-001', 'VIETNAM',
    'Nguyen Thi Lan', 'lan.nguyen@hcmplaythings.vn', '+84-28-3822-5511',
    '45 Tan Binh Industrial Park, Ho Chi Minh City, Vietnam',
    'ACTIVE', 'TOY_MANUFACTURER', 38, '50% upfront, 50% on shipment', 4.50
),
(
    'vnd-003-uuid', 'Pune Creative Toys Pvt. Ltd.', 'VND-IN-001', 'INDIA',
    'Rajesh Mehta', 'rajesh.mehta@punecreative.in', '+91-20-2712-8899',
    'Plot 22, Bhosari MIDC Industrial Area, Pune, Maharashtra 411026, India',
    'ACTIVE', 'TOY_MANUFACTURER', 55, 'NET45', 3.90
),
(
    'vnd-004-uuid', 'Bangkok Fun Factory Co. Ltd.', 'VND-TH-001', 'THAILAND',
    'Somchai Wattana', 'somchai@bangkokfun.co.th', '+66-2-685-4400',
    '99 Moo 4, Amata City Industrial Estate, Chonburi 20160, Thailand',
    'ACTIVE', 'TOY_MANUFACTURER', 42, 'NET30', 4.75
),
(
    'vnd-005-uuid', 'Guangzhou PackMaster Co.', 'VND-CN-002', 'CHINA',
    'Li Mei', 'limei@gzpackmaster.cn', '+86-20-6601-3344',
    '88 Panyu Economic Development Zone, Guangzhou, China 511400',
    'ACTIVE', 'PACKAGING', 30, 'NET30', 4.00
),
(
    'vnd-006-uuid', 'Hanoi Precision Plastics', 'VND-VN-002', 'VIETNAM',
    'Tran Van Duc', 'duc.tran@hanoiplastics.vn', '+84-24-3826-7700',
    '12 Quang Minh Industrial Zone, Me Linh, Hanoi, Vietnam',
    'ACTIVE', 'TOY_MANUFACTURER', 40, 'NET30', 4.10
),
(
    'vnd-007-uuid', 'Chennai Toy Crafts Ltd.', 'VND-IN-002', 'INDIA',
    'Priya Rajan', 'priya@chennaicrafts.in', '+91-44-2431-5566',
    'No. 7 SIDCO Industrial Estate, Ambattur, Chennai 600058, India',
    'INACTIVE', 'TOY_MANUFACTURER', 60, 'NET60', 3.20
);

-- ── RFQs ─────────────────────────────────────────────────────────────────────
INSERT INTO rfqs (external_id, rfq_number, campaign_external_id, campaign_code,
                  title, description, toy_category, quantity_required, unit,
                  target_unit_cost_usd, required_by_date, submission_deadline,
                  status, created_by)
VALUES
(
    'rfq-001-uuid', 'RFQ-2025-001', 'camp-001-uuid', 'SUMMER25-TOY',
    'Summer 2025 Toy Surprise — Dinosaur Figure Series',
    'Sourcing 500,000 mystery dinosaur figures for kids meal toy surprise campaign. '
    'Must meet CPSC safety standards. Individually packaged in branded surprise box.',
    'Dinosaur Figures', 500000, 'PIECES',
    0.85, '2025-04-30', '2025-02-28',
    'OPEN', 'procurement.manager'
),
(
    'rfq-002-uuid', 'RFQ-2025-002', 'camp-002-uuid', 'HOLIDAY25-TOY',
    'Holiday 2025 — Collectible Figurine Series (6 Characters)',
    'Sourcing 1,200,000 collectible holiday figurines across 6 character designs. '
    'Premium finish required. Full color box packaging included.',
    'Collectible Figurines', 1200000, 'PIECES',
    1.20, '2025-10-15', '2025-07-31',
    'DRAFT', 'procurement.manager'
);

-- ── Invite vendors to RFQ-2025-001 ───────────────────────────────────────────
INSERT INTO rfq_vendors (rfq_id, vendor_id)
SELECT
    (SELECT id FROM rfqs WHERE rfq_number = 'RFQ-2025-001'),
    v.id
FROM vendors v
WHERE v.vendor_code IN ('VND-CN-001', 'VND-VN-001', 'VND-TH-001', 'VND-IN-001')
  AND v.status = 'ACTIVE';

-- ── Vendor Quotes for RFQ-2025-001 ───────────────────────────────────────────
-- China vendor quote
INSERT INTO vendor_quotes (external_id, rfq_id, vendor_id, quoted_unit_cost_usd,
                           quoted_quantity, total_cost_usd, lead_time_days,
                           delivery_date, payment_terms, notes, status)
SELECT
    'quote-001-uuid',
    (SELECT id FROM rfqs WHERE rfq_number = 'RFQ-2025-001'),
    (SELECT id FROM vendors WHERE vendor_code = 'VND-CN-001'),
    0.78, 500000, 390000.00, 42, '2025-04-20', 'NET30',
    'Can produce all 500k units in single production run. CPSC test reports available.',
    'SUBMITTED';

-- Vietnam vendor quote
INSERT INTO vendor_quotes (external_id, rfq_id, vendor_id, quoted_unit_cost_usd,
                           quoted_quantity, total_cost_usd, lead_time_days,
                           delivery_date, payment_terms, notes, status)
SELECT
    'quote-002-uuid',
    (SELECT id FROM rfqs WHERE rfq_number = 'RFQ-2025-001'),
    (SELECT id FROM vendors WHERE vendor_code = 'VND-VN-001'),
    0.82, 500000, 410000.00, 35, '2025-04-15', '50% upfront, 50% on shipment',
    'Faster lead time. ISO 9001 certified facility. Free sample set available.',
    'SUBMITTED';

-- Thailand vendor quote
INSERT INTO vendor_quotes (external_id, rfq_id, vendor_id, quoted_unit_cost_usd,
                           quoted_quantity, total_cost_usd, lead_time_days,
                           delivery_date, payment_terms, notes, status)
SELECT
    'quote-003-uuid',
    (SELECT id FROM rfqs WHERE rfq_number = 'RFQ-2025-001'),
    (SELECT id FROM vendors WHERE vendor_code = 'VND-TH-001'),
    0.91, 500000, 455000.00, 40, '2025-04-25', 'NET30',
    'Premium quality finish. Highest rated vendor. Slightly above target cost.',
    'SUBMITTED';

-- India vendor quote
INSERT INTO vendor_quotes (external_id, rfq_id, vendor_id, quoted_unit_cost_usd,
                           quoted_quantity, total_cost_usd, lead_time_days,
                           delivery_date, payment_terms, notes, status)
SELECT
    'quote-004-uuid',
    (SELECT id FROM rfqs WHERE rfq_number = 'RFQ-2025-001'),
    (SELECT id FROM vendors WHERE vendor_code = 'VND-IN-001'),
    0.72, 500000, 360000.00, 52, '2025-04-28', 'NET45',
    'Lowest cost but longest lead time. Recommend for split order consideration.',
    'SUBMITTED';
