-- =============================================================================
-- cs_vendor DATABASE — DDL SCRIPT
-- Database: cs_vendor
-- Engine:   MySQL 8.x (InnoDB)
-- Charset:  utf8mb4
-- NOTE:     All schema changes are made HERE, not by the application.
--           Spring Boot connects as vendor_app user with NO DDL privileges.
--
-- Domain story:
--   The food chain sources toys from vendors in China, Vietnam, India, Thailand.
--   This ERP manages: vendor registration, RFQ (Request for Quote) issuance,
--   quote submission by vendors, award decisions, and vendor scorecards.
-- =============================================================================

-- ── 1. DATABASE ───────────────────────────────────────────────────────────────
CREATE DATABASE IF NOT EXISTS cs_vendor
    CHARACTER SET utf8mb4
    COLLATE utf8mb4_unicode_ci;

USE cs_vendor;

-- ── 2. APPLICATION USER (least privilege — no DDL) ───────────────────────────
CREATE USER IF NOT EXISTS 'vendor_app'@'localhost' IDENTIFIED BY 'VendorApp#2025!';
GRANT SELECT, INSERT, UPDATE, DELETE ON cs_vendor.* TO 'vendor_app'@'localhost';
FLUSH PRIVILEGES;

-- ── 3. TABLES ─────────────────────────────────────────────────────────────────

