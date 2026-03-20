-- =============================================================================
-- cs_wms_inbound DATABASE — DDL SCRIPT
-- Database: cs_wms_inbound
-- Engine:   MySQL 8.x (InnoDB)
-- Charset:  utf8mb4
-- NOTE:     All schema changes are made HERE, not by the application.
--           Spring Boot connects as wms_inbound_app with NO DDL privileges.
--
-- Domain story:
--   When cs-procurement-api publishes erp.procurement.po.ready-to-ship,
--   this WMS service creates an ASN (Advance Shipment Notice), schedules
--   a dock appointment, receives the physical shipment, performs QC,
--   and triggers put-away into warehouse locations.
--
--   Key outbound event: erp.wms.inbound.putaway.completed
--   → consumed by cs-oms-api to update available inventory for store allocation
-- =============================================================================

-- ── 1. DATABASE ───────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS cs_wms_inbound
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cs_wms_inbound;

-- ── 2. APPLICATION USER ───────────────────────────────────────────────────────
CREATE USER IF NOT EXISTS 'wms_inbound_app'@'localhost' IDENTIFIED BY 'WmsInbound#2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON cs_wms_inbound.* TO 'wms_inbound_app'@'localhost';
FLUSH PRIVILEGES;

-- ── 3. TABLES ─────────────────────────────────────────────────────────────────

