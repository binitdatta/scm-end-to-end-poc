CREATE DATABASE  IF NOT EXISTS `cs_procurement` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cs_procurement`;
-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (x86_64)
--
-- Host: localhost    Database: cs_procurement
-- ------------------------------------------------------
-- Server version	8.0.45

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `invoices`
--

DROP TABLE IF EXISTS `invoices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `invoices` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `invoice_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `po_id` bigint unsigned NOT NULL,
  `vendor_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `invoice_amount_usd` decimal(15,2) NOT NULL,
  `tax_amount_usd` decimal(15,2) NOT NULL DEFAULT '0.00',
  `total_amount_usd` decimal(15,2) NOT NULL,
  `invoice_date` date NOT NULL,
  `due_date` date NOT NULL,
  `status` enum('RECEIVED','UNDER_REVIEW','APPROVED','PAID','DISPUTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'RECEIVED',
  `paid_at` datetime DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_inv_external_id` (`external_id`),
  UNIQUE KEY `uq_inv_number` (`invoice_number`),
  KEY `idx_inv_po_id` (`po_id`),
  KEY `idx_inv_status` (`status`),
  KEY `idx_inv_vendor` (`vendor_external_id`),
  CONSTRAINT `fk_inv_po` FOREIGN KEY (`po_id`) REFERENCES `purchase_orders` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `invoices`
--

LOCK TABLES `invoices` WRITE;
/*!40000 ALTER TABLE `invoices` DISABLE KEYS */;
INSERT INTO `invoices` VALUES (1,'9ffcad2c-52bc-4893-bc57-b57f29f3d940','INV-TH-2025-0042',3,'vnd-004-uuid',232500.00,0.00,232500.00,'2025-04-20','2025-05-20','PAID','2026-03-18 15:57:04','Final invoice for PO-2025-003. 250,000 Space Explorer figures. Payment due NET30.','2026-03-18 15:57:04','2026-03-18 15:57:04');
/*!40000 ALTER TABLE `invoices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `po_events`
--

DROP TABLE IF EXISTS `po_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `po_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `po_id` bigint unsigned NOT NULL,
  `event_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `previous_status` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `triggered_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rabbitmq_published` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_poe_po_id` (`po_id`),
  KEY `idx_poe_event_type` (`event_type`),
  CONSTRAINT `fk_poe_po` FOREIGN KEY (`po_id`) REFERENCES `purchase_orders` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=26 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `po_events`
--

LOCK TABLES `po_events` WRITE;
/*!40000 ALTER TABLE `po_events` DISABLE KEYS */;
INSERT INTO `po_events` VALUES (1,1,'CREATED',NULL,'DRAFT','PO created from RFQ-2025-001 award. Vietnam vendor Ho Chi Minh Playthings selected.','procurement.manager','2026-03-18 10:56:05',0),(2,1,'APPROVED','DRAFT','APPROVED','PO approved by procurement director. Budget confirmed. Ready to send to vendor.','procurement.director','2026-03-18 10:56:05',1),(3,2,'CREATED',NULL,'DRAFT','PO created from RFQ-2025-002 award. Pending CFO approval.','procurement.manager','2026-03-18 10:56:05',0),(4,3,'CREATED',NULL,'DRAFT','PO created','procurement.manager','2026-03-18 15:57:04',0),(5,3,'APPROVED','DRAFT','APPROVED','Budget confirmed. Toy specs verified. Approved.','procurement.director','2026-03-18 15:57:04',1),(6,3,'SENT_TO_VENDOR','APPROVED','SENT_TO_VENDOR','PO emailed and uploaded to vendor portal.','procurement.manager','2026-03-18 15:57:04',1),(7,3,'ACKNOWLEDGED','SENT_TO_VENDOR','ACKNOWLEDGED','Bangkok Fun Factory confirmed receipt. Production slot reserved.','vnd-th-001.portal','2026-03-18 15:57:04',1),(8,3,'IN_PRODUCTION','ACKNOWLEDGED','IN_PRODUCTION','Molds ready. First production run started. ETA 35 days.','vnd-th-001.portal','2026-03-18 15:57:04',1),(9,3,'READY_TO_SHIP','IN_PRODUCTION','READY_TO_SHIP','All 250k units QC passed. Loaded on vessel MSC AURORA. ETA LAX 2025-05-05.','vnd-th-001.portal','2026-03-18 15:57:04',1),(10,3,'COMPLETED','READY_TO_SHIP','COMPLETED','All toys received at DC. Invoice paid. PO closed.','procurement.manager','2026-03-18 15:57:04',1),(11,1,'SENT_TO_VENDOR','APPROVED','SENT_TO_VENDOR','PO transmitted to Ho Chi Minh Playthings via EDI.','procurement.manager','2026-03-18 15:57:04',1),(12,4,'CREATED',NULL,'DRAFT','PO created','agent','2026-04-03 13:29:38',0),(13,4,'APPROVED','DRAFT','APPROVED','Approved by agentic AI control tower','agent','2026-04-03 13:36:49',1),(14,5,'CREATED',NULL,'DRAFT','PO created','agent','2026-04-03 16:58:04',0),(15,5,'APPROVED','DRAFT','APPROVED','Approved by agentic AI control tower','agent','2026-04-03 16:58:04',1),(16,5,'SENT_TO_VENDOR','APPROVED','SENT_TO_VENDOR',NULL,'agent','2026-04-03 16:58:04',1),(17,5,'ACKNOWLEDGED','SENT_TO_VENDOR','ACKNOWLEDGED',NULL,'agent','2026-04-03 16:58:04',1),(18,6,'CREATED',NULL,'DRAFT','PO created','agent','2026-04-03 17:10:32',0),(19,6,'APPROVED','DRAFT','APPROVED','Approved by agentic AI control tower','agent','2026-04-03 17:10:32',1),(20,6,'SENT_TO_VENDOR','APPROVED','SENT_TO_VENDOR',NULL,'agent','2026-04-03 17:10:32',1),(21,6,'ACKNOWLEDGED','SENT_TO_VENDOR','ACKNOWLEDGED',NULL,'agent','2026-04-03 17:10:32',1),(22,7,'CREATED',NULL,'DRAFT','PO created','agent','2026-04-03 17:16:09',0),(23,7,'APPROVED','DRAFT','APPROVED','Approved by agentic AI control tower','agent','2026-04-03 17:16:09',1),(24,7,'SENT_TO_VENDOR','APPROVED','SENT_TO_VENDOR',NULL,'agent','2026-04-03 17:16:09',1),(25,7,'ACKNOWLEDGED','SENT_TO_VENDOR','ACKNOWLEDGED',NULL,'agent','2026-04-03 17:16:09',1);
/*!40000 ALTER TABLE `po_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `po_line_items`
--

DROP TABLE IF EXISTS `po_line_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `po_line_items` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `po_id` bigint unsigned NOT NULL,
  `line_number` int unsigned NOT NULL,
  `item_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Internal SKU / item code',
  `description` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int unsigned NOT NULL,
  `unit` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PIECES',
  `unit_price_usd` decimal(10,4) NOT NULL,
  `line_total_usd` decimal(15,2) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_poli_external_id` (`external_id`),
  UNIQUE KEY `uq_poli_po_line` (`po_id`,`line_number`),
  KEY `idx_poli_po_id` (`po_id`),
  CONSTRAINT `fk_poli_po` FOREIGN KEY (`po_id`) REFERENCES `purchase_orders` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `po_line_items`
--

LOCK TABLES `po_line_items` WRITE;
/*!40000 ALTER TABLE `po_line_items` DISABLE KEYS */;
INSERT INTO `po_line_items` VALUES (1,'poli-001-uuid',1,1,'TOY-DINO-MIX-001','Dinosaur Figure Mystery Mix — 8 Variants (T-Rex, Triceratops, Brachiosaurus, Stegosaurus, Velociraptor, Pterodactyl, Ankylosaurus, Spinosaurus)',480000,'PIECES',0.8200,393600.00),(2,'poli-002-uuid',1,2,'PKG-SURPRISE-BOX-001','Branded Surprise Box Packaging — printed cardboard with mystery design',500000,'PIECES',0.0320,16000.00),(3,'poli-003-uuid',1,3,'TOY-DINO-BONUS-001','Bonus Rare Holographic Variant — limited 1-in-25 inclusion',20000,'PIECES',0.0200,400.00),(4,'f68cff6a-f6bd-4bc5-b4de-9e4b40510d5e',3,1,'TOY-SPACE-MIX-001','Space Explorer Figure Mystery Mix — 5 variants (Astronaut, Rover, Rocket, Alien, Satellite)',240000,'PIECES',0.9300,223200.00),(5,'2894d42c-90aa-4e3d-af93-23b7b8ed94c4',3,2,'PKG-SURPRISE-BOX-002','Space-themed surprise packaging box',250000,'PIECES',0.0320,8000.00);
/*!40000 ALTER TABLE `po_line_items` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `purchase_orders`
--

DROP TABLE IF EXISTS `purchase_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `purchase_orders` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `po_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. PO-2025-001',
  `rfq_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'cs_vendor.rfqs.external_id',
  `rfq_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'cs_crm.campaigns.external_id',
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `award_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'cs_vendor.rfq_awards.external_id',
  `vendor_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_country` enum('CHINA','VIETNAM','INDIA','THAILAND','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL,
  `toy_description` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_ordered` int unsigned NOT NULL,
  `unit_price_usd` decimal(10,4) NOT NULL,
  `total_value_usd` decimal(15,2) NOT NULL,
  `currency` varchar(10) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'USD',
  `payment_terms` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `required_delivery_date` date NOT NULL COMMENT 'Must arrive at DC by this date',
  `estimated_ship_date` date DEFAULT NULL,
  `incoterms` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. FOB, CIF, EXW',
  `destination_port` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. Port of Los Angeles',
  `status` enum('DRAFT','APPROVED','SENT_TO_VENDOR','ACKNOWLEDGED','IN_PRODUCTION','READY_TO_SHIP','COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `approved_by` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `approved_at` datetime DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_po_external_id` (`external_id`),
  UNIQUE KEY `uq_po_number` (`po_number`),
  UNIQUE KEY `uq_po_award` (`award_external_id`) COMMENT 'One PO per award',
  KEY `idx_po_status` (`status`),
  KEY `idx_po_vendor` (`vendor_external_id`),
  KEY `idx_po_campaign` (`campaign_external_id`),
  KEY `idx_po_rfq` (`rfq_external_id`),
  KEY `idx_po_delivery_date` (`required_delivery_date`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `purchase_orders`
--

LOCK TABLES `purchase_orders` WRITE;
/*!40000 ALTER TABLE `purchase_orders` DISABLE KEYS */;
INSERT INTO `purchase_orders` VALUES (1,'po-001-uuid','PO-2025-001','rfq-001-uuid','RFQ-2025-001','camp-001-uuid','SUMMER25-TOY','award-001-uuid','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise (500k units)',500000,0.8200,410000.00,'USD','50% upfront, 50% on shipment','2025-04-30','2025-04-01','FOB','Port of Los Angeles','SENT_TO_VENDOR','procurement.manager','procurement.director','2026-01-15 09:00:00','Vietnam vendor awarded for fastest lead time (35 days) and ISO 9001 certification.','2026-03-18 10:56:05','2026-03-18 15:57:04'),(2,'po-002-uuid','PO-2025-002','rfq-002-uuid','RFQ-2025-002','camp-002-uuid','HOLIDAY25-TOY','award-002-uuid','vnd-001-uuid','VND-CN-001','Shenzhen BrightToy Manufacturing Co.','CHINA','Holiday 2025 Collectible Figurines — 6 Character Series (1.2M units)',1200000,0.7800,936000.00,'USD','NET30','2025-10-15','2025-09-15','CIF','Port of Long Beach','DRAFT','procurement.manager',NULL,NULL,'Pending final approval from CFO due to order value exceeding $900k threshold.','2026-03-18 10:56:05','2026-03-18 10:56:05'),(3,'0b6c76ab-bf51-4a9c-87d4-11543da1a7ea','PO-2025-003','rfq-003-ext-uuid','RFQ-2025-003','camp-001-uuid','SUMMER25-TOY','award-003-ext-uuid','vnd-004-uuid','VND-TH-001','Bangkok Fun Factory Co. Ltd.','THAILAND','Space Explorer Figure Series — Summer 2025 (250k units)',250000,0.9300,232500.00,'USD','NET30','2025-05-15','2025-04-20','FOB','Port of Los Angeles','COMPLETED','procurement.manager','procurement.director','2026-03-18 15:57:04','Awarded to Bangkok Fun Factory. Premium finish. ISO 14001 certified.','2026-03-18 15:57:04','2026-03-18 15:57:04'),(4,'d7344e34-1d7a-4bf2-8ce7-7067b0b69df7','PO-2025-004','2ebe6a47-161b-48ac-84c8-26fcdca27e7a','RFQ-2025-004','camp-001-uuid','SUMMER25-TOY','87937ea0-de94-4d14-9ea8-b268f51fdeab','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','Spring Promotion Supply — Mixed Figures (500 units)',500,0.7900,395.00,'USD','NET30','2025-07-15','2025-06-15','FOB','Port of Los Angeles','APPROVED','agent','agent','2026-04-03 13:36:49',NULL,'2026-04-03 13:29:38','2026-04-03 13:36:49'),(5,'cb129ede-4eed-4187-b676-60b23e29d787','PO-AGENT-D9B2FED5','2a69612d-607c-4b5e-bd01-135e29a4808b','RFQ-AGENT','44e362cb-3a5a-4230-b0e6-00d5af6f7295','SPRING-PROMOTI-45F71','d366fd5d-0285-4ae5-987f-fbe75155c92e','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','Agent-generated PO — Ho Chi Minh Playthings Ltd. — 500 units @ $0.79',500,0.7900,395.00,'USD','NET30','2026-07-02','2026-06-02','FOB','Port of Los Angeles','ACKNOWLEDGED','agent','agent','2026-04-03 16:58:04',NULL,'2026-04-03 16:58:04','2026-04-03 16:58:04'),(6,'c0353401-91db-42a3-8cd4-444e16e02e6a','PO-AGENT-8EFB77B9','b9b3909c-41c1-4cd9-9ea7-a3bda4b0f514','RFQ-AGENT','2aaff0da-a322-4edb-8684-54b96e27dbc0','SPRING-PROMOTI-E7606','97fe2b55-59d6-46a8-9589-83e4bfdbe8ac','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','Agent-generated PO — Ho Chi Minh Playthings Ltd. — 500 units @ $0.79',500,0.7900,395.00,'USD','NET30','2026-07-02','2026-06-02','FOB','Port of Los Angeles','ACKNOWLEDGED','agent','agent','2026-04-03 17:10:32',NULL,'2026-04-03 17:10:32','2026-04-03 17:10:32'),(7,'0279711c-081d-4c7c-80be-6e69391408c5','PO-AGENT-DDE4FB19','998f8bd8-fa90-4031-b69c-ff0fa85555b1','RFQ-AGENT','9cbc529d-41eb-400b-9150-c6326af95860','SPRING-PROMOTI-179B6','7693d71c-be65-45c2-8372-d2ccc0258121','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','Agent-generated PO — Ho Chi Minh Playthings Ltd. — 500 units @ $0.79',500,0.7900,395.00,'USD','NET30','2026-07-02','2026-06-02','FOB','Port of Los Angeles','ACKNOWLEDGED','agent','agent','2026-04-03 17:16:09',NULL,'2026-04-03 17:16:09','2026-04-03 17:16:09');
/*!40000 ALTER TABLE `purchase_orders` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-04 10:20:01
