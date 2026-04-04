CREATE DATABASE  IF NOT EXISTS `cs_crm` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cs_crm`;
-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (x86_64)
--
-- Host: localhost    Database: cs_crm
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
-- Table structure for table `campaign_customers`
--

DROP TABLE IF EXISTS `campaign_customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `campaign_customers` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `campaign_id` bigint unsigned NOT NULL,
  `customer_id` bigint unsigned NOT NULL,
  `enrolled_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `enrollment_channel` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'SYSTEM' COMMENT 'APP, IMPORT, SYSTEM',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_cc_campaign_customer` (`campaign_id`,`customer_id`),
  KEY `idx_cc_campaign_id` (`campaign_id`),
  KEY `idx_cc_customer_id` (`customer_id`),
  CONSTRAINT `fk_cc_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `campaigns` (`id`),
  CONSTRAINT `fk_cc_customer` FOREIGN KEY (`customer_id`) REFERENCES `customers` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `campaign_customers`
--

LOCK TABLES `campaign_customers` WRITE;
/*!40000 ALTER TABLE `campaign_customers` DISABLE KEYS */;
INSERT INTO `campaign_customers` VALUES (1,1,1,'2026-03-18 10:08:04','SYSTEM'),(2,1,2,'2026-03-18 10:08:04','SYSTEM'),(3,1,4,'2026-03-18 10:08:04','SYSTEM'),(4,1,5,'2026-03-18 10:08:04','SYSTEM'),(5,1,7,'2026-03-18 10:08:04','SYSTEM'),(6,1,9,'2026-03-18 10:08:04','SYSTEM');
/*!40000 ALTER TABLE `campaign_customers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `campaign_events`
--

DROP TABLE IF EXISTS `campaign_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `campaign_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `campaign_id` bigint unsigned NOT NULL,
  `event_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. LAUNCHED, PAUSED, COMPLETED',
  `previous_status` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `triggered_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rabbitmq_published` tinyint(1) NOT NULL DEFAULT '0' COMMENT '1 = message published to exchange',
  PRIMARY KEY (`id`),
  KEY `idx_ce_campaign_id` (`campaign_id`),
  KEY `idx_ce_event_type` (`event_type`),
  CONSTRAINT `fk_ce_campaign` FOREIGN KEY (`campaign_id`) REFERENCES `campaigns` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=31 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `campaign_events`
--

LOCK TABLES `campaign_events` WRITE;
/*!40000 ALTER TABLE `campaign_events` DISABLE KEYS */;
INSERT INTO `campaign_events` VALUES (1,1,'CREATED',NULL,'DRAFT','Campaign record created via seed','admin','2026-03-18 10:08:04',0),(2,2,'CREATED',NULL,'DRAFT','Campaign record created via seed','admin','2026-03-18 10:08:04',0),(3,3,'CREATED',NULL,'DRAFT','Campaign record created via seed','admin','2026-03-18 10:08:04',0),(4,4,'CREATED',NULL,'DRAFT','Campaign created','campaign.manager','2026-03-18 10:10:40',0),(5,4,'LAUNCHED','DRAFT','ACTIVE','All vendor contracts signed. Toy production confirmed. Launch approved.','campaign.manager','2026-03-18 10:10:40',1),(6,4,'PAUSED','ACTIVE','PAUSED','Supply delay from Vietnam vendor. Pausing for 2 weeks.','ops.manager','2026-03-18 10:10:40',1),(7,4,'COMPLETED','PAUSED','COMPLETED','Campaign ran full season. All toys distributed to stores.','campaign.manager','2026-03-18 10:10:40',1),(8,1,'LAUNCHED','DRAFT','ACTIVE','RabbitMQ message proof test','test.validation','2026-03-18 10:15:54',1),(9,2,'LAUNCHED','DRAFT','ACTIVE','Validating queue binding','rabbitmq.test','2026-03-18 10:18:17',1),(10,3,'LAUNCHED','DRAFT','ACTIVE','Testing source field fix','source.field.test','2026-03-18 10:22:30',1),(11,5,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 07:52:15',0),(12,5,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 09:21:42',1),(13,6,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 09:33:04',0),(14,6,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 09:33:04',1),(15,7,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 09:37:36',0),(16,7,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 09:37:36',1),(17,8,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 11:33:46',0),(18,8,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 11:33:46',1),(19,9,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 11:42:20',0),(20,9,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 11:42:20',1),(21,10,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 11:46:57',0),(22,10,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 11:46:57',1),(23,11,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 11:51:47',0),(24,11,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 11:51:47',1),(25,12,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 11:57:34',0),(26,12,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 11:57:35',1),(27,13,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 12:10:07',0),(28,13,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 12:10:08',1),(29,14,'CREATED',NULL,'DRAFT','Campaign created','agent','2026-04-03 12:15:44',0),(30,14,'LAUNCHED','DRAFT','ACTIVE',NULL,'agent','2026-04-03 12:15:44',1);
/*!40000 ALTER TABLE `campaign_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `campaigns`
--