-- 3.1  advance_shipment_notices (ASN)
--      Created when procurement signals po.ready-to-ship.
--      Represents expected inbound shipment before physical arrival.
CREATE TABLE IF NOT EXISTS advance_shipment_notices (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id             VARCHAR(64)         NOT NULL,
    asn_number              VARCHAR(50)         NOT NULL COMMENT 'e.g. ASN-2025-001',

    -- Cross-service references
    po_external_id          VARCHAR(64)         NOT NULL COMMENT 'cs_procurement.purchase_orders.external_id',
    po_number               VARCHAR(50)         NOT NULL,
    campaign_external_id    VARCHAR(64)         NOT NULL,
    campaign_code           VARCHAR(50)         NOT NULL,
    vendor_external_id      VARCHAR(64)         NOT NULL,
    vendor_code             VARCHAR(50)         NOT NULL,
    vendor_name             VARCHAR(200)        NOT NULL,
    vendor_country          VARCHAR(20)         NOT NULL,

    -- Shipment details
    sku                     VARCHAR(50)         NOT NULL COMMENT 'Internal toy SKU',
    toy_description         VARCHAR(200)        NOT NULL,
    expected_quantity       INT UNSIGNED        NOT NULL,
    unit_of_measure         VARCHAR(20)         NOT NULL DEFAULT 'PIECES',
    carrier_name            VARCHAR(100)            NULL,
    tracking_number         VARCHAR(100)            NULL COMMENT 'Vessel / AWB / PRO number',
    origin_port             VARCHAR(100)            NULL,
    destination_port        VARCHAR(100)            NULL,
    incoterms               VARCHAR(20)             NULL,

    -- Dates
    estimated_arrival_date  DATE                    NULL,
    actual_arrival_date     DATE                    NULL,
    dock_appointment_date   DATETIME                NULL,
    dock_door               VARCHAR(10)             NULL COMMENT 'e.g. DOOR-05',

    -- Lifecycle
    status                  ENUM('CREATED','SCHEDULED','IN_TRANSIT','ARRIVED',
                                 'RECEIVING','RECEIVED','PUTAWAY_IN_PROGRESS',
                                 'PUTAWAY_COMPLETED','CANCELLED')
                            NOT NULL DEFAULT 'CREATED',
    notes                   TEXT                    NULL,
    created_by              VARCHAR(100)        NOT NULL,
    created_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_asn               PRIMARY KEY (id),
    CONSTRAINT uq_asn_external_id   UNIQUE (external_id),
    CONSTRAINT uq_asn_number        UNIQUE (asn_number),
    CONSTRAINT uq_asn_po            UNIQUE (po_external_id) COMMENT 'One ASN per PO'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2  receiving_records
--      Physical count recorded at the dock when shipment arrives.
CREATE TABLE IF NOT EXISTS receiving_records (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id             VARCHAR(64)         NOT NULL,
    asn_id                  BIGINT UNSIGNED     NOT NULL,
    received_quantity       INT UNSIGNED        NOT NULL,
    damaged_quantity        INT UNSIGNED        NOT NULL DEFAULT 0,
    rejected_quantity       INT UNSIGNED        NOT NULL DEFAULT 0,
    accepted_quantity       INT UNSIGNED        NOT NULL,
    variance_quantity       INT                     NULL COMMENT 'received - expected (can be negative)',
    received_by             VARCHAR(100)        NOT NULL,
    received_at             DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    qc_passed               TINYINT(1)          NOT NULL DEFAULT 0,
    qc_notes                TEXT                    NULL,
    CONSTRAINT pk_rr                PRIMARY KEY (id),
    CONSTRAINT uq_rr_external_id    UNIQUE (external_id),
    CONSTRAINT uq_rr_asn            UNIQUE (asn_id) COMMENT 'One receiving record per ASN',
    CONSTRAINT fk_rr_asn            FOREIGN KEY (asn_id) REFERENCES advance_shipment_notices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3  putaway_tasks
--      Directs forklift/operator to move received items to warehouse locations.
CREATE TABLE IF NOT EXISTS putaway_tasks (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id             VARCHAR(64)         NOT NULL,
    asn_id                  BIGINT UNSIGNED     NOT NULL,
    sku                     VARCHAR(50)         NOT NULL,
    quantity_to_putaway     INT UNSIGNED        NOT NULL,
    quantity_putaway        INT UNSIGNED        NOT NULL DEFAULT 0,
    warehouse_zone          VARCHAR(20)         NOT NULL COMMENT 'e.g. ZONE-A, ZONE-B',
    warehouse_aisle         VARCHAR(10)             NULL COMMENT 'e.g. A-12',
    warehouse_bin           VARCHAR(20)             NULL COMMENT 'e.g. BIN-A-12-003',
    status                  ENUM('PENDING','IN_PROGRESS','COMPLETED','CANCELLED')
                            NOT NULL DEFAULT 'PENDING',
    assigned_to             VARCHAR(100)            NULL,
    started_at              DATETIME                NULL,
    completed_at            DATETIME                NULL,
    created_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_putaway           PRIMARY KEY (id),
    CONSTRAINT uq_putaway_ext_id    UNIQUE (external_id),
    CONSTRAINT fk_putaway_asn       FOREIGN KEY (asn_id) REFERENCES advance_shipment_notices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.4  inventory_locations
--      Current inventory snapshot per SKU per bin location.
CREATE TABLE IF NOT EXISTS inventory_locations (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    sku                     VARCHAR(50)         NOT NULL,
    campaign_code           VARCHAR(50)         NOT NULL,
    warehouse_zone          VARCHAR(20)         NOT NULL,
    warehouse_aisle         VARCHAR(10)             NULL,
    warehouse_bin           VARCHAR(20)         NOT NULL,
    quantity_on_hand        INT UNSIGNED        NOT NULL DEFAULT 0,
    quantity_reserved       INT UNSIGNED        NOT NULL DEFAULT 0,
    quantity_available      INT UNSIGNED        NOT NULL DEFAULT 0,
    last_receipt_date       DATE                    NULL,
    last_updated_at         DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_inv_loc           PRIMARY KEY (id),
    CONSTRAINT uq_inv_sku_bin       UNIQUE (sku, warehouse_bin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.5  asn_events  (full audit trail)
CREATE TABLE IF NOT EXISTS asn_events (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    asn_id                  BIGINT UNSIGNED     NOT NULL,
    event_type              VARCHAR(80)         NOT NULL,
    previous_status         VARCHAR(30)             NULL,
    new_status              VARCHAR(30)         NOT NULL,
    notes                   TEXT                    NULL,
    triggered_by            VARCHAR(100)        NOT NULL,
    event_at                DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rabbitmq_published      TINYINT(1)          NOT NULL DEFAULT 0,
    CONSTRAINT pk_asn_events        PRIMARY KEY (id),
    CONSTRAINT fk_ae_asn            FOREIGN KEY (asn_id) REFERENCES advance_shipment_notices(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. INDEXES ────────────────────────────────────────────────────────────────
CREATE INDEX idx_asn_status             ON advance_shipment_notices(status);
CREATE INDEX idx_asn_po                 ON advance_shipment_notices(po_external_id);
CREATE INDEX idx_asn_campaign           ON advance_shipment_notices(campaign_external_id);
CREATE INDEX idx_asn_vendor             ON advance_shipment_notices(vendor_external_id);
CREATE INDEX idx_asn_arrival            ON advance_shipment_notices(estimated_arrival_date);
CREATE INDEX idx_rr_asn_id              ON receiving_records(asn_id);
CREATE INDEX idx_putaway_asn_id         ON putaway_tasks(asn_id);
CREATE INDEX idx_putaway_status         ON putaway_tasks(status);
CREATE INDEX idx_putaway_sku            ON putaway_tasks(sku);
CREATE INDEX idx_inv_sku                ON inventory_locations(sku);
CREATE INDEX idx_inv_campaign           ON inventory_locations(campaign_code);
CREATE INDEX idx_inv_zone               ON inventory_locations(warehouse_zone);
CREATE INDEX idx_ae_asn_id              ON asn_events(asn_id);
