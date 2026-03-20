-- =============================================================================
-- cs_procurement DATABASE — DDL SCRIPT
-- Database: cs_procurement
-- Engine:   MySQL 8.x (InnoDB)
-- Charset:  utf8mb4
-- NOTE:     All schema changes are made HERE, not by the application.
--           Spring Boot connects as procurement_app with NO DDL privileges.
--
-- Domain story:
--   After cs-vendor-api awards an RFQ (erp.vendor.rfq.awarded event),
--   the Procurement ERP creates a Purchase Order (PO) against the winning vendor.
--   POs go through: DRAFT → APPROVED → SENT_TO_VENDOR → ACKNOWLEDGED →
--                   IN_PRODUCTION → READY_TO_SHIP → COMPLETED / CANCELLED
--   Each status transition publishes a RabbitMQ event consumed by the
--   Control Tower and downstream WMS/TMS services.
-- =============================================================================

-- ── 1. DATABASE ───────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS cs_procurement
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cs_procurement;

-- ── 2. APPLICATION USER ───────────────────────────────────────────────────────
CREATE USER IF NOT EXISTS 'procurement_app'@'localhost' IDENTIFIED BY 'ProcurementApp#2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON cs_procurement.* TO 'procurement_app'@'localhost';
FLUSH PRIVILEGES;

-- ── 3. TABLES ─────────────────────────────────────────────────────────────────

