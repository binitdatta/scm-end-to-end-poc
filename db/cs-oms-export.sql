CREATE DATABASE  IF NOT EXISTS `cs_oms` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cs_oms`;
-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (x86_64)
--
-- Host: localhost    Database: cs_oms
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
-- Table structure for table `allocation_run`
--

DROP TABLE IF EXISTS `allocation_run`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `allocation_run` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `run_reference` varchar(50) NOT NULL,
  `campaign_code` varchar(50) NOT NULL,
  `sku_code` varchar(50) NOT NULL,
  `trigger_source` varchar(50) NOT NULL DEFAULT 'MANUAL',
  `available_qty` int NOT NULL,
  `allocated_qty` int NOT NULL DEFAULT '0',
  `stores_targeted` int NOT NULL DEFAULT '0',
  `stores_fulfilled` int NOT NULL DEFAULT '0',
  `status` varchar(30) NOT NULL DEFAULT 'INITIATED',
  `started_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `completed_at` datetime DEFAULT NULL,
  `error_message` varchar(1000) DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_run_reference` (`run_reference`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `allocation_run`
--

LOCK TABLES `allocation_run` WRITE;
/*!40000 ALTER TABLE `allocation_run` DISABLE KEYS */;
/*!40000 ALTER TABLE `allocation_run` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `campaign_allocation_rule`
--

DROP TABLE IF EXISTS `campaign_allocation_rule`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `campaign_allocation_rule` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `campaign_code` varchar(50) NOT NULL,
  `sku_code` varchar(50) NOT NULL,
  `store_tier` varchar(20) NOT NULL,
  `units_per_store` int NOT NULL,
  `priority` int NOT NULL DEFAULT '1',
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rule` (`campaign_code`,`sku_code`,`store_tier`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `campaign_allocation_rule`
--

LOCK TABLES `campaign_allocation_rule` WRITE;
/*!40000 ALTER TABLE `campaign_allocation_rule` DISABLE KEYS */;
INSERT INTO `campaign_allocation_rule` VALUES (1,'SUMMER25-TOY','TOY-DINO-MIX-001','TIER1',200,1,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(2,'SUMMER25-TOY','TOY-DINO-MIX-001','TIER2',130,2,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(3,'SUMMER25-TOY','TOY-DINO-MIX-001','TIER3',80,3,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(4,'SUMMER25-TOY','TOY-SPACE-MIX-001','TIER1',100,1,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(5,'SUMMER25-TOY','TOY-SPACE-MIX-001','TIER2',65,2,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(6,'SUMMER25-TOY','TOY-SPACE-MIX-001','TIER3',40,3,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(7,'HOLIDAY25-TOY','TOY-DINO-MIX-001','TIER1',150,1,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(8,'HOLIDAY25-TOY','TOY-DINO-MIX-001','TIER2',100,2,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(9,'HOLIDAY25-TOY','TOY-DINO-MIX-001','TIER3',60,3,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(10,'HOLIDAY25-TOY','TOY-SPACE-MIX-001','TIER1',80,1,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(11,'HOLIDAY25-TOY','TOY-SPACE-MIX-001','TIER2',50,2,1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(12,'HOLIDAY25-TOY','TOY-SPACE-MIX-001','TIER3',30,3,1,'2026-03-18 14:26:49','2026-03-18 14:26:49');
/*!40000 ALTER TABLE `campaign_allocation_rule` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_availability`
--

DROP TABLE IF EXISTS `inventory_availability`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_availability` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_available` int unsigned NOT NULL DEFAULT '0',
  `quantity_reserved` int unsigned NOT NULL DEFAULT '0',
  `quantity_remaining` int unsigned NOT NULL DEFAULT '0',
  `source_asn_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `last_updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_inv_sku_campaign` (`sku`,`campaign_code`),
  KEY `idx_inv_sku` (`sku`),
  KEY `idx_inv_campaign` (`campaign_code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_availability`
--

LOCK TABLES `inventory_availability` WRITE;
/*!40000 ALTER TABLE `inventory_availability` DISABLE KEYS */;
INSERT INTO `inventory_availability` VALUES (1,'TOY-DINO-MIX-001','SUMMER25-TOY',499800,232000,267800,'ASN-2025-001','2026-03-19 13:53:24'),(2,'TOY-SPACE-MIX-001','SUMMER25-TOY',249950,0,249950,'ASN-2025-003','2026-03-19 08:45:40'),(3,'TOY-MIXED-001','SUMMER25-TOY',500,500,0,NULL,'2026-04-03 13:57:34'),(4,'TOY-MIXED-001','SPRING-PROMOTI-45F71',500,500,0,NULL,'2026-04-03 16:58:31'),(5,'TOY-MIXED-001','SPRING-PROMOTI-E7606',500,500,0,NULL,'2026-04-03 17:10:49'),(6,'TOY-MIXED-001','SPRING-PROMOTI-179B6',500,500,0,NULL,'2026-04-03 17:16:27');
/*!40000 ALTER TABLE `inventory_availability` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_snapshot`
--

DROP TABLE IF EXISTS `inventory_snapshot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_snapshot` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `sku_code` varchar(50) NOT NULL,
  `zone_code` varchar(20) NOT NULL,
  `campaign_code` varchar(50) DEFAULT NULL,
  `available_qty` int NOT NULL DEFAULT '0',
  `reserved_qty` int NOT NULL DEFAULT '0',
  `last_event_id` varchar(100) DEFAULT NULL,
  `snapshot_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sku_zone` (`sku_code`,`zone_code`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_snapshot`
--

LOCK TABLES `inventory_snapshot` WRITE;
/*!40000 ALTER TABLE `inventory_snapshot` DISABLE KEYS */;
INSERT INTO `inventory_snapshot` VALUES (1,'TOY-DINO-MIX-001','ZONE-A','SUMMER25-TOY',499800,0,NULL,'2026-03-18 14:26:49','2026-03-18 14:26:49','2026-03-18 14:26:49'),(2,'TOY-SPACE-MIX-001','ZONE-B','SUMMER25-TOY',249950,0,NULL,'2026-03-18 14:26:49','2026-03-18 14:26:49','2026-03-18 14:26:49');
/*!40000 ALTER TABLE `inventory_snapshot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `order_events`
--

DROP TABLE IF EXISTS `order_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `order_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `store_order_id` bigint unsigned NOT NULL,
  `event_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `previous_status` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `triggered_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rabbitmq_published` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_oe_order` (`store_order_id`),
  CONSTRAINT `fk_oe_order` FOREIGN KEY (`store_order_id`) REFERENCES `store_orders` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=32 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `order_events`
--

LOCK TABLES `order_events` WRITE;
/*!40000 ALTER TABLE `order_events` DISABLE KEYS */;
INSERT INTO `order_events` VALUES (1,1,'ORDER_CREATED',NULL,'DRAFT','Store order created for Midwest region.','oms.planner','2026-03-19 08:45:40',0),(2,1,'ORDER_SUBMITTED','DRAFT','SUBMITTED','Order submitted for allocation.','oms.planner','2026-03-19 08:45:40',0),(3,1,'ORDER_ALLOCATED','SUBMITTED','ALLOCATED','640 stores x 200 units. Total 128,000 units reserved from TOY-DINO-MIX-001.','oms.system','2026-03-19 08:45:40',1),(4,2,'ORDER_CREATED',NULL,'DRAFT','Store order created for West region.','oms.planner','2026-03-19 08:45:40',0),(5,3,'ORDER_CREATED',NULL,'DRAFT','Order created for region US-SOUTHEAST','oms.planner','2026-03-19 13:53:23',0),(6,3,'ORDER_SUBMITTED','DRAFT','SUBMITTED','Inventory confirmed. Submitting for allocation.','oms.planner','2026-03-19 13:53:23',1),(7,3,'ORDER_ALLOCATED','SUBMITTED','ALLOCATED','4 stores x ~26000 units. Total=104000','oms.system','2026-03-19 13:53:24',1),(8,3,'ORDER_PICKING','ALLOCATED','PICKING','Pick wave WV-2025-003 started. 520 store cartons being picked.','wms.outbound','2026-03-19 13:53:24',1),(9,3,'ORDER_SHIPPED','PICKING','SHIPPED','All 520 store cartons loaded on outbound trucks. En route to Southeast stores.','tms.carrier','2026-03-19 13:53:24',1),(10,3,'ORDER_DELIVERED','SHIPPED','DELIVERED','Delivery confirmed at all 520 SE store locations. POD received.','tms.carrier','2026-03-19 13:53:24',1),(11,4,'ORDER_CREATED',NULL,'DRAFT','Order created for region US-NORTHWEST','test.user','2026-03-19 13:53:24',0),(12,4,'ORDER_CANCELLED','DRAFT','CANCELLED','Campaign budget cut. Order cancelled.','oms.planner','2026-03-19 13:53:24',1),(13,5,'ORDER_CREATED',NULL,'DRAFT','Order created for region US-WEST','test','2026-03-19 13:53:24',0),(14,5,'ORDER_SUBMITTED','DRAFT','SUBMITTED',NULL,'test','2026-03-19 13:53:24',1),(15,2,'ORDER_SUBMITTED','DRAFT','SUBMITTED','West region order submitted for allocation.','oms.planner','2026-03-19 13:53:24',1),(16,6,'ORDER_CREATED',NULL,'DRAFT','Order created for region US-MIDWEST','agent','2026-04-03 13:56:21',0),(17,6,'ORDER_SUBMITTED','DRAFT','SUBMITTED',NULL,'agent','2026-04-03 13:56:55',1),(18,6,'ORDER_ALLOCATED','SUBMITTED','ALLOCATED','4 stores x ~125 units. Total=500','agent','2026-04-03 13:57:34',1),(19,6,'ORDER_PICKING','ALLOCATED','PICKING',NULL,'agent','2026-04-03 13:58:10',1),(20,7,'ORDER_CREATED',NULL,'DRAFT','Order created for region US-MIDWEST','agent','2026-04-03 16:58:31',0),(21,7,'ORDER_SUBMITTED','DRAFT','SUBMITTED',NULL,'agent','2026-04-03 16:58:31',1),(22,7,'ORDER_ALLOCATED','SUBMITTED','ALLOCATED','4 stores x ~125 units. Total=500','agent','2026-04-03 16:58:31',1),(23,7,'ORDER_PICKING','ALLOCATED','PICKING',NULL,'agent','2026-04-03 16:58:31',1),(24,8,'ORDER_CREATED',NULL,'DRAFT','Order created for region US-MIDWEST','agent','2026-04-03 17:10:49',0),(25,8,'ORDER_SUBMITTED','DRAFT','SUBMITTED',NULL,'agent','2026-04-03 17:10:49',1),(26,8,'ORDER_ALLOCATED','SUBMITTED','ALLOCATED','4 stores x ~125 units. Total=500','agent','2026-04-03 17:10:49',1),(27,8,'ORDER_PICKING','ALLOCATED','PICKING',NULL,'agent','2026-04-03 17:10:49',1),(28,9,'ORDER_CREATED',NULL,'DRAFT','Order created for region US-MIDWEST','agent','2026-04-03 17:16:27',0),(29,9,'ORDER_SUBMITTED','DRAFT','SUBMITTED',NULL,'agent','2026-04-03 17:16:27',1),(30,9,'ORDER_ALLOCATED','SUBMITTED','ALLOCATED','4 stores x ~125 units. Total=500','agent','2026-04-03 17:16:27',1),(31,9,'ORDER_PICKING','ALLOCATED','PICKING',NULL,'agent','2026-04-03 17:16:27',1);
/*!40000 ALTER TABLE `order_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `outbound_event_log`
--

DROP TABLE IF EXISTS `outbound_event_log`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `outbound_event_log` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `event_id` varchar(100) NOT NULL,
  `event_type` varchar(100) NOT NULL,
  `store_order_id` bigint DEFAULT NULL,
  `allocation_run_id` bigint DEFAULT NULL,
  `payload` mediumtext,
  `published_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_event_id` (`event_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `outbound_event_log`
--

LOCK TABLES `outbound_event_log` WRITE;
/*!40000 ALTER TABLE `outbound_event_log` DISABLE KEYS */;
/*!40000 ALTER TABLE `outbound_event_log` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `store_location`
--

DROP TABLE IF EXISTS `store_location`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `store_location` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `store_code` varchar(20) NOT NULL,
  `store_name` varchar(100) NOT NULL,
  `region` varchar(50) NOT NULL,
  `state` varchar(2) NOT NULL,
  `city` varchar(100) NOT NULL,
  `address` varchar(255) DEFAULT NULL,
  `is_active` tinyint(1) NOT NULL DEFAULT '1',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_store_code` (`store_code`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `store_location`
--

LOCK TABLES `store_location` WRITE;
/*!40000 ALTER TABLE `store_location` DISABLE KEYS */;
INSERT INTO `store_location` VALUES (1,'STORE-NE-001','Toy Kingdom Boston','NORTHEAST','MA','Boston','100 Tremont St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(2,'STORE-NE-002','Toy Kingdom Hartford','NORTHEAST','CT','Hartford','200 Main St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(3,'STORE-NE-003','Toy Kingdom Providence','NORTHEAST','RI','Providence','50 Broad St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(4,'STORE-NE-004','Toy Kingdom Albany','NORTHEAST','NY','Albany','300 State St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(5,'STORE-NE-005','Toy Kingdom Manchester','NORTHEAST','NH','Manchester','10 Elm St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(6,'STORE-NE-006','Toy Kingdom Burlington','NORTHEAST','VT','Burlington','75 Church St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(7,'STORE-NE-007','Toy Kingdom Portland','NORTHEAST','ME','Portland','20 Congress St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(8,'STORE-NE-008','Toy Kingdom Newark','NORTHEAST','NJ','Newark','400 Market St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(9,'STORE-NE-009','Toy Kingdom Pittsburgh','NORTHEAST','PA','Pittsburgh','250 Forbes Ave',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(10,'STORE-NE-010','Toy Kingdom Buffalo','NORTHEAST','NY','Buffalo','100 Main St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(11,'STORE-SE-001','Toy Kingdom Atlanta','SOUTHEAST','GA','Atlanta','500 Peachtree St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(12,'STORE-SE-002','Toy Kingdom Miami','SOUTHEAST','FL','Miami','100 Biscayne Blvd',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(13,'STORE-SE-003','Toy Kingdom Charlotte','SOUTHEAST','NC','Charlotte','300 Tryon St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(14,'STORE-SE-004','Toy Kingdom Nashville','SOUTHEAST','TN','Nashville','200 Broadway',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(15,'STORE-SE-005','Toy Kingdom Birmingham','SOUTHEAST','AL','Birmingham','100 20th St N',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(16,'STORE-SE-006','Toy Kingdom New Orleans','SOUTHEAST','LA','New Orleans','300 Canal St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(17,'STORE-SE-007','Toy Kingdom Columbia','SOUTHEAST','SC','Columbia','250 Main St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(18,'STORE-SE-008','Toy Kingdom Richmond','SOUTHEAST','VA','Richmond','100 Broad St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(19,'STORE-SE-009','Toy Kingdom Jacksonville','SOUTHEAST','FL','Jacksonville','200 Bay St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(20,'STORE-SE-010','Toy Kingdom Memphis','SOUTHEAST','TN','Memphis','150 Beale St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(21,'STORE-MW-001','Toy Kingdom Chicago','MIDWEST','IL','Chicago','233 S Wacker Dr',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(22,'STORE-MW-002','Toy Kingdom Detroit','MIDWEST','MI','Detroit','100 Renaissance Ctr',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(23,'STORE-MW-003','Toy Kingdom Minneapolis','MIDWEST','MN','Minneapolis','800 Nicollet Mall',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(24,'STORE-MW-004','Toy Kingdom Cleveland','MIDWEST','OH','Cleveland','200 Public Square',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(25,'STORE-MW-005','Toy Kingdom Indianapolis','MIDWEST','IN','Indianapolis','250 Monument Cir',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(26,'STORE-MW-006','Toy Kingdom Milwaukee','MIDWEST','WI','Milwaukee','310 E Michigan St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(27,'STORE-MW-007','Toy Kingdom Columbus','MIDWEST','OH','Columbus','100 E Broad St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(28,'STORE-MW-008','Toy Kingdom Kansas City','MIDWEST','MO','Kansas City','400 Grand Blvd',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(29,'STORE-MW-009','Toy Kingdom Omaha','MIDWEST','NE','Omaha','100 Dodge St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(30,'STORE-MW-010','Toy Kingdom Des Moines','MIDWEST','IA','Des Moines','300 Locust St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(31,'STORE-SW-001','Toy Kingdom Dallas','SOUTHWEST','TX','Dallas','200 Commerce St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(32,'STORE-SW-002','Toy Kingdom Houston','SOUTHWEST','TX','Houston','500 Dallas St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(33,'STORE-SW-003','Toy Kingdom Phoenix','SOUTHWEST','AZ','Phoenix','100 N Central Ave',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(34,'STORE-SW-004','Toy Kingdom San Antonio','SOUTHWEST','TX','San Antonio','300 E Commerce',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(35,'STORE-SW-005','Toy Kingdom Denver','SOUTHWEST','CO','Denver','1600 Glenarm Pl',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(36,'STORE-SW-006','Toy Kingdom Albuquerque','SOUTHWEST','NM','Albuquerque','200 Central Ave SW',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(37,'STORE-SW-007','Toy Kingdom Las Vegas','SOUTHWEST','NV','Las Vegas','3600 S Las Vegas Blvd',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(38,'STORE-SW-008','Toy Kingdom Tucson','SOUTHWEST','AZ','Tucson','100 E Broadway',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(39,'STORE-SW-009','Toy Kingdom El Paso','SOUTHWEST','TX','El Paso','200 San Jacinto Plz',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(40,'STORE-SW-010','Toy Kingdom Oklahoma City','SOUTHWEST','OK','Oklahoma City','100 N Broadway Ave',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(41,'STORE-WE-001','Toy Kingdom Los Angeles','WEST','CA','Los Angeles','350 S Grand Ave',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(42,'STORE-WE-002','Toy Kingdom San Francisco','WEST','CA','San Francisco','1 Market St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(43,'STORE-WE-003','Toy Kingdom Seattle','WEST','WA','Seattle','400 Pine St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(44,'STORE-WE-004','Toy Kingdom Portland','WEST','OR','Portland','100 SW Main St',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(45,'STORE-WE-005','Toy Kingdom San Diego','WEST','CA','San Diego','200 Harbor Dr',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(46,'STORE-WE-006','Toy Kingdom Sacramento','WEST','CA','Sacramento','300 Capitol Mall',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(47,'STORE-WE-007','Toy Kingdom Salt Lake City','WEST','UT','Salt Lake City','100 W Temple',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(48,'STORE-WE-008','Toy Kingdom Boise','WEST','ID','Boise','200 N Capitol Blvd',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(49,'STORE-WE-009','Toy Kingdom Honolulu','WEST','HI','Honolulu','100 Ala Moana Blvd',1,'2026-03-18 14:26:49','2026-03-18 14:26:49'),(50,'STORE-WE-010','Toy Kingdom Anchorage','WEST','AK','Anchorage','600 W 5th Ave',1,'2026-03-18 14:26:49','2026-03-18 14:26:49');
/*!40000 ALTER TABLE `store_location` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `store_order`
--

DROP TABLE IF EXISTS `store_order`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `store_order` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `order_number` varchar(50) NOT NULL,
  `store_id` bigint NOT NULL,
  `campaign_code` varchar(50) NOT NULL,
  `sku_code` varchar(50) NOT NULL,
  `requested_qty` int NOT NULL,
  `allocated_qty` int NOT NULL DEFAULT '0',
  `status` varchar(30) NOT NULL DEFAULT 'PENDING',
  `allocation_run_id` bigint DEFAULT NULL,
  `notes` varchar(500) DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_order_number` (`order_number`),
  KEY `fk_so_store` (`store_id`),
  CONSTRAINT `fk_so_store` FOREIGN KEY (`store_id`) REFERENCES `store_location` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `store_order`
--

LOCK TABLES `store_order` WRITE;
/*!40000 ALTER TABLE `store_order` DISABLE KEYS */;
/*!40000 ALTER TABLE `store_order` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `store_order_lines`
--

DROP TABLE IF EXISTS `store_order_lines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `store_order_lines` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_order_id` bigint unsigned NOT NULL,
  `store_id` bigint unsigned NOT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_allocated` int unsigned NOT NULL DEFAULT '0',
  `quantity_shipped` int unsigned NOT NULL DEFAULT '0',
  `quantity_delivered` int unsigned NOT NULL DEFAULT '0',
  `status` enum('PENDING','ALLOCATED','SHIPPED','DELIVERED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sol_external_id` (`external_id`),
  UNIQUE KEY `uq_sol_order_store` (`store_order_id`,`store_id`),
  KEY `idx_sol_order` (`store_order_id`),
  KEY `idx_sol_store` (`store_id`),
  KEY `idx_sol_status` (`status`),
  CONSTRAINT `fk_sol_order` FOREIGN KEY (`store_order_id`) REFERENCES `store_orders` (`id`),
  CONSTRAINT `fk_sol_store` FOREIGN KEY (`store_id`) REFERENCES `stores` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=28 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `store_order_lines`
--

LOCK TABLES `store_order_lines` WRITE;
/*!40000 ALTER TABLE `store_order_lines` DISABLE KEYS */;
INSERT INTO `store_order_lines` VALUES (1,'sol-STR-0001-001',1,1,'TOY-DINO-MIX-001',200,0,0,'ALLOCATED'),(2,'sol-STR-0002-001',1,2,'TOY-DINO-MIX-001',200,0,0,'ALLOCATED'),(3,'sol-STR-0003-001',1,3,'TOY-DINO-MIX-001',200,0,0,'ALLOCATED'),(4,'sol-STR-0004-001',1,4,'TOY-DINO-MIX-001',200,0,0,'ALLOCATED'),(8,'bcd76547-ec1b-4d9e-b10d-6f720db0fd5f',3,9,'TOY-DINO-MIX-001',26000,26000,26000,'DELIVERED'),(9,'da6536cb-d361-479e-8595-a43f9cd70650',3,10,'TOY-DINO-MIX-001',26000,26000,26000,'DELIVERED'),(10,'2f34750f-dd39-4a0b-ba70-0e96c21b4291',3,11,'TOY-DINO-MIX-001',26000,26000,26000,'DELIVERED'),(11,'7a7827bb-cd6c-4f07-8aba-b5eff878b9c7',3,12,'TOY-DINO-MIX-001',26000,26000,26000,'DELIVERED'),(12,'ced65cfc-88f3-4923-8260-45823a1d6a94',6,1,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(13,'e2da9493-06b2-4972-ab83-c5aca9f7f124',6,2,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(14,'3da1de32-487e-4956-8c03-6a90393603e6',6,3,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(15,'c5f2a494-1b00-4fc3-8975-6405a79cc3f6',6,4,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(16,'0caa0d52-903d-4d25-b693-6a0a66fee068',7,1,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(17,'cbf209ac-e901-4aae-8e56-36fcdb0f68b2',7,2,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(18,'e1e3cd53-cf67-45ac-8a7f-f6019be48dde',7,3,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(19,'8346ae62-8e52-4a92-a7c6-0454ba87c083',7,4,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(20,'f727dd1d-caaa-40e8-9f1b-8ea2af3ee3b2',8,1,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(21,'8c3a2de3-e31c-4134-8a19-c8c1f01d4d7b',8,2,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(22,'140f2c3c-3ca7-4644-9a34-43b1b3046927',8,3,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(23,'403ddbc7-efb7-4c9a-98ab-230bcc3acfba',8,4,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(24,'920ca866-01ba-4f25-8af7-66842478d432',9,1,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(25,'242beb21-8736-455f-a3bc-bc166d758c4f',9,2,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(26,'1c129587-9e2f-4eb4-87c0-090b624f10b3',9,3,'TOY-MIXED-001',125,0,0,'ALLOCATED'),(27,'5dde8185-c871-4307-a15e-726e5b2f56f3',9,4,'TOY-MIXED-001',125,0,0,'ALLOCATED');
/*!40000 ALTER TABLE `store_order_lines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `store_orders`
--

DROP TABLE IF EXISTS `store_orders`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `store_orders` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `order_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_id` bigint unsigned NOT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `toy_description` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_requested` int unsigned NOT NULL,
  `quantity_allocated` int unsigned NOT NULL DEFAULT '0',
  `quantity_per_store` int unsigned DEFAULT NULL,
  `requested_delivery_date` date NOT NULL,
  `allocated_at` datetime DEFAULT NULL,
  `status` enum('DRAFT','SUBMITTED','ALLOCATED','PICKING','SHIPPED','DELIVERED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'DRAFT',
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_so_external_id` (`external_id`),
  UNIQUE KEY `uq_so_order_number` (`order_number`),
  KEY `idx_so_campaign` (`campaign_external_id`),
  KEY `idx_so_status` (`status`),
  KEY `idx_so_region` (`region_id`),
  KEY `idx_so_sku` (`sku`),
  CONSTRAINT `fk_so_region` FOREIGN KEY (`region_id`) REFERENCES `store_regions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=10 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `store_orders`
--

LOCK TABLES `store_orders` WRITE;
/*!40000 ALTER TABLE `store_orders` DISABLE KEYS */;
INSERT INTO `store_orders` VALUES (1,'ord-001-uuid','ORD-2025-001','camp-001-uuid','SUMMER25-TOY',1,'TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',128000,128000,200,'2025-06-01','2026-01-20 09:00:00','ALLOCATED','oms.planner','Midwest allocation: 640 stores x 200 units each. Reserved from ASN-2025-001.','2026-03-19 08:45:40','2026-03-19 08:45:40'),(2,'ord-002-uuid','ORD-2025-002','camp-001-uuid','SUMMER25-TOY',2,'TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',116000,0,NULL,'2025-06-01',NULL,'SUBMITTED','oms.planner','West allocation: 580 stores x 200 units each. Pending submission and allocation.','2026-03-19 08:45:40','2026-03-19 13:53:24'),(3,'a094fc71-2302-4981-b13d-d4a270480a76','ORD-2025-003','camp-001-uuid','SUMMER25-TOY',3,'TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',104000,104000,26000,'2025-06-01','2026-03-19 13:53:24','DELIVERED','oms.planner','Southeast allocation: 520 stores x 200 units each.','2026-03-19 13:53:23','2026-03-19 13:53:24'),(4,'15fdd5a7-183c-4a07-b258-b5e002d64bc1','ORD-2025-CANCEL','camp-001-uuid','SUMMER25-TOY',6,'TOY-DINO-MIX-001','Test cancel order',10000,0,NULL,'2025-06-15',NULL,'CANCELLED','test.user',NULL,'2026-03-19 13:53:24','2026-03-19 13:53:24'),(5,'5e8171a2-9d90-4af8-bc5d-0324cf82b60a','ORD-2025-HUGE','camp-001-uuid','SUMMER25-TOY',2,'TOY-DINO-MIX-001','Too large order',9999999,0,NULL,'2025-06-01',NULL,'SUBMITTED','test',NULL,'2026-03-19 13:53:24','2026-03-19 13:53:24'),(6,'f00f6978-8f23-4604-bc87-f47520cbbfa1','ORD-AGENT-001','camp-001-uuid','SUMMER25-TOY',1,'TOY-MIXED-001','Mixed Figures - Spring Promotion',500,500,125,'2025-07-20','2026-04-03 13:57:34','PICKING','agent',NULL,'2026-04-03 13:56:21','2026-04-03 13:58:10'),(7,'7feaa08f-a75f-4443-8fb5-734b9eb96ad3','ORD-AGENT-DD069853','44e362cb-3a5a-4230-b0e6-00d5af6f7295','SPRING-PROMOTI-45F71',1,'TOY-MIXED-001','Mixed Figures — Spring Promotion',500,500,125,'2026-05-03','2026-04-03 16:58:31','PICKING','agent',NULL,'2026-04-03 16:58:31','2026-04-03 16:58:31'),(8,'027e1cea-0bcf-43ca-8e81-a5d858973bee','ORD-AGENT-3A3CD9FE','2aaff0da-a322-4edb-8684-54b96e27dbc0','SPRING-PROMOTI-E7606',1,'TOY-MIXED-001','Mixed Figures — Spring Promotion',500,500,125,'2026-05-03','2026-04-03 17:10:49','PICKING','agent',NULL,'2026-04-03 17:10:49','2026-04-03 17:10:49'),(9,'43fcfa84-ef8e-413c-ae80-404e4ff286fa','ORD-AGENT-5CBA8E9A','9cbc529d-41eb-400b-9150-c6326af95860','SPRING-PROMOTI-179B6',1,'TOY-MIXED-001','Mixed Figures — Spring Promotion',500,500,125,'2026-05-03','2026-04-03 17:16:27','PICKING','agent',NULL,'2026-04-03 17:16:27','2026-04-03 17:16:27');
/*!40000 ALTER TABLE `store_orders` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `store_regions`
--

DROP TABLE IF EXISTS `store_regions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `store_regions` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_count` int unsigned NOT NULL DEFAULT '0',
  `distribution_dc` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. DC-CHICAGO, DC-LOS-ANGELES',
  `status` enum('ACTIVE','INACTIVE') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sr_external_id` (`external_id`),
  UNIQUE KEY `uq_sr_code` (`region_code`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `store_regions`
--

LOCK TABLES `store_regions` WRITE;
/*!40000 ALTER TABLE `store_regions` DISABLE KEYS */;
INSERT INTO `store_regions` VALUES (1,'reg-001-uuid','US-MIDWEST','Midwest United States',640,'DC-CHICAGO','ACTIVE','2026-03-19 08:45:40'),(2,'reg-002-uuid','US-WEST','Western United States',580,'DC-LOS-ANGELES','ACTIVE','2026-03-19 08:45:40'),(3,'reg-003-uuid','US-SOUTHEAST','Southeast United States',520,'DC-ATLANTA','ACTIVE','2026-03-19 08:45:40'),(4,'reg-004-uuid','US-NORTHEAST','Northeast United States',480,'DC-NEW-YORK','ACTIVE','2026-03-19 08:45:40'),(5,'reg-005-uuid','US-SOUTHWEST','Southwest United States',440,'DC-DALLAS','ACTIVE','2026-03-19 08:45:40'),(6,'reg-006-uuid','US-NORTHWEST','Northwest United States',540,'DC-SEATTLE','ACTIVE','2026-03-19 08:45:40');
/*!40000 ALTER TABLE `store_regions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `store_tier_assignment`
--

DROP TABLE IF EXISTS `store_tier_assignment`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `store_tier_assignment` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `store_id` bigint NOT NULL,
  `campaign_code` varchar(50) NOT NULL,
  `store_tier` varchar(20) NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_store_campaign` (`store_id`,`campaign_code`),
  CONSTRAINT `fk_sta_store` FOREIGN KEY (`store_id`) REFERENCES `store_location` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=51 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `store_tier_assignment`
--

LOCK TABLES `store_tier_assignment` WRITE;
/*!40000 ALTER TABLE `store_tier_assignment` DISABLE KEYS */;
INSERT INTO `store_tier_assignment` VALUES (1,1,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(2,2,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(3,3,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(4,4,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(5,5,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(6,6,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(7,7,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(8,8,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(9,9,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(10,10,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(11,11,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(12,12,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(13,13,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(14,14,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(15,15,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(16,16,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(17,17,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(18,18,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(19,19,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(20,20,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(21,21,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(22,22,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(23,23,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(24,24,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(25,25,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(26,26,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(27,27,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(28,28,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(29,29,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(30,30,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(31,31,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(32,32,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(33,33,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(34,34,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(35,35,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(36,36,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(37,37,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(38,38,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(39,39,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(40,40,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(41,41,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(42,42,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(43,43,'SUMMER25-TOY','TIER1','2026-03-18 14:26:49'),(44,44,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(45,45,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(46,46,'SUMMER25-TOY','TIER2','2026-03-18 14:26:49'),(47,47,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(48,48,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(49,49,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49'),(50,50,'SUMMER25-TOY','TIER3','2026-03-18 14:26:49');
/*!40000 ALTER TABLE `store_tier_assignment` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `stores`
--

DROP TABLE IF EXISTS `stores`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `stores` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_id` bigint unsigned NOT NULL,
  `address` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `zip_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `status` enum('ACTIVE','INACTIVE','CLOSED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'ACTIVE',
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_stores_external_id` (`external_id`),
  UNIQUE KEY `uq_stores_number` (`store_number`),
  KEY `idx_stores_region` (`region_id`),
  KEY `idx_stores_status` (`status`),
  CONSTRAINT `fk_stores_region` FOREIGN KEY (`region_id`) REFERENCES `store_regions` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `stores`
--

LOCK TABLES `stores` WRITE;
/*!40000 ALTER TABLE `stores` DISABLE KEYS */;
INSERT INTO `stores` VALUES (1,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown',1,'100 N Michigan Ave','Chicago','IL','60601','ACTIVE','2026-03-19 08:45:40'),(2,'str-002-uuid','STR-0002','Burger Bliss Naperville',1,'204 S Washington St','Naperville','IL','60540','ACTIVE','2026-03-19 08:45:40'),(3,'str-003-uuid','STR-0003','Burger Bliss Milwaukee',1,'780 N Water St','Milwaukee','WI','53202','ACTIVE','2026-03-19 08:45:40'),(4,'str-004-uuid','STR-0004','Burger Bliss Indianapolis',1,'1 Monument Circle','Indianapolis','IN','46204','ACTIVE','2026-03-19 08:45:40'),(5,'str-005-uuid','STR-0101','Burger Bliss Los Angeles Downtown',2,'333 S Grand Ave','Los Angeles','CA','90071','ACTIVE','2026-03-19 08:45:40'),(6,'str-006-uuid','STR-0102','Burger Bliss San Francisco',2,'1 Market St','San Francisco','CA','94105','ACTIVE','2026-03-19 08:45:40'),(7,'str-007-uuid','STR-0103','Burger Bliss Las Vegas Strip',2,'3700 Las Vegas Blvd S','Las Vegas','NV','89109','ACTIVE','2026-03-19 08:45:40'),(8,'str-008-uuid','STR-0104','Burger Bliss Phoenix',2,'201 E Washington St','Phoenix','AZ','85004','ACTIVE','2026-03-19 08:45:40'),(9,'str-009-uuid','STR-0201','Burger Bliss Atlanta Midtown',3,'848 Peachtree St NE','Atlanta','GA','30308','ACTIVE','2026-03-19 08:45:40'),(10,'str-010-uuid','STR-0202','Burger Bliss Miami Brickell',3,'1221 Brickell Ave','Miami','FL','33131','ACTIVE','2026-03-19 08:45:40'),(11,'str-011-uuid','STR-0203','Burger Bliss Charlotte',3,'100 N Tryon St','Charlotte','NC','28202','ACTIVE','2026-03-19 08:45:40'),(12,'str-012-uuid','STR-0204','Burger Bliss Nashville',3,'209 10th Ave S','Nashville','TN','37203','ACTIVE','2026-03-19 08:45:40'),(13,'str-013-uuid','STR-0301','Burger Bliss New York Midtown',4,'1 Times Square','New York','NY','10036','ACTIVE','2026-03-19 08:45:40'),(14,'str-014-uuid','STR-0302','Burger Bliss Boston',4,'100 Boylston St','Boston','MA','02116','ACTIVE','2026-03-19 08:45:40'),(15,'str-015-uuid','STR-0303','Burger Bliss Philadelphia',4,'1700 Market St','Philadelphia','PA','19103','ACTIVE','2026-03-19 08:45:40'),(16,'str-016-uuid','STR-0304','Burger Bliss Washington DC',4,'1000 Vermont Ave NW','Washington','DC','20005','ACTIVE','2026-03-19 08:45:40'),(17,'str-017-uuid','STR-0401','Burger Bliss Dallas Uptown',5,'3699 McKinney Ave','Dallas','TX','75204','ACTIVE','2026-03-19 08:45:40'),(18,'str-018-uuid','STR-0402','Burger Bliss Houston Galleria',5,'5015 Westheimer Rd','Houston','TX','77056','ACTIVE','2026-03-19 08:45:40'),(19,'str-019-uuid','STR-0501','Burger Bliss Seattle Pike Place',6,'1428 Post Alley','Seattle','WA','98101','ACTIVE','2026-03-19 08:45:40'),(20,'str-020-uuid','STR-0502','Burger Bliss Portland',6,'SW 5th & Morrison','Portland','OR','97204','ACTIVE','2026-03-19 08:45:40');
/*!40000 ALTER TABLE `stores` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-04 10:19:02
