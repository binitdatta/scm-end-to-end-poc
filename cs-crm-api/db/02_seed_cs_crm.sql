-- =============================================================================
-- cs_crm SEED DATA
-- Run AFTER 01_ddl_cs_crm.sql
-- =============================================================================

USE cs_crm;

-- ── Customers ─────────────────────────────────────────────────────────────────
INSERT INTO customers (external_id, first_name, last_name, email, phone, tier, status) VALUES
('cust-001-uuid', 'Sarah',   'Mitchell',  'sarah.mitchell@example.com',  '312-555-0101', 'PLATINUM', 'ACTIVE'),
('cust-002-uuid', 'James',   'Hargrove',  'james.hargrove@example.com',  '773-555-0102', 'GOLD',     'ACTIVE'),
('cust-003-uuid', 'Maria',   'Delgado',   'maria.delgado@example.com',   '847-555-0103', 'STANDARD', 'ACTIVE'),
('cust-004-uuid', 'Kevin',   'Okafor',    'kevin.okafor@example.com',    '630-555-0104', 'GOLD',     'ACTIVE'),
('cust-005-uuid', 'Linda',   'Fujimoto',  'linda.fujimoto@example.com',  '312-555-0105', 'PLATINUM', 'ACTIVE'),
('cust-006-uuid', 'Thomas',  'Brennan',   'thomas.brennan@example.com',  '708-555-0106', 'STANDARD', 'INACTIVE'),
('cust-007-uuid', 'Aisha',   'Rahman',    'aisha.rahman@example.com',    '773-555-0107', 'GOLD',     'ACTIVE'),
('cust-008-uuid', 'Carlos',  'Espinoza',  'carlos.espinoza@example.com', '312-555-0108', 'STANDARD', 'ACTIVE'),
('cust-009-uuid', 'Priya',   'Sharma',    'priya.sharma@example.com',    '847-555-0109', 'PLATINUM', 'ACTIVE'),
('cust-010-uuid', 'Derek',   'Walton',    'derek.walton@example.com',    '630-555-0110', 'STANDARD', 'ACTIVE');

-- ── Campaigns ─────────────────────────────────────────────────────────────────
INSERT INTO campaigns (external_id, campaign_name, campaign_code, description, campaign_type, status, budget_usd, start_date, end_date, target_region, created_by) VALUES
(
    'camp-001-uuid',
    'Summer Surprise 2025',
    'SUMMER25-TOY',
    'Kids meal toy surprise campaign for summer 2025. Toys sourced from Thailand and Vietnam vendors. Packaged as a mystery surprise inside every kids meal.',
    'TOY_SURPRISE',
    'DRAFT',
    750000.00,
    '2025-06-01',
    '2025-08-31',
    'NATIONAL',
    'admin'
),
(
    'camp-002-uuid',
    'Holiday Collectibles 2025',
    'HOLIDAY25-TOY',
    'Winter holiday collectible toy series. Limited edition figurines across 6 characters. Sourced from China vendor.',
    'TOY_SURPRISE',
    'DRAFT',
    1200000.00,
    '2025-11-15',
    '2025-12-31',
    'NATIONAL',
    'admin'
),
(
    'camp-003-uuid',
    'Spring Loyalty Boost',
    'SPRING25-LOYAL',
    'Loyalty points double-up promotion for Gold and Platinum customers during spring.',
    'LOYALTY',
    'DRAFT',
    200000.00,
    '2025-03-20',
    '2025-05-31',
    'US-MIDWEST',
    'admin'
);

-- ── Campaign Events (initial DRAFT audit entries) ─────────────────────────────
INSERT INTO campaign_events (campaign_id, event_type, previous_status, new_status, notes, triggered_by, rabbitmq_published)
SELECT id, 'CREATED', NULL, 'DRAFT', 'Campaign record created via seed', 'admin', 0
FROM campaigns;

-- ── Enroll some customers into Summer Surprise ────────────────────────────────
INSERT INTO campaign_customers (campaign_id, customer_id, enrollment_channel)
SELECT
    (SELECT id FROM campaigns WHERE campaign_code = 'SUMMER25-TOY'),
    c.id,
    'SYSTEM'
FROM customers c
WHERE c.tier IN ('GOLD', 'PLATINUM') AND c.status = 'ACTIVE';
