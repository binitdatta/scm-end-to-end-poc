-- =============================================================================
-- cs_wms_outbound DATABASE — DDL SCRIPT
-- Database: cs_wms_outbound
-- Engine:   MySQL 8.x (InnoDB)
-- Charset:  utf8mb4
-- NOTE:     All schema changes are made HERE, not by the application.
--           Spring Boot connects as wms_outbound_app with NO DDL privileges.
--
-- Domain story:
--   When cs-oms-api publishes erp.oms.store-order.allocated, this WMS
--   creates a pick wave, directs warehouse operators to pick toys from
--   bin locations, packs them into store cartons, manifests them, and
--   dispatches to the TMS for outbound carrier delivery to stores.
--
--   Key outbound event: erp.wms.outbound.shipment.dispatched
--   → consumed by cs-tms-api to book carrier and schedule store delivery
--
--   Lifecycle:
--     Pick Wave: CREATED → ASSIGNED → PICKING → COMPLETED
--     Shipment:  CREATED → PACKED → MANIFESTED → DISPATCHED
-- =============================================================================

-- ── 1. DATABASE ───────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS cs_wms_outbound
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cs_wms_outbound;

-- ── 2. APPLICATION USER ───────────────────────────────────────────────────────
CREATE USER IF NOT EXISTS 'wms_outbound_app'@'localhost' IDENTIFIED BY 'WmsOutbound#2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON cs_wms_outbound.* TO 'wms_outbound_app'@'localhost';
FLUSH PRIVILEGES;

-- ── 3. TABLES ─────────────────────────────────────────────────────────────────

