-- =============================================================================
-- cs_tms DATABASE — DDL SCRIPT
-- Database: cs_tms
-- Engine:   MySQL 8.x (InnoDB)
-- Charset:  utf8mb4
-- NOTE:     All schema changes are made HERE, not by the application.
--           Spring Boot connects as tms_app with NO DDL privileges.
--
-- Domain story:
--   When cs-wms-outbound-api publishes erp.wms.outbound.shipment.dispatched,
--   this TMS creates a delivery load, assigns it to a carrier driver,
--   tracks transit milestones, records proof-of-delivery (POD) at each store,
--   and publishes erp.tms.delivery.pod-confirmed — the final event in the
--   supply chain that signals toys are physically in the restaurant.
--
--   Key outbound event: erp.tms.delivery.pod-confirmed
--   → consumed by Flask Control Tower for BI / analytics dashboard
--
--   Lifecycle:
--     Delivery Load: CREATED → ASSIGNED → IN_TRANSIT → COMPLETED
--     Store Delivery: PENDING → OUT_FOR_DELIVERY → DELIVERED → POD_CONFIRMED
-- =============================================================================

-- ── 1. DATABASE ───────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS cs_tms
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cs_tms;

-- ── 2. APPLICATION USER ───────────────────────────────────────────────────────
CREATE USER IF NOT EXISTS 'tms_app'@'localhost' IDENTIFIED BY 'TmsApp#2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON cs_tms.* TO 'tms_app'@'localhost';
FLUSH PRIVILEGES;

-- ── 3. TABLES ─────────────────────────────────────────────────────────────────