-- 3.1  vendors
--      One row per supplier. Country drives lead time and duty rates.
CREATE TABLE IF NOT EXISTS vendors (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    vendor_name         VARCHAR(200)        NOT NULL,
    vendor_code         VARCHAR(50)         NOT NULL COMMENT 'Short code e.g. VND-CN-001',
    country             ENUM('CHINA','VIETNAM','INDIA','THAILAND','OTHER') NOT NULL,
    contact_name        VARCHAR(150)            NULL,
    contact_email       VARCHAR(255)            NULL,
    contact_phone       VARCHAR(40)             NULL,
    address             TEXT                    NULL,
    status              ENUM('ACTIVE','INACTIVE','BLACKLISTED') NOT NULL DEFAULT 'ACTIVE',
    category            ENUM('TOY_MANUFACTURER','PACKAGING','LOGISTICS','OTHER') NOT NULL DEFAULT 'TOY_MANUFACTURER',
    lead_time_days      INT UNSIGNED            NULL COMMENT 'Typical production lead time in days',
    payment_terms       VARCHAR(100)            NULL COMMENT 'e.g. NET30, 50% upfront',
    scorecard_rating    DECIMAL(3,2)            NULL COMMENT '0.00 to 5.00',
    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_vendors               PRIMARY KEY (id),
    CONSTRAINT uq_vendors_external_id   UNIQUE (external_id),
    CONSTRAINT uq_vendors_code          UNIQUE (vendor_code),
    CONSTRAINT chk_vendors_rating       CHECK (scorecard_rating IS NULL OR (scorecard_rating >= 0 AND scorecard_rating <= 5))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.2  rfqs  (Request for Quote)
--      Issued by the food chain company to one or more vendors for a campaign.
CREATE TABLE IF NOT EXISTS rfqs (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    rfq_number          VARCHAR(50)         NOT NULL COMMENT 'Human-readable e.g. RFQ-2025-001',
    campaign_external_id VARCHAR(64)        NOT NULL COMMENT 'References cs_crm.campaigns.external_id',
    campaign_code       VARCHAR(50)         NOT NULL,
    title               VARCHAR(200)        NOT NULL,
    description         TEXT                    NULL,
    toy_category        VARCHAR(100)            NULL COMMENT 'e.g. Dinosaur Figures, Action Heroes',
    quantity_required   INT UNSIGNED        NOT NULL,
    unit               VARCHAR(30)          NOT NULL DEFAULT 'PIECES',
    target_unit_cost_usd DECIMAL(10,4)          NULL,
    required_by_date    DATE                NOT NULL COMMENT 'Date toys must be at DC',
    submission_deadline DATE                NOT NULL COMMENT 'Vendor quote due date',
    status              ENUM('DRAFT','OPEN','UNDER_REVIEW','AWARDED','CANCELLED') NOT NULL DEFAULT 'DRAFT',
    created_by          VARCHAR(100)        NOT NULL,
    created_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_rfqs                  PRIMARY KEY (id),
    CONSTRAINT uq_rfqs_external_id      UNIQUE (external_id),
    CONSTRAINT uq_rfqs_number           UNIQUE (rfq_number),
    CONSTRAINT chk_rfqs_dates           CHECK (required_by_date > submission_deadline)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.3  rfq_vendors
--      Junction: which vendors are invited to quote on which RFQ.
CREATE TABLE IF NOT EXISTS rfq_vendors (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    rfq_id              BIGINT UNSIGNED     NOT NULL,
    vendor_id           BIGINT UNSIGNED     NOT NULL,
    invited_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT pk_rfq_vendors           PRIMARY KEY (id),
    CONSTRAINT uq_rfq_vendor            UNIQUE (rfq_id, vendor_id),
    CONSTRAINT fk_rfqv_rfq              FOREIGN KEY (rfq_id)    REFERENCES rfqs(id),
    CONSTRAINT fk_rfqv_vendor           FOREIGN KEY (vendor_id) REFERENCES vendors(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.4  vendor_quotes
--      A vendor's response to an RFQ.
CREATE TABLE IF NOT EXISTS vendor_quotes (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    rfq_id              BIGINT UNSIGNED     NOT NULL,
    vendor_id           BIGINT UNSIGNED     NOT NULL,
    quoted_unit_cost_usd DECIMAL(10,4)      NOT NULL,
    quoted_quantity     INT UNSIGNED        NOT NULL,
    total_cost_usd      DECIMAL(15,2)       NOT NULL,
    lead_time_days      INT UNSIGNED        NOT NULL,
    delivery_date       DATE                NOT NULL,
    payment_terms       VARCHAR(100)            NULL,
    notes               TEXT                    NULL,
    status              ENUM('SUBMITTED','UNDER_REVIEW','ACCEPTED','REJECTED') NOT NULL DEFAULT 'SUBMITTED',
    submitted_at        DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT pk_vendor_quotes         PRIMARY KEY (id),
    CONSTRAINT uq_vq_external_id        UNIQUE (external_id),
    CONSTRAINT uq_vq_rfq_vendor         UNIQUE (rfq_id, vendor_id) COMMENT 'One quote per vendor per RFQ',
    CONSTRAINT fk_vq_rfq                FOREIGN KEY (rfq_id)    REFERENCES rfqs(id),
    CONSTRAINT fk_vq_vendor             FOREIGN KEY (vendor_id) REFERENCES vendors(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- 3.5  rfq_awards
--      Records the award decision: which vendor won the RFQ.
CREATE TABLE IF NOT EXISTS rfq_awards (
    id                  BIGINT UNSIGNED     NOT NULL AUTO_INCREMENT,
    external_id         VARCHAR(64)         NOT NULL,
    rfq_id              BIGINT UNSIGNED     NOT NULL,
    winning_vendor_id   BIGINT UNSIGNED     NOT NULL,
    winning_quote_id    BIGINT UNSIGNED     NOT NULL,
    awarded_quantity    INT UNSIGNED        NOT NULL,
    awarded_unit_cost_usd DECIMAL(10,4)     NOT NULL,
    total_award_value_usd DECIMAL(15,2)     NOT NULL,
    award_notes         TEXT                    NULL,
    awarded_by          VARCHAR(100)        NOT NULL,
    awarded_at          DATETIME            NOT NULL DEFAULT CURRENT_TIMESTAMP,
    rabbitmq_published  TINYINT(1)          NOT NULL DEFAULT 0,
    CONSTRAINT pk_rfq_awards            PRIMARY KEY (id),
    CONSTRAINT uq_rfqa_external_id      UNIQUE (external_id),
    CONSTRAINT uq_rfqa_rfq_id          UNIQUE (rfq_id) COMMENT 'Only one award per RFQ',
    CONSTRAINT fk_rfqa_rfq              FOREIGN KEY (rfq_id)           REFERENCES rfqs(id),
    CONSTRAINT fk_rfqa_vendor           FOREIGN KEY (winning_vendor_id) REFERENCES vendors(id),
    CONSTRAINT fk_rfqa_quote            FOREIGN KEY (winning_quote_id)  REFERENCES vendor_quotes(id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ── 4. INDEXES ────────────────────────────────────────────────────────────────
CREATE INDEX idx_vendors_country        ON vendors(country);
CREATE INDEX idx_vendors_status         ON vendors(status);
CREATE INDEX idx_vendors_category       ON vendors(category);
CREATE INDEX idx_rfqs_status            ON rfqs(status);
CREATE INDEX idx_rfqs_campaign          ON rfqs(campaign_external_id);
CREATE INDEX idx_rfqs_dates             ON rfqs(submission_deadline, required_by_date);
CREATE INDEX idx_rfqv_rfq_id            ON rfq_vendors(rfq_id);
CREATE INDEX idx_rfqv_vendor_id         ON rfq_vendors(vendor_id);
CREATE INDEX idx_vq_rfq_id              ON vendor_quotes(rfq_id);
CREATE INDEX idx_vq_vendor_id           ON vendor_quotes(vendor_id);
CREATE INDEX idx_vq_status              ON vendor_quotes(status);
CREATE INDEX idx_rfqa_vendor_id         ON rfq_awards(winning_vendor_id);