-- 3.1  pick_waves
--      Batches work from one or more store orders into a single warehouse pick run.
CREATE TABLE IF NOT EXISTS pick_waves (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id             VARCHAR(64)         NOT NULL,
    wave_number             VARCHAR(50)         NOT NULL COMMENT 'e.g. WV-2025-001',

    -- Cross-service references
    store_order_external_id VARCHAR(64)         NOT NULL COMMENT 'cs_oms.store_orders.external_id',
    store_order_number      VARCHAR(50)         NOT NULL,
    campaign_external_id    VARCHAR(64)         NOT NULL,
    campaign_code           VARCHAR(50)         NOT NULL,
    region_code             VARCHAR(20)         NOT NULL,

    -- Product
    sku                     VARCHAR(50)         NOT NULL,
    toy_description         VARCHAR(200)        NOT NULL,
    total_quantity          INT UNSIGNED        NOT NULL,
    picked_quantity         INT UNSIGNED        NOT NULL DEFAULT 0,

    -- Warehouse
    pick_zone               VARCHAR(20)             NULL COMMENT 'e.g. ZONE-A',
    assigned_to             VARCHAR(100)            NULL,

    -- Dates
    required_ship_date      DATE                NOT NULL,
    started_at              DATETIME                NULL,
    completed_at            DATETIME                NULL,

    -- Lifecycle
    status                  ENUM('CREATED','ASSIGNED','PICKING','COMPLETED','CANCELLED')
                            NOT NULL DEFAULT 'CREATED',
    notes                   TEXT                    NULL,
    created_by              VARCHAR(100)        NOT NULL,
    created_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_pick_waves            PRIMARY KEY (id),
    CONSTRAINT uq_pw_external_id        UNIQUE (external_id),
    CONSTRAINT uq_pw_wave_number        UNIQUE (wave_number)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2  pick_wave_lines
--      One line per source bin location within a pick wave.
CREATE TABLE IF NOT EXISTS pick_wave_lines (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    pick_wave_id        BIGINT UNSIGNED     NOT NULL,
    sku                 VARCHAR(50)         NOT NULL,
    warehouse_zone      VARCHAR(20)             NULL,
    warehouse_aisle     VARCHAR(10)             NULL,
    warehouse_bin       VARCHAR(20)         NOT NULL,
    quantity_to_pick    INT UNSIGNED        NOT NULL,
    quantity_picked     INT UNSIGNED        NOT NULL DEFAULT 0,
    status              ENUM('PENDING','PICKED','SHORT','CANCELLED')
                        NOT NULL DEFAULT 'PENDING',
    CONSTRAINT pk_pwl               PRIMARY KEY (id),
    CONSTRAINT uq_pwl_external_id   UNIQUE (external_id),
    CONSTRAINT fk_pwl_wave          FOREIGN KEY (pick_wave_id) REFERENCES pick_waves(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3  outbound_shipments
--      One shipment per store order. Created after pick wave completes.
CREATE TABLE IF NOT EXISTS outbound_shipments (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id             VARCHAR(64)         NOT NULL,
    shipment_number         VARCHAR(50)         NOT NULL COMMENT 'e.g. SHP-2025-001',

    -- Cross-service references
    pick_wave_id            BIGINT UNSIGNED     NOT NULL,
    store_order_external_id VARCHAR(64)         NOT NULL,
    store_order_number      VARCHAR(50)         NOT NULL,
    campaign_external_id    VARCHAR(64)         NOT NULL,
    campaign_code           VARCHAR(50)         NOT NULL,
    region_code             VARCHAR(20)         NOT NULL,
    distribution_dc         VARCHAR(50)             NULL,

    -- Product
    sku                     VARCHAR(50)         NOT NULL,
    toy_description         VARCHAR(200)        NOT NULL,
    total_cartons           INT UNSIGNED        NOT NULL COMMENT 'One carton per store',
    total_units             INT UNSIGNED        NOT NULL,
    units_per_carton        INT UNSIGNED        NOT NULL DEFAULT 1,

    -- Carrier / routing
    carrier_name            VARCHAR(100)            NULL,
    pro_number              VARCHAR(100)            NULL COMMENT 'Carrier tracking reference',
    destination_region      VARCHAR(100)            NULL,

    -- Dates
    required_delivery_date  DATE                NOT NULL,
    estimated_ship_date     DATE                    NULL,
    actual_ship_date        DATE                    NULL,

    -- Lifecycle
    status                  ENUM('CREATED','PACKED','MANIFESTED','DISPATCHED','CANCELLED')
                            NOT NULL DEFAULT 'CREATED',
    notes                   TEXT                    NULL,
    created_by              VARCHAR(100)        NOT NULL,
    created_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_outbound_shipments    PRIMARY KEY (id),
    CONSTRAINT uq_os_external_id        UNIQUE (external_id),
    CONSTRAINT uq_os_shipment_number    UNIQUE (shipment_number),
    CONSTRAINT uq_os_pick_wave          UNIQUE (pick_wave_id),
    CONSTRAINT fk_os_pick_wave          FOREIGN KEY (pick_wave_id) REFERENCES pick_waves(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.4  shipment_store_lines
--      Per-store carton in the shipment — one row per destination store.
CREATE TABLE IF NOT EXISTS shipment_store_lines (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    shipment_id         BIGINT UNSIGNED     NOT NULL,
    store_external_id   VARCHAR(64)         NOT NULL,
    store_number        VARCHAR(20)         NOT NULL,
    store_name          VARCHAR(150)        NOT NULL,
    city                VARCHAR(100)            NULL,
    state_code          VARCHAR(10)             NULL,
    sku                 VARCHAR(50)         NOT NULL,
    quantity            INT UNSIGNED        NOT NULL,
    carton_label        VARCHAR(50)             NULL COMMENT 'Barcode label for carton',
    status              ENUM('PENDING','PACKED','DISPATCHED','DELIVERED')
                        NOT NULL DEFAULT 'PENDING',
    CONSTRAINT pk_ssl               PRIMARY KEY (id),
    CONSTRAINT uq_ssl_external_id   UNIQUE (external_id),
    CONSTRAINT fk_ssl_shipment      FOREIGN KEY (shipment_id) REFERENCES outbound_shipments(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.5  outbound_events  (full audit trail)
CREATE TABLE IF NOT EXISTS outbound_events (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    entity_type         VARCHAR(20)         NOT NULL COMMENT 'PICK_WAVE or SHIPMENT',
    entity_id           BIGINT UNSIGNED     NOT NULL,
    event_type          VARCHAR(80)         NOT NULL,
    previous_status     VARCHAR(30)             NULL,
    new_status          VARCHAR(30)         NOT NULL,
    notes               TEXT                    NULL,
    triggered_by        VARCHAR(100)        NOT NULL,
    event_at            DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rabbitmq_published  TINYINT(1)          NOT NULL DEFAULT 0,
    CONSTRAINT pk_outbound_events   PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. INDEXES ────────────────────────────────────────────────────────────────
CREATE INDEX idx_pw_status              ON pick_waves(status);
CREATE INDEX idx_pw_campaign            ON pick_waves(campaign_code);
CREATE INDEX idx_pw_order               ON pick_waves(store_order_external_id);
CREATE INDEX idx_pw_sku                 ON pick_waves(sku);
CREATE INDEX idx_pwl_wave_id            ON pick_wave_lines(pick_wave_id);
CREATE INDEX idx_pwl_status             ON pick_wave_lines(status);
CREATE INDEX idx_os_status              ON outbound_shipments(status);
CREATE INDEX idx_os_campaign            ON outbound_shipments(campaign_code);
CREATE INDEX idx_os_order               ON outbound_shipments(store_order_external_id);
CREATE INDEX idx_ssl_shipment           ON shipment_store_lines(shipment_id);
CREATE INDEX idx_ssl_store              ON shipment_store_lines(store_external_id);
CREATE INDEX idx_oe_entity              ON outbound_events(entity_type, entity_id);