-- 3.1  delivery_loads
--      One load per dispatched WMS shipment. Covers all stores in that shipment.
CREATE TABLE IF NOT EXISTS delivery_loads (
    id                          BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id                 VARCHAR(64)         NOT NULL,
    load_number                 VARCHAR(50)         NOT NULL COMMENT 'e.g. LOAD-2025-001',

    -- Cross-service references
    shipment_external_id        VARCHAR(64)         NOT NULL COMMENT 'cs_wms_outbound.outbound_shipments.external_id',
    shipment_number             VARCHAR(50)         NOT NULL,
    store_order_external_id     VARCHAR(64)         NOT NULL,
    store_order_number          VARCHAR(50)         NOT NULL,
    campaign_external_id        VARCHAR(64)         NOT NULL,
    campaign_code               VARCHAR(50)         NOT NULL,
    region_code                 VARCHAR(20)         NOT NULL,
    distribution_dc             VARCHAR(50)             NULL,

    -- Product
    sku                         VARCHAR(50)         NOT NULL,
    toy_description             VARCHAR(200)        NOT NULL,
    total_cartons               INT UNSIGNED        NOT NULL,
    total_units                 INT UNSIGNED        NOT NULL,

    -- Carrier
    carrier_name                VARCHAR(100)        NOT NULL,
    pro_number                  VARCHAR(100)        NOT NULL COMMENT 'Carrier tracking PRO',
    driver_name                 VARCHAR(100)            NULL,
    truck_number                VARCHAR(50)             NULL,

    -- Dates
    required_delivery_date      DATE                NOT NULL,
    pickup_date                 DATE                    NULL,
    estimated_delivery_date     DATE                    NULL,

    -- Lifecycle
    status                      ENUM('CREATED','ASSIGNED','IN_TRANSIT','COMPLETED','CANCELLED')
                                NOT NULL DEFAULT 'CREATED',
    notes                       TEXT                    NULL,
    created_by                  VARCHAR(100)        NOT NULL,
    created_at                  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at                  DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    CONSTRAINT pk_delivery_loads        PRIMARY KEY (id),
    CONSTRAINT uq_dl_external_id        UNIQUE (external_id),
    CONSTRAINT uq_dl_load_number        UNIQUE (load_number),
    CONSTRAINT uq_dl_shipment           UNIQUE (shipment_external_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2  store_deliveries
--      One row per store per delivery load.
--      Tracks individual store-level delivery + POD.
CREATE TABLE IF NOT EXISTS store_deliveries (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    delivery_load_id    BIGINT UNSIGNED     NOT NULL,

    -- Store info (denormalised from OMS/WMS)
    store_external_id   VARCHAR(64)         NOT NULL,
    store_number        VARCHAR(20)         NOT NULL,
    store_name          VARCHAR(150)        NOT NULL,
    city                VARCHAR(100)            NULL,
    state_code          VARCHAR(10)             NULL,

    -- Product
    sku                 VARCHAR(50)         NOT NULL,
    quantity            INT UNSIGNED        NOT NULL,
    carton_label        VARCHAR(50)             NULL,

    -- POD details
    delivered_quantity  INT UNSIGNED            NULL,
    pod_signatory       VARCHAR(100)            NULL COMMENT 'Name of store manager who signed',
    pod_notes           TEXT                    NULL,
    delivered_at        DATETIME                NULL,
    pod_confirmed_at    DATETIME                NULL,

    -- Lifecycle
    status              ENUM('PENDING','OUT_FOR_DELIVERY','DELIVERED','POD_CONFIRMED','FAILED')
                        NOT NULL DEFAULT 'PENDING',

    CONSTRAINT pk_store_deliveries      PRIMARY KEY (id),
    CONSTRAINT uq_sd_external_id        UNIQUE (external_id),
    CONSTRAINT fk_sd_load               FOREIGN KEY (delivery_load_id) REFERENCES delivery_loads(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3  transit_events
--      Append-only carrier tracking milestones (location pings, exceptions, etc.)
CREATE TABLE IF NOT EXISTS transit_events (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    delivery_load_id    BIGINT UNSIGNED     NOT NULL,
    event_code          VARCHAR(50)         NOT NULL COMMENT 'e.g. PICKUP, IN_TRANSIT, EXCEPTION, DELIVERED',
    event_description   VARCHAR(255)            NULL,
    location            VARCHAR(200)            NULL COMMENT 'City, State or facility name',
    event_at            DATETIME            NOT NULL,
    recorded_at         DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    source              VARCHAR(50)             NULL COMMENT 'CARRIER_API, MANUAL, SYSTEM',
    CONSTRAINT pk_transit_events        PRIMARY KEY (id),
    CONSTRAINT fk_te_load               FOREIGN KEY (delivery_load_id) REFERENCES delivery_loads(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.4  tms_events
--      Full audit trail for every load status transition.
CREATE TABLE IF NOT EXISTS tms_events (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    delivery_load_id    BIGINT UNSIGNED     NOT NULL,
    event_type          VARCHAR(80)         NOT NULL,
    previous_status     VARCHAR(30)             NULL,
    new_status          VARCHAR(30)         NOT NULL,
    notes               TEXT                    NULL,
    triggered_by        VARCHAR(100)        NOT NULL,
    event_at            DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rabbitmq_published  TINYINT(1)          NOT NULL DEFAULT 0,
    CONSTRAINT pk_tms_events            PRIMARY KEY (id),
    CONSTRAINT fk_tmse_load             FOREIGN KEY (delivery_load_id) REFERENCES delivery_loads(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. INDEXES ────────────────────────────────────────────────────────────────
CREATE INDEX idx_dl_status          ON delivery_loads(status);
CREATE INDEX idx_dl_campaign        ON delivery_loads(campaign_code);
CREATE INDEX idx_dl_carrier         ON delivery_loads(carrier_name);
CREATE INDEX idx_dl_shipment        ON delivery_loads(shipment_external_id);
CREATE INDEX idx_sd_load            ON store_deliveries(delivery_load_id);
CREATE INDEX idx_sd_store           ON store_deliveries(store_external_id);
CREATE INDEX idx_sd_status          ON store_deliveries(status);
CREATE INDEX idx_te_load            ON transit_events(delivery_load_id);
CREATE INDEX idx_te_event_at        ON transit_events(event_at);
CREATE INDEX idx_tmse_load          ON tms_events(delivery_load_id);