-- 3.1  purchase_orders
--      Core PO record. One PO per vendor per campaign sourcing decision.
CREATE TABLE IF NOT EXISTS purchase_orders (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id             VARCHAR(64)         NOT NULL,
    po_number               VARCHAR(50)         NOT NULL COMMENT 'e.g. PO-2025-001',

    -- Cross-service references (no FK — different databases)
    rfq_external_id         VARCHAR(64)         NOT NULL COMMENT 'cs_vendor.rfqs.external_id',
    rfq_number              VARCHAR(50)         NOT NULL,
    campaign_external_id    VARCHAR(64)         NOT NULL COMMENT 'cs_crm.campaigns.external_id',
    campaign_code           VARCHAR(50)         NOT NULL,
    award_external_id       VARCHAR(64)         NOT NULL COMMENT 'cs_vendor.rfq_awards.external_id',

    -- Vendor details (denormalized — vendor lives in cs_vendor DB)
    vendor_external_id      VARCHAR(64)         NOT NULL,
    vendor_code             VARCHAR(50)         NOT NULL,
    vendor_name             VARCHAR(200)        NOT NULL,
    vendor_country          ENUM('CHINA','VIETNAM','INDIA','THAILAND','OTHER') NOT NULL,

    -- Line item details
    toy_description         VARCHAR(200)        NOT NULL,
    quantity_ordered        INT UNSIGNED        NOT NULL,
    unit_price_usd          DECIMAL(10,4)       NOT NULL,
    total_value_usd         DECIMAL(15,2)       NOT NULL,
    currency                VARCHAR(10)         NOT NULL DEFAULT 'USD',

    -- Logistics
    payment_terms           VARCHAR(100)            NULL,
    required_delivery_date  DATE                NOT NULL COMMENT 'Must arrive at DC by this date',
    estimated_ship_date     DATE                    NULL,
    incoterms               VARCHAR(20)             NULL COMMENT 'e.g. FOB, CIF, EXW',
    destination_port        VARCHAR(100)            NULL COMMENT 'e.g. Port of Los Angeles',

    -- Lifecycle
    status                  ENUM('DRAFT','APPROVED','SENT_TO_VENDOR','ACKNOWLEDGED',
                                 'IN_PRODUCTION','READY_TO_SHIP','COMPLETED','CANCELLED')
                            NOT NULL DEFAULT 'DRAFT',
    created_by              VARCHAR(100)        NOT NULL,
    approved_by             VARCHAR(100)            NULL,
    approved_at             DATETIME                NULL,
    notes                   TEXT                    NULL,

    created_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_purchase_orders           PRIMARY KEY (id),
    CONSTRAINT uq_po_external_id            UNIQUE (external_id),
    CONSTRAINT uq_po_number                 UNIQUE (po_number),
    CONSTRAINT uq_po_award                  UNIQUE (award_external_id) COMMENT 'One PO per award'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2  po_line_items
--      Itemized breakdown within a PO (toy SKU, packaging, labelling etc.)
CREATE TABLE IF NOT EXISTS po_line_items (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    po_id               BIGINT UNSIGNED     NOT NULL,
    line_number         INT UNSIGNED        NOT NULL,
    item_code           VARCHAR(50)         NOT NULL COMMENT 'Internal SKU / item code',
    description         VARCHAR(200)        NOT NULL,
    quantity            INT UNSIGNED        NOT NULL,
    unit                VARCHAR(30)         NOT NULL DEFAULT 'PIECES',
    unit_price_usd      DECIMAL(10,4)       NOT NULL,
    line_total_usd      DECIMAL(15,2)       NOT NULL,
    CONSTRAINT pk_po_line_items             PRIMARY KEY (id),
    CONSTRAINT uq_poli_external_id          UNIQUE (external_id),
    CONSTRAINT uq_poli_po_line              UNIQUE (po_id, line_number),
    CONSTRAINT fk_poli_po                   FOREIGN KEY (po_id) REFERENCES purchase_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3  po_events  (full audit trail of every PO status transition)
CREATE TABLE IF NOT EXISTS po_events (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    po_id               BIGINT UNSIGNED     NOT NULL,
    event_type          VARCHAR(80)         NOT NULL,
    previous_status     VARCHAR(30)             NULL,
    new_status          VARCHAR(30)         NOT NULL,
    notes               TEXT                    NULL,
    triggered_by        VARCHAR(100)        NOT NULL,
    event_at            DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rabbitmq_published  TINYINT(1)          NOT NULL DEFAULT 0,
    CONSTRAINT pk_po_events                 PRIMARY KEY (id),
    CONSTRAINT fk_poe_po                    FOREIGN KEY (po_id) REFERENCES purchase_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.4  invoices
--      Vendor invoice against a PO — received after shipment.
CREATE TABLE IF NOT EXISTS invoices (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    invoice_number      VARCHAR(50)         NOT NULL,
    po_id               BIGINT UNSIGNED     NOT NULL,
    vendor_external_id  VARCHAR(64)         NOT NULL,
    invoice_amount_usd  DECIMAL(15,2)       NOT NULL,
    tax_amount_usd      DECIMAL(15,2)       NOT NULL DEFAULT 0.00,
    total_amount_usd    DECIMAL(15,2)       NOT NULL,
    invoice_date        DATE                NOT NULL,
    due_date            DATE                NOT NULL,
    status              ENUM('RECEIVED','UNDER_REVIEW','APPROVED','PAID','DISPUTED')
                        NOT NULL DEFAULT 'RECEIVED',
    paid_at             DATETIME                NULL,
    notes               TEXT                    NULL,
    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_invoices                  PRIMARY KEY (id),
    CONSTRAINT uq_inv_external_id           UNIQUE (external_id),
    CONSTRAINT uq_inv_number                UNIQUE (invoice_number),
    CONSTRAINT fk_inv_po                    FOREIGN KEY (po_id) REFERENCES purchase_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. INDEXES ────────────────────────────────────────────────────────────────
CREATE INDEX idx_po_status              ON purchase_orders(status);
CREATE INDEX idx_po_vendor              ON purchase_orders(vendor_external_id);
CREATE INDEX idx_po_campaign            ON purchase_orders(campaign_external_id);
CREATE INDEX idx_po_rfq                 ON purchase_orders(rfq_external_id);
CREATE INDEX idx_po_delivery_date       ON purchase_orders(required_delivery_date);
CREATE INDEX idx_poli_po_id             ON po_line_items(po_id);
CREATE INDEX idx_poe_po_id              ON po_events(po_id);
CREATE INDEX idx_poe_event_type         ON po_events(event_type);
CREATE INDEX idx_inv_po_id              ON invoices(po_id);
CREATE INDEX idx_inv_status             ON invoices(status);
CREATE INDEX idx_inv_vendor             ON invoices(vendor_external_id);
