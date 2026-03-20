-- =============================================================================
-- cs_control_tower_bi DATABASE — DDL SCRIPT
-- Run this in MySQL Workbench BEFORE starting python app.py
-- =============================================================================

CREATE DATABASE IF NOT EXISTS cs_control_tower_bi
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cs_control_tower_bi;

-- Application user — SELECT/INSERT/UPDATE/DELETE only. NO DDL privileges.
CREATE USER IF NOT EXISTS 'ct_app'@'localhost' IDENTIFIED BY 'CtApp#2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON cs_control_tower_bi.* TO 'ct_app'@'localhost';
FLUSH PRIVILEGES;

CREATE TABLE IF NOT EXISTS erp_events (
    id            BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    routing_key   VARCHAR(120)     NOT NULL,
    service       VARCHAR(40)      NOT NULL,
    event_type    VARCHAR(80)          NULL,
    campaign_code VARCHAR(50)          NULL,
    region_code   VARCHAR(30)          NULL,
    payload_json  MEDIUMTEXT       NOT NULL,
    received_at   DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_erp_events PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS campaign_summaries (
    id                    BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    campaign_code         VARCHAR(50)      NOT NULL,
    campaign_status       VARCHAR(30)          NULL,
    total_pos             INT UNSIGNED     NOT NULL DEFAULT 0,
    total_units_ordered   INT UNSIGNED     NOT NULL DEFAULT 0,
    total_units_received  INT UNSIGNED     NOT NULL DEFAULT 0,
    total_orders          INT UNSIGNED     NOT NULL DEFAULT 0,
    total_units_allocated INT UNSIGNED     NOT NULL DEFAULT 0,
    total_shipments       INT UNSIGNED     NOT NULL DEFAULT 0,
    total_units_shipped   INT UNSIGNED     NOT NULL DEFAULT 0,
    total_loads           INT UNSIGNED     NOT NULL DEFAULT 0,
    total_units_delivered INT UNSIGNED     NOT NULL DEFAULT 0,
    stores_delivered      INT UNSIGNED     NOT NULL DEFAULT 0,
    last_event_at         DATETIME             NULL,
    updated_at            DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_campaign_summaries PRIMARY KEY (id),
    CONSTRAINT uq_cs_campaign_code   UNIQUE (campaign_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS delivery_tracking (
    id               BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    campaign_code    VARCHAR(50)      NOT NULL,
    region_code      VARCHAR(30)      NOT NULL,
    load_number      VARCHAR(50)          NULL,
    carrier_name     VARCHAR(100)         NULL,
    pro_number       VARCHAR(100)         NULL,
    sku              VARCHAR(50)          NULL,
    total_units      INT UNSIGNED     NOT NULL DEFAULT 0,
    delivered_units  INT UNSIGNED     NOT NULL DEFAULT 0,
    stores_count     INT UNSIGNED     NOT NULL DEFAULT 0,
    load_status      VARCHAR(30)          NULL,
    pod_confirmed_at DATETIME             NULL,
    updated_at       DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_delivery_tracking PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS chat_history (
    id              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT,
    user_question   TEXT             NOT NULL,
    ai_response     TEXT             NOT NULL,
    service_called  VARCHAR(50)          NULL,
    api_endpoint    VARCHAR(200)         NULL,
    api_payload     TEXT                 NULL,
    raw_api_json    MEDIUMTEXT           NULL,
    session_id      VARCHAR(64)          NULL,
    created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_chat_history PRIMARY KEY (id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE INDEX idx_ee_routing_key   ON erp_events(routing_key);
CREATE INDEX idx_ee_service       ON erp_events(service);
CREATE INDEX idx_ee_campaign_code ON erp_events(campaign_code);
CREATE INDEX idx_ee_received_at   ON erp_events(received_at);
CREATE INDEX idx_dt_campaign_code ON delivery_tracking(campaign_code);
CREATE INDEX idx_dt_region_code   ON delivery_tracking(region_code);
CREATE INDEX idx_dt_load_number   ON delivery_tracking(load_number);
CREATE INDEX idx_ch_session_id    ON chat_history(session_id);
CREATE INDEX idx_ch_created_at    ON chat_history(created_at);