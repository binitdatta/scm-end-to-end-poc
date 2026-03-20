-- =============================================================================
-- cs_oms DATABASE — DDL SCRIPT
-- Database: cs_oms
-- Engine:   MySQL 8.x (InnoDB)
-- Charset:  utf8mb4
-- NOTE:     All schema changes are made HERE, not by the application.
--           Spring Boot connects as oms_app with NO DDL privileges.
--
-- Domain story:
--   The food chain has ~3,200 restaurant locations organised into US regions.
--   When cs-wms-inbound-api publishes erp.wms.inbound.putaway.completed,
--   the OMS updates its local inventory view. Planners create store orders
--   per campaign per region, allocate inventory across stores, and publish
--   erp.oms.store-order.allocated — which triggers cs-wms-outbound-api
--   to begin pick, pack and ship.
--
--   Store order lifecycle:
--     DRAFT → SUBMITTED → ALLOCATED → PICKING → SHIPPED → DELIVERED
-- =============================================================================

-- ── 1. DATABASE ───────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS cs_oms
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cs_oms;

-- ── 2. APPLICATION USER ───────────────────────────────────────────────────────
CREATE USER IF NOT EXISTS 'oms_app'@'localhost' IDENTIFIED BY 'OmsApp#2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON cs_oms.* TO 'oms_app'@'localhost';
FLUSH PRIVILEGES;

-- ── 3. TABLES ─────────────────────────────────────────────────────────────────

