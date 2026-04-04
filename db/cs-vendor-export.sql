CREATE DATABASE  IF NOT EXISTS `cs_vendor` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cs_vendor`;
-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (x86_64)
--
-- Host: localhost    Database: cs_vendor
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
-- Table structure for table `rfq_awards`
--

DROP TABLE IF EXISTS `rfq_awards`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rfq_awards` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rfq_id` bigint unsigned NOT NULL,
  `winning_vendor_id` bigint unsigned NOT NULL,
  `winning_quote_id` bigint unsigned NOT NULL,
  `awarded_quantity` int unsigned NOT NULL,
  `awarded_unit_cost_usd` decimal(10,4) NOT NULL,
  `total_award_value_usd` decimal(15,2) NOT NULL,
  `award_notes` text COLLATE utf8mb4_unicode_ci,
  `awarded_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `awarded_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rabbitmq_published` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rfqa_external_id` (`external_id`),
  UNIQUE KEY `uq_rfqa_rfq_id` (`rfq_id`) COMMENT 'Only one award per RFQ',
  KEY `fk_rfqa_quote` (`winning_quote_id`),
  KEY `idx_rfqa_vendor_id` (`winning_vendor_id`),
  CONSTRAINT `fk_rfqa_quote` FOREIGN KEY (`winning_quote_id`) REFERENCES `vendor_quotes` (`id`),
  CONSTRAINT `fk_rfqa_rfq` FOREIGN KEY (`rfq_id`) REFERENCES `rfqs` (`id`),
  CONSTRAINT `fk_rfqa_vendor` FOREIGN KEY (`winning_vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rfq_awards`
--

LOCK TABLES `rfq_awards` WRITE;
/*!40000 ALTER TABLE `rfq_awards` DISABLE KEYS */;
INSERT INTO `rfq_awards` VALUES (2,'b3b1e8d0-a880-4fbe-8c95-5abd55c9eae2',5,4,7,250000,0.9300,232500.00,'Thailand vendor selected for premium finish and faster delivery. Scorecard 4.75 is highest among bidders.','procurement.director','2026-03-18 15:43:48',1),(3,'87937ea0-de94-4d14-9ea8-b268f51fdeab',7,2,9,500,0.7900,395.00,NULL,'agent','2026-04-03 13:25:28',1),(4,'a5eca617-8b1b-40a6-9e29-c9bb6504ae77',8,2,11,500,0.7900,395.00,NULL,'agent','2026-04-03 16:57:59',1),(5,'97fe2b55-59d6-46a8-9589-83e4bfdbe8ac',9,2,14,500,0.7900,395.00,NULL,'agent','2026-04-03 17:10:29',1),(6,'7693d71c-be65-45c2-8372-d2ccc0258121',10,2,17,500,0.7900,395.00,NULL,'agent','2026-04-03 17:16:06',1);
/*!40000 ALTER TABLE `rfq_awards` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rfq_vendors`
--

DROP TABLE IF EXISTS `rfq_vendors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rfq_vendors` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `rfq_id` bigint unsigned NOT NULL,
  `vendor_id` bigint unsigned NOT NULL,
  `invited_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rfq_vendor` (`rfq_id`,`vendor_id`),
  KEY `idx_rfqv_rfq_id` (`rfq_id`),
  KEY `idx_rfqv_vendor_id` (`vendor_id`),
  CONSTRAINT `fk_rfqv_rfq` FOREIGN KEY (`rfq_id`) REFERENCES `rfqs` (`id`),
  CONSTRAINT `fk_rfqv_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rfq_vendors`
--

