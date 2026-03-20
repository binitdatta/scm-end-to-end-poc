-- =============================================================================
-- cs_crm DATABASE — DDL SCRIPT
-- Database: cs_crm
-- Engine:   MySQL 8.x (InnoDB)
-- Charset:  utf8mb4
-- NOTE:     All schema changes are made HERE, not by the application.
--           Spring Boot connects as a read/write user (crm_app) that has
--           NO DDL privileges (no CREATE/ALTER/DROP TABLE).
-- =============================================================================

-- ── 1. DATABASE ───────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS cs_crm
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cs_crm;

-- ── 2. APPLICATION USER (least privilege — no DDL) ───────────────────────────
-- Run these as root / admin account once.
-- The app user can only SELECT/INSERT/UPDATE/DELETE — never ALTER or DROP.
CREATE USER IF NOT EXISTS 'crm_app'@'localhost' IDENTIFIED BY 'CrmApp#2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON cs_crm.* TO 'crm_app'@'localhost';
FLUSH PRIVILEGES;

-- ── 3. TABLES ─────────────────────────────────────────────────────────────────

-- 3.1  customers
CREATE TABLE IF NOT EXISTS customers (
    id              BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id     VARCHAR(64)         NOT NULL COMMENT 'UUID assigned by app layer',
    first_name      VARCHAR(100)        NOT NULL,
    last_name       VARCHAR(100)        NOT NULL,
    email           VARCHAR(255)        NOT NULL,
    phone           VARCHAR(30)             NULL,
    tier            ENUM('STANDARD','GOLD','PLATINUM') NOT NULL DEFAULT 'STANDARD',
    status          ENUM('ACTIVE','INACTIVE','SUSPENDED') NOT NULL DEFAULT 'ACTIVE',
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_customers         PRIMARY KEY (id),
    CONSTRAINT uq_customers_extid   UNIQUE (external_id),
    CONSTRAINT uq_customers_email   UNIQUE (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2  campaigns
CREATE TABLE IF NOT EXISTS campaigns (
    id              BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id     VARCHAR(64)         NOT NULL COMMENT 'UUID assigned by app layer',
    campaign_name   VARCHAR(200)        NOT NULL,
    campaign_code   VARCHAR(50)         NOT NULL COMMENT 'Short code e.g. SUMMER25-TOY',
    description     TEXT                    NULL,
    campaign_type   ENUM('TOY_SURPRISE','SEASONAL','LOYALTY','PROMO') NOT NULL DEFAULT 'TOY_SURPRISE',
    status          ENUM('DRAFT','ACTIVE','PAUSED','COMPLETED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
    budget_usd      DECIMAL(15,2)       NOT NULL DEFAULT 0.00,
    start_date      DATE                NOT NULL,
    end_date        DATE                NOT NULL,
    target_region   VARCHAR(100)            NULL COMMENT 'e.g. US-MIDWEST, NATIONAL',
    created_by      VARCHAR(100)        NOT NULL,
    created_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at      DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_campaigns             PRIMARY KEY (id),
    CONSTRAINT uq_campaigns_extid       UNIQUE (external_id),
    CONSTRAINT uq_campaigns_code        UNIQUE (campaign_code),
    CONSTRAINT chk_campaigns_dates      CHECK (end_date >= start_date)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3  campaign_events  (audit trail of every status transition)
CREATE TABLE IF NOT EXISTS campaign_events (
    id              BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    campaign_id     BIGINT UNSIGNED     NOT NULL,
    event_type      VARCHAR(80)         NOT NULL COMMENT 'e.g. LAUNCHED, PAUSED, COMPLETED',
    previous_status VARCHAR(30)             NULL,
    new_status      VARCHAR(30)         NOT NULL,
    notes           TEXT                    NULL,
    triggered_by    VARCHAR(100)        NOT NULL,
    event_at        DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rabbitmq_published  TINYINT(1)      NOT NULL DEFAULT 0 COMMENT '1 = message published to exchange',
    CONSTRAINT pk_campaign_events       PRIMARY KEY (id),
    CONSTRAINT fk_ce_campaign           FOREIGN KEY (campaign_id) REFERENCES campaigns(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.4  campaign_customers  (which customers are enrolled in which campaign)
CREATE TABLE IF NOT EXISTS campaign_customers (
    id              BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    campaign_id     BIGINT UNSIGNED     NOT NULL,
    customer_id     BIGINT UNSIGNED     NOT NULL,
    enrolled_at     DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    enrollment_channel VARCHAR(50)      NOT NULL DEFAULT 'SYSTEM' COMMENT 'APP, IMPORT, SYSTEM',
    CONSTRAINT pk_campaign_customers    PRIMARY KEY (id),
    CONSTRAINT uq_cc_campaign_customer  UNIQUE (campaign_id, customer_id),
    CONSTRAINT fk_cc_campaign           FOREIGN KEY (campaign_id) REFERENCES campaigns(id),
    CONSTRAINT fk_cc_customer           FOREIGN KEY (customer_id) REFERENCES customers(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. INDEXES ────────────────────────────────────────────────────────────────
CREATE INDEX idx_campaigns_status      ON campaigns(status);
CREATE INDEX idx_campaigns_dates       ON campaigns(start_date, end_date);
CREATE INDEX idx_ce_campaign_id        ON campaign_events(campaign_id);
CREATE INDEX idx_ce_event_type         ON campaign_events(event_type);
CREATE INDEX idx_cc_campaign_id        ON campaign_customers(campaign_id);
CREATE INDEX idx_cc_customer_id        ON campaign_customers(customer_id);
CREATE INDEX idx_customers_status      ON customers(status);
CREATE INDEX idx_customers_tier        ON customers(tier);