DROP TABLE IF EXISTS `campaigns`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `campaigns` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'UUID assigned by app layer',
  `campaign_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Short code e.g. SUMMER25-TOY',
  `description` text COLLATE utf8mb4_unicode_ci,
  `campaign_type` enum('TOY_SURPRISE','SEASONAL','LOYALTY','PROMO') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'TOY_SURPRISE',
  `status` enum('DRAFT','ACTIVE','PAUSED','COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `budget_usd` decimal(15,2) NOT NULL DEFAULT '0.00',
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `target_region` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. US-MIDWEST, NATIONAL',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_campaigns_extid` (`external_id`),
  UNIQUE KEY `uq_campaigns_code` (`campaign_code`),
  KEY `idx_campaigns_status` (`status`),
  KEY `idx_campaigns_dates` (`start_date`,`end_date`),
  CONSTRAINT `chk_campaigns_dates` CHECK ((`end_date` >= `start_date`))
) ENGINE=InnoDB AUTO_INCREMENT=15 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `campaigns`
--

LOCK TABLES `campaigns` WRITE;
/*!40000 ALTER TABLE `campaigns` DISABLE KEYS */;
INSERT INTO `campaigns` VALUES (1,'camp-001-uuid','Summer Surprise 2025','SUMMER25-TOY','Kids meal toy surprise campaign for summer 2025. Toys sourced from Thailand and Vietnam vendors. Packaged as a mystery surprise inside every kids meal.','TOY_SURPRISE','ACTIVE',750000.00,'2025-06-01','2025-08-31','NATIONAL','admin','2026-03-18 10:08:04','2026-03-18 10:15:54'),(2,'camp-002-uuid','Holiday Collectibles 2025','HOLIDAY25-TOY','Winter holiday collectible toy series. Limited edition figurines across 6 characters. Sourced from China vendor.','TOY_SURPRISE','ACTIVE',1200000.00,'2025-11-15','2025-12-31','NATIONAL','admin','2026-03-18 10:08:04','2026-03-18 10:18:17'),(3,'camp-003-uuid','Spring Loyalty Boost','SPRING25-LOYAL','Loyalty points double-up promotion for Gold and Platinum customers during spring.','LOYALTY','ACTIVE',200000.00,'2025-03-20','2025-05-31','US-MIDWEST','admin','2026-03-18 10:08:04','2026-03-18 10:22:30'),(4,'39e3b4cb-8b7c-4e67-b0c9-fc145ea6016e','Autumn Adventure 2025','AUTUMN25-TOY','Fall season toy surprise campaign. Mystery dinosaur figures sourced from Vietnam vendor.','TOY_SURPRISE','COMPLETED',850000.00,'2025-09-01','2025-11-30','US-MIDWEST','campaign.manager','2026-03-18 10:10:40','2026-03-18 10:10:40'),(5,'eb946d40-6f18-4403-82a9-9d91262d1bc4','Smoke Test Campaign','SMOKE-001',NULL,'PROMO','ACTIVE',1000.00,'2025-06-01','2025-08-31','MIDWEST','agent','2026-04-03 07:52:15','2026-04-03 09:21:42'),(6,'2f5397c0-39c2-4b3f-9605-f83cf4db3a49','Spring Promotion Campaign','SPRING-PROMOTION-CAM',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 09:33:04','2026-04-03 09:33:04'),(7,'2aced0ca-137a-49d8-87a0-80155029f6fe','Spring Promotion Campaign','SPRING-PROMOTI-256DB',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 09:37:36','2026-04-03 09:37:36'),(8,'abed8471-81e8-463d-a3b0-0b1d0e1d1f68','Spring Promotion Campaign','SPRING-PROMOTI-0CE98',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 11:33:46','2026-04-03 11:33:46'),(9,'5fe31240-feea-4378-82f4-7eabf3823bb5','Spring Promotion Campaign','SPRING-PROMOTI-864DE',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 11:42:20','2026-04-03 11:42:20'),(10,'51b6a72f-4b82-4033-92ff-a36d9b20566b','Spring Promotion Campaign','SPRING-PROMOTI-EF749',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 11:46:57','2026-04-03 11:46:57'),(11,'5da9307f-3f0d-44f3-af64-25b1b1e687e8','Spring Promotion Campaign','SPRING-PROMOTI-B0961',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 11:51:47','2026-04-03 11:51:47'),(12,'44e362cb-3a5a-4230-b0e6-00d5af6f7295','Spring Promotion Campaign','SPRING-PROMOTI-45F71',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 11:57:34','2026-04-03 11:57:35'),(13,'2aaff0da-a322-4edb-8684-54b96e27dbc0','Spring Promotion Campaign','SPRING-PROMOTI-E7606',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 12:10:07','2026-04-03 12:10:08'),(14,'9cbc529d-41eb-400b-9150-c6326af95860','Spring Promotion Campaign','SPRING-PROMOTI-179B6',NULL,'PROMO','ACTIVE',25000.00,'2026-04-03','2027-04-03','MIDWEST','agent','2026-04-03 12:15:44','2026-04-03 12:15:44');
/*!40000 ALTER TABLE `campaigns` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `customers`
--

DROP TABLE IF EXISTS `customers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `customers` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'UUID assigned by app layer',
  `first_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `last_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `email` varchar(255) COLLATE utf8mb4_unicode_ci NOT NULL,
  `phone` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tier` enum('STANDARD','GOLD','PLATINUM') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'STANDARD',
  `status` enum('ACTIVE','INACTIVE','SUSPENDED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_customers_extid` (`external_id`),
  UNIQUE KEY `uq_customers_email` (`email`),
  KEY `idx_customers_status` (`status`),
  KEY `idx_customers_tier` (`tier`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `customers`
--

LOCK TABLES `customers` WRITE;
/*!40000 ALTER TABLE `customers` DISABLE KEYS */;
INSERT INTO `customers` VALUES (1,'cust-001-uuid','Sarah','Mitchell','sarah.mitchell@example.com','312-555-0101','PLATINUM','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(2,'cust-002-uuid','James','Hargrove','james.hargrove@example.com','773-555-0102','GOLD','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(3,'cust-003-uuid','Maria','Delgado','maria.delgado@example.com','847-555-0103','STANDARD','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(4,'cust-004-uuid','Kevin','Okafor','kevin.okafor@example.com','630-555-0104','GOLD','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(5,'cust-005-uuid','Linda','Fujimoto','linda.fujimoto@example.com','312-555-0105','PLATINUM','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(6,'cust-006-uuid','Thomas','Brennan','thomas.brennan@example.com','708-555-0106','STANDARD','INACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(7,'cust-007-uuid','Aisha','Rahman','aisha.rahman@example.com','773-555-0107','GOLD','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(8,'cust-008-uuid','Carlos','Espinoza','carlos.espinoza@example.com','312-555-0108','STANDARD','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(9,'cust-009-uuid','Priya','Sharma','priya.sharma@example.com','847-555-0109','PLATINUM','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(10,'cust-010-uuid','Derek','Walton','derek.walton@example.com','630-555-0110','STANDARD','ACTIVE','2026-03-18 10:08:04','2026-03-18 10:08:04'),(11,'0819d19e-3920-4bbf-a1d5-9a3968809611','Jessica','Park','jessica.park@test.com','312-555-9001','PLATINUM','ACTIVE','2026-03-18 10:10:39','2026-03-18 10:10:39'),(12,'10fdb68f-fb3b-4ba7-bd09-c819bc07c9b0','Marcus','Lee','marcus.lee@test.com','773-555-9002','GOLD','ACTIVE','2026-03-18 10:10:39','2026-03-18 10:10:39');
/*!40000 ALTER TABLE `customers` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-04 10:16:40