LOCK TABLES `rfq_vendors` WRITE;
/*!40000 ALTER TABLE `rfq_vendors` DISABLE KEYS */;
INSERT INTO `rfq_vendors` VALUES (1,1,1,'2026-03-18 10:38:07'),(2,1,2,'2026-03-18 10:38:07'),(3,1,3,'2026-03-18 10:38:07'),(4,1,4,'2026-03-18 10:38:07'),(10,5,1,'2026-03-18 15:43:48'),(11,5,4,'2026-03-18 15:43:48');
/*!40000 ALTER TABLE `rfq_vendors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `rfqs`
--

DROP TABLE IF EXISTS `rfqs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `rfqs` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rfq_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Human-readable e.g. RFQ-2025-001',
  `campaign_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'References cs_crm.campaigns.external_id',
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `toy_category` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. Dinosaur Figures, Action Heroes',
  `quantity_required` int unsigned NOT NULL,
  `unit` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PIECES',
  `target_unit_cost_usd` decimal(10,4) DEFAULT NULL,
  `required_by_date` date NOT NULL COMMENT 'Date toys must be at DC',
  `submission_deadline` date NOT NULL COMMENT 'Vendor quote due date',
  `status` enum('DRAFT','OPEN','UNDER_REVIEW','AWARDED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rfqs_external_id` (`external_id`),
  UNIQUE KEY `uq_rfqs_number` (`rfq_number`),
  KEY `idx_rfqs_status` (`status`),
  KEY `idx_rfqs_campaign` (`campaign_external_id`),
  KEY `idx_rfqs_dates` (`submission_deadline`,`required_by_date`),
  CONSTRAINT `chk_rfqs_dates` CHECK ((`required_by_date` > `submission_deadline`))
) ENGINE=InnoDB AUTO_INCREMENT=11 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `rfqs`
--

LOCK TABLES `rfqs` WRITE;
/*!40000 ALTER TABLE `rfqs` DISABLE KEYS */;
INSERT INTO `rfqs` VALUES (1,'rfq-001-uuid','RFQ-2025-001','camp-001-uuid','SUMMER25-TOY','Summer 2025 Toy Surprise — Dinosaur Figure Series','Sourcing 500,000 mystery dinosaur figures for kids meal toy surprise campaign. Must meet CPSC safety standards. Individually packaged in branded surprise box.','Dinosaur Figures',500000,'PIECES',0.8500,'2025-04-30','2025-02-28','OPEN','procurement.manager','2026-03-18 10:38:07','2026-03-18 10:38:07'),(2,'rfq-002-uuid','RFQ-2025-002','camp-002-uuid','HOLIDAY25-TOY','Holiday 2025 — Collectible Figurine Series (6 Characters)','Sourcing 1,200,000 collectible holiday figurines across 6 character designs. Premium finish required. Full color box packaging included.','Collectible Figurines',1200000,'PIECES',1.2000,'2025-10-15','2025-07-31','DRAFT','procurement.manager','2026-03-18 10:38:07','2026-03-18 10:38:07'),(5,'618a497f-7817-46d0-bdc7-e6db011810e0','RFQ-2025-003','camp-001-uuid','SUMMER25-TOY','Summer 2025 — Space Explorer Figure Series','250,000 space explorer toy figures for the summer kids meal campaign. UV-safe paint required.','Space Explorer Figures',250000,'PIECES',0.9000,'2025-05-15','2025-03-31','AWARDED','procurement.manager','2026-03-18 15:43:48','2026-03-18 15:43:48'),(6,'7d174479-b6f8-4639-8c0d-fce45c71d4bb','RFQ-2025-CANCEL','camp-002-uuid','HOLIDAY25-TOY','Test RFQ for cancellation',NULL,NULL,10000,'PIECES',NULL,'2025-12-01','2025-09-30','CANCELLED','test.user','2026-03-18 15:43:48','2026-03-18 15:43:48'),(7,'2ebe6a47-161b-48ac-84c8-26fcdca27e7a','RFQ-2025-004','camp-001-uuid','SUMMER25-TOY','Spring Promotion Supply RFQ','Bulk supply for spring promotion campaign','Mixed Figures',500,'PIECES',1.0000,'2025-07-15','2025-06-30','AWARDED','agent','2026-04-03 13:07:31','2026-04-03 13:25:28'),(8,'2a69612d-607c-4b5e-bd01-135e29a4808b','RFQ-AGENT-3483E515','44e362cb-3a5a-4230-b0e6-00d5af6f7295','SPRING-PROMOTI-45F71','Q2 Supply RFQ','Bulk supply for spring promotion','Mixed Figures',500,'PIECES',1.0000,'2027-04-03','2025-06-30','AWARDED','agent','2026-04-03 16:57:35','2026-04-03 16:57:59'),(9,'b9b3909c-41c1-4cd9-9ea7-a3bda4b0f514','RFQ-AGENT-321865C3','2aaff0da-a322-4edb-8684-54b96e27dbc0','SPRING-PROMOTI-E7606','Q2 Supply RFQ','Bulk supply for spring promotion','Mixed Figures',500,'PIECES',1.0000,'2027-04-03','2025-06-30','AWARDED','agent','2026-04-03 17:10:08','2026-04-03 17:10:30'),(10,'998f8bd8-fa90-4031-b69c-ff0fa85555b1','RFQ-AGENT-4098F162','9cbc529d-41eb-400b-9150-c6326af95860','SPRING-PROMOTI-179B6','Q2 Supply RFQ','Bulk supply for spring promotion','Mixed Figures',500,'PIECES',1.0000,'2027-04-03','2025-06-30','AWARDED','agent','2026-04-03 17:15:44','2026-04-03 17:16:06');
/*!40000 ALTER TABLE `rfqs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vendor_quotes`
--

DROP TABLE IF EXISTS `vendor_quotes`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendor_quotes` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `rfq_id` bigint unsigned NOT NULL,
  `vendor_id` bigint unsigned NOT NULL,
  `quoted_unit_cost_usd` decimal(10,4) NOT NULL,
  `quoted_quantity` int unsigned NOT NULL,
  `total_cost_usd` decimal(15,2) NOT NULL,
  `lead_time_days` int unsigned NOT NULL,
  `delivery_date` date NOT NULL,
  `payment_terms` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `status` enum('SUBMITTED','UNDER_REVIEW','ACCEPTED','REJECTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SUBMITTED',
  `submitted_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vq_external_id` (`external_id`),
  UNIQUE KEY `uq_vq_rfq_vendor` (`rfq_id`,`vendor_id`) COMMENT 'One quote per vendor per RFQ',
  KEY `idx_vq_rfq_id` (`rfq_id`),
  KEY `idx_vq_vendor_id` (`vendor_id`),
  KEY `idx_vq_status` (`status`),
  CONSTRAINT `fk_vq_rfq` FOREIGN KEY (`rfq_id`) REFERENCES `rfqs` (`id`),
  CONSTRAINT `fk_vq_vendor` FOREIGN KEY (`vendor_id`) REFERENCES `vendors` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=19 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vendor_quotes`
--

LOCK TABLES `vendor_quotes` WRITE;
/*!40000 ALTER TABLE `vendor_quotes` DISABLE KEYS */;
INSERT INTO `vendor_quotes` VALUES (1,'quote-001-uuid',1,1,0.7800,500000,390000.00,42,'2025-04-20','NET30','Can produce all 500k units in single production run. CPSC test reports available.','SUBMITTED','2026-03-18 10:38:07','2026-03-18 10:38:07'),(2,'quote-002-uuid',1,2,0.8200,500000,410000.00,35,'2025-04-15','50% upfront, 50% on shipment','Faster lead time. ISO 9001 certified facility. Free sample set available.','SUBMITTED','2026-03-18 10:38:07','2026-03-18 10:38:07'),(3,'quote-003-uuid',1,4,0.9100,500000,455000.00,40,'2025-04-25','NET30','Premium quality finish. Highest rated vendor. Slightly above target cost.','SUBMITTED','2026-03-18 10:38:07','2026-03-18 10:38:07'),(4,'quote-004-uuid',1,3,0.7200,500000,360000.00,52,'2025-04-28','NET45','Lowest cost but longest lead time. Recommend for split order consideration.','SUBMITTED','2026-03-18 10:38:07','2026-03-18 10:38:07'),(6,'f9d02fea-12c7-4bdc-8807-b3e2b59a1911',5,1,0.8400,250000,210000.00,42,'2025-05-10','NET30','Single-run production. ASTM F963 certified. Sample batch available in 2 weeks.','REJECTED','2026-03-18 15:43:48','2026-03-18 15:43:48'),(7,'cb125f30-7ad3-4b2f-9884-c6c548556f86',5,4,0.9300,250000,232500.00,38,'2025-05-05','NET30','Premium finish, faster delivery. ISO 14001 certified. Scorecard 4.75.','ACCEPTED','2026-03-18 15:43:48','2026-03-18 15:43:48'),(8,'b9a7f7e0-5d33-40f5-8fb3-adbf2d38ae41',7,1,0.8200,500,410.00,45,'2025-07-10',NULL,'Can meet CPSC standards','REJECTED','2026-04-03 13:13:06','2026-04-03 13:25:28'),(9,'05a7eadb-6be4-4346-b40e-1a398a1eb538',7,2,0.7900,500,395.00,38,'2025-07-05',NULL,'Competitive pricing with fast delivery','ACCEPTED','2026-04-03 13:14:05','2026-04-03 13:25:28'),(10,'2cff7c72-f591-4669-8c77-40d30c2e5d33',8,1,0.8200,500,410.00,45,'2026-05-18',NULL,'Quote submitted by agent','REJECTED','2026-04-03 16:57:35','2026-04-03 16:57:59'),(11,'d366fd5d-0285-4ae5-987f-fbe75155c92e',8,2,0.7900,500,395.00,38,'2026-05-11',NULL,'Quote submitted by agent','ACCEPTED','2026-04-03 16:57:35','2026-04-03 16:57:59'),(12,'8aafc23c-271f-4b5e-80a8-478b0c999e98',8,3,0.8800,500,440.00,55,'2026-05-28',NULL,'Quote submitted by agent','REJECTED','2026-04-03 16:57:35','2026-04-03 16:57:59'),(13,'339ed9cb-9480-48c2-a047-ee1ed0cdac84',9,1,0.8200,500,410.00,45,'2026-05-18',NULL,'Quote submitted by agent','REJECTED','2026-04-03 17:10:08','2026-04-03 17:10:30'),(14,'c2add4ef-cc84-4ed6-8e9e-498daf6f7329',9,2,0.7900,500,395.00,38,'2026-05-11',NULL,'Quote submitted by agent','ACCEPTED','2026-04-03 17:10:08','2026-04-03 17:10:30'),(15,'e861bd5c-0f9a-4b7c-a6bb-40b152ba934b',9,3,0.8800,500,440.00,55,'2026-05-28',NULL,'Quote submitted by agent','REJECTED','2026-04-03 17:10:08','2026-04-03 17:10:30'),(16,'3e4a40a4-65f3-4b25-a2aa-3cae92db6d95',10,1,0.8200,500,410.00,45,'2026-05-18',NULL,'Quote submitted by agent','REJECTED','2026-04-03 17:15:44','2026-04-03 17:16:06'),(17,'16f3914c-8503-47f2-ada0-768a64149b6f',10,2,0.7900,500,395.00,38,'2026-05-11',NULL,'Quote submitted by agent','ACCEPTED','2026-04-03 17:15:44','2026-04-03 17:16:06'),(18,'5f9daac1-4465-45a3-871a-2bf177a02397',10,3,0.8800,500,440.00,55,'2026-05-28',NULL,'Quote submitted by agent','REJECTED','2026-04-03 17:15:44','2026-04-03 17:16:06');
/*!40000 ALTER TABLE `vendor_quotes` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vendors`
--

DROP TABLE IF EXISTS `vendors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `vendors` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Short code e.g. VND-CN-001',
  `country` enum('CHINA','VIETNAM','INDIA','THAILAND','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL,
  `contact_name` varchar(150) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_email` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `contact_phone` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `address` text COLLATE utf8mb4_unicode_ci,
  `status` enum('ACTIVE','INACTIVE','BLACKLISTED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `category` enum('TOY_MANUFACTURER','PACKAGING','LOGISTICS','OTHER') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'TOY_MANUFACTURER',
  `lead_time_days` int unsigned DEFAULT NULL COMMENT 'Typical production lead time in days',
  `payment_terms` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. NET30, 50% upfront',
  `scorecard_rating` decimal(3,2) DEFAULT NULL COMMENT '0.00 to 5.00',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_vendors_external_id` (`external_id`),
  UNIQUE KEY `uq_vendors_code` (`vendor_code`),
  KEY `idx_vendors_country` (`country`),
  KEY `idx_vendors_status` (`status`),
  KEY `idx_vendors_category` (`category`),
  CONSTRAINT `chk_vendors_rating` CHECK (((`scorecard_rating` is null) or ((`scorecard_rating` >= 0) and (`scorecard_rating` <= 5))))
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vendors`
--

LOCK TABLES `vendors` WRITE;
/*!40000 ALTER TABLE `vendors` DISABLE KEYS */;
INSERT INTO `vendors` VALUES (1,'vnd-001-uuid','Shenzhen BrightToy Manufacturing Co.','VND-CN-001','CHINA','Wei Zhang','wei.zhang@brighttoy.cn','+86-755-8801-2233','18 Longhua Industrial Zone, Shenzhen, Guangdong, China 518109','ACTIVE','TOY_MANUFACTURER',45,'NET30',4.20,'2026-03-18 10:38:07','2026-03-18 10:38:07'),(2,'vnd-002-uuid','Ho Chi Minh Playthings Ltd.','VND-VN-001','VIETNAM','Nguyen Thi Lan','lan.nguyen@hcmplaythings.vn','+84-28-3822-5511','45 Tan Binh Industrial Park, Ho Chi Minh City, Vietnam','ACTIVE','TOY_MANUFACTURER',38,'50% upfront, 50% on shipment',4.50,'2026-03-18 10:38:07','2026-03-18 10:38:07'),(3,'vnd-003-uuid','Pune Creative Toys Pvt. Ltd.','VND-IN-001','INDIA','Rajesh Mehta','rajesh.mehta@punecreative.in','+91-20-2712-8899','Plot 22, Bhosari MIDC Industrial Area, Pune, Maharashtra 411026, India','ACTIVE','TOY_MANUFACTURER',55,'NET45',3.90,'2026-03-18 10:38:07','2026-03-18 10:38:07'),(4,'vnd-004-uuid','Bangkok Fun Factory Co. Ltd.','VND-TH-001','THAILAND','Somchai Wattana','somchai@bangkokfun.co.th','+66-2-685-4400','99 Moo 4, Amata City Industrial Estate, Chonburi 20160, Thailand','ACTIVE','TOY_MANUFACTURER',42,'NET30',4.75,'2026-03-18 10:38:07','2026-03-18 10:38:07'),(5,'vnd-005-uuid','Guangzhou PackMaster Co.','VND-CN-002','CHINA','Li Mei','limei@gzpackmaster.cn','+86-20-6601-3344','88 Panyu Economic Development Zone, Guangzhou, China 511400','ACTIVE','PACKAGING',30,'NET30',4.00,'2026-03-18 10:38:07','2026-03-18 10:38:07'),(6,'vnd-006-uuid','Hanoi Precision Plastics','VND-VN-002','VIETNAM','Tran Van Duc','duc.tran@hanoiplastics.vn','+84-24-3826-7700','12 Quang Minh Industrial Zone, Me Linh, Hanoi, Vietnam','ACTIVE','TOY_MANUFACTURER',40,'NET30',4.10,'2026-03-18 10:38:07','2026-03-18 10:38:07'),(7,'vnd-007-uuid','Chennai Toy Crafts Ltd.','VND-IN-002','INDIA','Priya Rajan','priya@chennaicrafts.in','+91-44-2431-5566','No. 7 SIDCO Industrial Estate, Ambattur, Chennai 600058, India','INACTIVE','TOY_MANUFACTURER',60,'NET60',3.20,'2026-03-18 10:38:07','2026-03-18 10:38:07'),(9,'dda64767-3689-4999-bd86-5baf98f158c2','Dongguan SuperToy Co. Ltd.','VND-CN-003','CHINA','Chen Wei','chenwei@dongguan-supertoy.cn','+86-769-8801-5599','Building 3, Houjie Town Industrial Park, Dongguan, Guangdong 523940','ACTIVE','TOY_MANUFACTURER',40,'NET30',4.60,'2026-03-18 15:43:48','2026-03-18 15:43:48');
/*!40000 ALTER TABLE `vendors` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-04 10:21:07