-- 3.1  store_regions
CREATE TABLE IF NOT EXISTS store_regions (
    id              BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id     VARCHAR(64)         NOT NULL,
    region_code     VARCHAR(20)         NOT NULL,
    region_name     VARCHAR(100)        NOT NULL,
    store_count     INT UNSIGNED        NOT NULL DEFAULT 0,
    distribution_dc VARCHAR(50)             NULL COMMENT 'e.g. DC-CHICAGO, DC-LOS-ANGELES',
    status          ENUM('ACTIVE','INACTIVE') NOT NULL DEFAULT 'ACTIVE',
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_store_regions         PRIMARY KEY (id),
    CONSTRAINT uq_sr_external_id        UNIQUE (external_id),
    CONSTRAINT uq_sr_code               UNIQUE (region_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2  stores
CREATE TABLE IF NOT EXISTS stores (
    id              BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id     VARCHAR(64)         NOT NULL,
    store_number    VARCHAR(20)         NOT NULL,
    store_name      VARCHAR(150)        NOT NULL,
    region_id       BIGINT UNSIGNED     NOT NULL,
    address         VARCHAR(255)            NULL,
    city            VARCHAR(100)            NULL,
    state_code      VARCHAR(10)             NULL,
    zip_code        VARCHAR(10)             NULL,
    status          ENUM('ACTIVE','INACTIVE','CLOSED') NOT NULL DEFAULT 'ACTIVE',
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_stores                PRIMARY KEY (id),
    CONSTRAINT uq_stores_external_id    UNIQUE (external_id),
    CONSTRAINT uq_stores_number         UNIQUE (store_number),
    CONSTRAINT fk_stores_region         FOREIGN KEY (region_id) REFERENCES store_regions(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3  store_orders
--      One order per campaign per region covering all stores in that region.
CREATE TABLE IF NOT EXISTS store_orders (
    id                      BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id             VARCHAR(64)         NOT NULL,
    order_number            VARCHAR(50)         NOT NULL,

    -- Cross-service references (no FK — different databases)
    campaign_external_id    VARCHAR(64)         NOT NULL,
    campaign_code           VARCHAR(50)         NOT NULL,

    region_id               BIGINT UNSIGNED     NOT NULL,
    sku                     VARCHAR(50)         NOT NULL,
    toy_description         VARCHAR(200)        NOT NULL,
    quantity_requested      INT UNSIGNED        NOT NULL,
    quantity_allocated      INT UNSIGNED        NOT NULL DEFAULT 0,
    quantity_per_store      INT UNSIGNED            NULL,

    requested_delivery_date DATE                NOT NULL,
    allocated_at            DATETIME                NULL,

    status                  ENUM('DRAFT','SUBMITTED','ALLOCATED','PICKING',
                                 'SHIPPED','DELIVERED','CANCELLED')
                            NOT NULL DEFAULT 'DRAFT',
    created_by              VARCHAR(100)        NOT NULL,
    notes                   TEXT                    NULL,
    created_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at              DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_store_orders          PRIMARY KEY (id),
    CONSTRAINT uq_so_external_id        UNIQUE (external_id),
    CONSTRAINT uq_so_order_number       UNIQUE (order_number),
    CONSTRAINT fk_so_region             FOREIGN KEY (region_id) REFERENCES store_regions(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.4  store_order_lines
--      Per-store allocation — one row per store per order.
CREATE TABLE IF NOT EXISTS store_order_lines (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    store_order_id      BIGINT UNSIGNED     NOT NULL,
    store_id            BIGINT UNSIGNED     NOT NULL,
    sku                 VARCHAR(50)         NOT NULL,
    quantity_allocated  INT UNSIGNED        NOT NULL DEFAULT 0,
    quantity_shipped    INT UNSIGNED        NOT NULL DEFAULT 0,
    quantity_delivered  INT UNSIGNED        NOT NULL DEFAULT 0,
    status              ENUM('PENDING','ALLOCATED','SHIPPED','DELIVERED','CANCELLED')
                        NOT NULL DEFAULT 'PENDING',
    CONSTRAINT pk_sol               PRIMARY KEY (id),
    CONSTRAINT uq_sol_external_id   UNIQUE (external_id),
    CONSTRAINT uq_sol_order_store   UNIQUE (store_order_id, store_id),
    CONSTRAINT fk_sol_order         FOREIGN KEY (store_order_id) REFERENCES store_orders(id),
    CONSTRAINT fk_sol_store         FOREIGN KEY (store_id)       REFERENCES stores(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.5  inventory_availability
--      OMS local view of available inventory.
--      Updated when erp.wms.inbound.putaway.completed is consumed.
CREATE TABLE IF NOT EXISTS inventory_availability (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    sku                 VARCHAR(50)         NOT NULL,
    campaign_code       VARCHAR(50)         NOT NULL,
    quantity_available  INT UNSIGNED        NOT NULL DEFAULT 0,
    quantity_reserved   INT UNSIGNED        NOT NULL DEFAULT 0,
    quantity_remaining  INT UNSIGNED        NOT NULL DEFAULT 0,
    source_asn_number   VARCHAR(50)             NULL,
    last_updated_at     DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_inv_avail         PRIMARY KEY (id),
    CONSTRAINT uq_inv_sku_campaign  UNIQUE (sku, campaign_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.6  order_events  (full audit trail)
CREATE TABLE IF NOT EXISTS order_events (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    store_order_id      BIGINT UNSIGNED     NOT NULL,
    event_type          VARCHAR(80)         NOT NULL,
    previous_status     VARCHAR(30)             NULL,
    new_status          VARCHAR(30)         NOT NULL,
    notes               TEXT                    NULL,
    triggered_by        VARCHAR(100)        NOT NULL,
    event_at            DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rabbitmq_published  TINYINT(1)          NOT NULL DEFAULT 0,
    CONSTRAINT pk_order_events      PRIMARY KEY (id),
    CONSTRAINT fk_oe_order          FOREIGN KEY (store_order_id) REFERENCES store_orders(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. INDEXES ────────────────────────────────────────────────────────────────
CREATE INDEX idx_stores_region          ON stores(region_id);
CREATE INDEX idx_stores_status          ON stores(status);
CREATE INDEX idx_so_campaign            ON store_orders(campaign_external_id);
CREATE INDEX idx_so_status              ON store_orders(status);
CREATE INDEX idx_so_region              ON store_orders(region_id);
CREATE INDEX idx_so_sku                 ON store_orders(sku);
CREATE INDEX idx_sol_order              ON store_order_lines(store_order_id);
CREATE INDEX idx_sol_store              ON store_order_lines(store_id);
CREATE INDEX idx_sol_status             ON store_order_lines(status);
CREATE INDEX idx_inv_sku                ON inventory_availability(sku);
CREATE INDEX idx_inv_campaign           ON inventory_availability(campaign_code);
CREATE INDEX idx_oe_order               ON order_events(store_order_id);
