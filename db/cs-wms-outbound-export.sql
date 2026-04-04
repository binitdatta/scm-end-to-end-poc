CREATE DATABASE  IF NOT EXISTS `cs_wms_outbound` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cs_wms_outbound`;
-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (x86_64)
--
-- Host: localhost    Database: cs_wms_outbound
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
-- Table structure for table `outbound_events`
--

DROP TABLE IF EXISTS `outbound_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `outbound_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `entity_type` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'PICK_WAVE or SHIPMENT',
  `entity_id` bigint unsigned NOT NULL,
  `event_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `previous_status` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `triggered_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rabbitmq_published` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_oe_entity` (`entity_type`,`entity_id`)
) ENGINE=InnoDB AUTO_INCREMENT=49 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `outbound_events`
--

LOCK TABLES `outbound_events` WRITE;
/*!40000 ALTER TABLE `outbound_events` DISABLE KEYS */;
INSERT INTO `outbound_events` VALUES (1,'PICK_WAVE',1,'WAVE_CREATED',NULL,'CREATED','Pick wave created from ORD-2025-001 allocation event.','wms.outbound.coordinator','2026-03-19 09:11:28',1),(2,'PICK_WAVE',1,'WAVE_ASSIGNED','CREATED','ASSIGNED','Assigned to picker.team.01.','wms.outbound.coordinator','2026-03-19 09:11:28',0),(3,'PICK_WAVE',1,'WAVE_COMPLETED','PICKING','COMPLETED','128,000 units picked from ZONE-A. 2 bin locations cleared.','picker.team.01','2026-03-19 09:11:28',1),(4,'SHIPMENT',1,'SHIPMENT_CREATED',NULL,'CREATED','Shipment SHP-2025-001 created from completed pick wave WV-2025-001.','wms.outbound.coordinator','2026-03-19 09:11:28',1),(5,'SHIPMENT',1,'SHIPMENT_PACKED','CREATED','PACKED','4 store cartons packed and labeled. Carton labels printed.','wms.outbound.packer','2026-03-19 09:11:28',1),(6,'SHIPMENT',1,'SHIPMENT_MANIFESTED','PACKED','MANIFESTED','XPO manifest generated. PRO XPO-2025-MW-0441 assigned.','wms.outbound.coordinator','2026-03-19 09:11:28',1),(7,'SHIPMENT',1,'SHIPMENT_DISPATCHED','MANIFESTED','DISPATCHED','XPO driver collected. 4 cartons en route to Midwest stores.','wms.outbound.coordinator','2026-03-19 09:11:28',1),(8,'PICK_WAVE',2,'WAVE_CREATED',NULL,'CREATED','Pick wave created for order ORD-2025-003','wms.outbound.coordinator','2026-03-19 14:12:14',0),(9,'PICK_WAVE',2,'WAVE_ASSIGNED','CREATED','ASSIGNED','Assigned to picker.team.02','picker.team.02','2026-03-19 14:12:14',0),(10,'PICK_WAVE',2,'WAVE_PICKING','ASSIGNED','PICKING','Picking started in ZONE-A.','picker.team.02','2026-03-19 14:12:14',0),(11,'PICK_WAVE',2,'WAVE_COMPLETED','PICKING','COMPLETED','104000 units picked. All 104,000 units picked from ZONE-A. 2 bins cleared.','picker.team.02','2026-03-19 14:12:14',1),(12,'SHIPMENT',2,'SHIPMENT_CREATED',NULL,'CREATED','Shipment created from wave WV-2025-002','wms.outbound.coordinator','2026-03-19 14:12:14',0),(13,'SHIPMENT',2,'SHIPMENT_PACKED','CREATED','PACKED','All 4 SE store cartons packed and labeled.','wms.outbound.packer','2026-03-19 14:12:14',1),(14,'SHIPMENT',2,'SHIPMENT_MANIFESTED','PACKED','MANIFESTED','Carrier: Old Dominion Freight PRO: OD-2025-SE-8812','wms.outbound.coordinator','2026-03-19 14:12:14',1),(15,'SHIPMENT',2,'SHIPMENT_DISPATCHED','MANIFESTED','DISPATCHED','4 cartons dispatched via Old Dominion Freight PRO OD-2025-SE-8812','wms.outbound.coordinator','2026-03-19 14:12:14',1),(16,'PICK_WAVE',3,'WAVE_CREATED',NULL,'CREATED','Pick wave created for order x','test','2026-03-19 14:12:14',0),(17,'PICK_WAVE',4,'WAVE_CREATED',NULL,'CREATED','Pick wave created for order ORD-AGENT-001','agent','2026-04-03 14:02:13',0),(18,'PICK_WAVE',4,'WAVE_ASSIGNED','CREATED','ASSIGNED','Assigned to agent','agent','2026-04-03 14:02:54',0),(19,'PICK_WAVE',4,'WAVE_PICKING','ASSIGNED','PICKING',NULL,'agent','2026-04-03 14:03:27',0),(20,'PICK_WAVE',4,'WAVE_COMPLETED','PICKING','COMPLETED','500 units picked. null','agent','2026-04-03 14:03:55',1),(21,'SHIPMENT',3,'SHIPMENT_CREATED',NULL,'CREATED','Shipment created from wave WV-AGENT-001','agent','2026-04-03 14:07:26',0),(22,'SHIPMENT',3,'SHIPMENT_PACKED','CREATED','PACKED',NULL,'agent','2026-04-03 14:08:02',1),(23,'SHIPMENT',3,'SHIPMENT_MANIFESTED','PACKED','MANIFESTED','Carrier: FedEx Freight PRO: PRO-AGENT-001','wms.outbound.coordinator','2026-04-03 14:08:36',1),(24,'SHIPMENT',3,'SHIPMENT_DISPATCHED','MANIFESTED','DISPATCHED','4 cartons dispatched via FedEx Freight PRO PRO-AGENT-001','agent','2026-04-03 14:09:08',1),(25,'PICK_WAVE',5,'WAVE_CREATED',NULL,'CREATED','Pick wave created for order ORD-AGENT-DD069853','agent','2026-04-03 16:58:31',0),(26,'PICK_WAVE',5,'WAVE_ASSIGNED','CREATED','ASSIGNED','Assigned to agent','agent','2026-04-03 16:58:31',0),(27,'PICK_WAVE',5,'WAVE_PICKING','ASSIGNED','PICKING',NULL,'agent','2026-04-03 16:58:31',0),(28,'PICK_WAVE',5,'WAVE_COMPLETED','PICKING','COMPLETED','500 units picked. null','agent','2026-04-03 16:58:31',1),(29,'SHIPMENT',4,'SHIPMENT_CREATED',NULL,'CREATED','Shipment created from wave WV-AGENT-0D1C6AF4','agent','2026-04-03 16:58:31',0),(30,'SHIPMENT',4,'SHIPMENT_PACKED','CREATED','PACKED',NULL,'agent','2026-04-03 16:58:31',1),(31,'SHIPMENT',4,'SHIPMENT_MANIFESTED','PACKED','MANIFESTED','Carrier: FedEx Freight PRO: PRO-AGENT-A7FF48','wms.outbound.coordinator','2026-04-03 16:58:31',1),(32,'SHIPMENT',4,'SHIPMENT_DISPATCHED','MANIFESTED','DISPATCHED','4 cartons dispatched via FedEx Freight PRO PRO-AGENT-A7FF48','agent','2026-04-03 16:58:31',1),(33,'PICK_WAVE',6,'WAVE_CREATED',NULL,'CREATED','Pick wave created for order ORD-AGENT-3A3CD9FE','agent','2026-04-03 17:10:49',0),(34,'PICK_WAVE',6,'WAVE_ASSIGNED','CREATED','ASSIGNED','Assigned to agent','agent','2026-04-03 17:10:49',0),(35,'PICK_WAVE',6,'WAVE_PICKING','ASSIGNED','PICKING',NULL,'agent','2026-04-03 17:10:49',0),(36,'PICK_WAVE',6,'WAVE_COMPLETED','PICKING','COMPLETED','500 units picked. null','agent','2026-04-03 17:10:49',1),(37,'SHIPMENT',5,'SHIPMENT_CREATED',NULL,'CREATED','Shipment created from wave WV-AGENT-35BD74A1','agent','2026-04-03 17:10:49',0),(38,'SHIPMENT',5,'SHIPMENT_PACKED','CREATED','PACKED',NULL,'agent','2026-04-03 17:10:49',1),(39,'SHIPMENT',5,'SHIPMENT_MANIFESTED','PACKED','MANIFESTED','Carrier: FedEx Freight PRO: PRO-AGENT-C37FF1','wms.outbound.coordinator','2026-04-03 17:10:49',1),(40,'SHIPMENT',5,'SHIPMENT_DISPATCHED','MANIFESTED','DISPATCHED','4 cartons dispatched via FedEx Freight PRO PRO-AGENT-C37FF1','agent','2026-04-03 17:10:49',1),(41,'PICK_WAVE',7,'WAVE_CREATED',NULL,'CREATED','Pick wave created for order ORD-AGENT-5CBA8E9A','agent','2026-04-03 17:16:27',0),(42,'PICK_WAVE',7,'WAVE_ASSIGNED','CREATED','ASSIGNED','Assigned to agent','agent','2026-04-03 17:16:27',0),(43,'PICK_WAVE',7,'WAVE_PICKING','ASSIGNED','PICKING',NULL,'agent','2026-04-03 17:16:27',0),(44,'PICK_WAVE',7,'WAVE_COMPLETED','PICKING','COMPLETED','500 units picked. null','agent','2026-04-03 17:16:27',1),(45,'SHIPMENT',6,'SHIPMENT_CREATED',NULL,'CREATED','Shipment created from wave WV-AGENT-6271826E','agent','2026-04-03 17:16:27',0),(46,'SHIPMENT',6,'SHIPMENT_PACKED','CREATED','PACKED',NULL,'agent','2026-04-03 17:16:27',1),(47,'SHIPMENT',6,'SHIPMENT_MANIFESTED','PACKED','MANIFESTED','Carrier: FedEx Freight PRO: PRO-AGENT-5E984A','wms.outbound.coordinator','2026-04-03 17:16:27',1),(48,'SHIPMENT',6,'SHIPMENT_DISPATCHED','MANIFESTED','DISPATCHED','4 cartons dispatched via FedEx Freight PRO PRO-AGENT-5E984A','agent','2026-04-03 17:16:27',1);
/*!40000 ALTER TABLE `outbound_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `outbound_shipments`
--

DROP TABLE IF EXISTS `outbound_shipments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `outbound_shipments` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shipment_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. SHP-2025-001',
  `pick_wave_id` bigint unsigned NOT NULL,
  `store_order_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_order_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `distribution_dc` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `toy_description` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_cartons` int unsigned NOT NULL COMMENT 'One carton per store',
  `total_units` int unsigned NOT NULL,
  `units_per_carton` int unsigned NOT NULL DEFAULT '1',
  `carrier_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `pro_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Carrier tracking reference',
  `destination_region` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `required_delivery_date` date NOT NULL,
  `estimated_ship_date` date DEFAULT NULL,
  `actual_ship_date` date DEFAULT NULL,
  `status` enum('CREATED','PACKED','MANIFESTED','DISPATCHED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CREATED',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_os_external_id` (`external_id`),
  UNIQUE KEY `uq_os_shipment_number` (`shipment_number`),
  UNIQUE KEY `uq_os_pick_wave` (`pick_wave_id`),
  KEY `idx_os_status` (`status`),
  KEY `idx_os_campaign` (`campaign_code`),
  KEY `idx_os_order` (`store_order_external_id`),
  CONSTRAINT `fk_os_pick_wave` FOREIGN KEY (`pick_wave_id`) REFERENCES `pick_waves` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `outbound_shipments`
--

LOCK TABLES `outbound_shipments` WRITE;
/*!40000 ALTER TABLE `outbound_shipments` DISABLE KEYS */;
INSERT INTO `outbound_shipments` VALUES (1,'shp-001-uuid','SHP-2025-001',1,'ord-001-uuid','ORD-2025-001','camp-001-uuid','SUMMER25-TOY','US-MIDWEST','DC-CHICAGO','TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',4,128000,32000,'XPO Logistics','XPO-2025-MW-0441','Midwest United States','2025-06-01','2025-05-20','2025-05-20','DISPATCHED','All 4 Midwest store cartons dispatched. XPO tracking XPO-2025-MW-0441.','wms.outbound.coordinator','2026-03-19 09:11:28','2026-03-19 09:11:28'),(2,'c957c0dd-418b-4c81-b4ec-731606bb2727','SHP-2025-002',2,'ord-003-ext-uuid','ORD-2025-003','camp-001-uuid','SUMMER25-TOY','US-SOUTHEAST','DC-ATLANTA','TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',4,104000,26000,'Old Dominion Freight','OD-2025-SE-8812',NULL,'2025-06-01','2025-05-28','2026-03-19','DISPATCHED','Southeast store cartons — 4 stores.','wms.outbound.coordinator','2026-03-19 14:12:14','2026-03-19 14:12:14'),(3,'d655b6b3-0add-4eb6-a9f6-80255fd16b58','SHP-AGENT-002',4,'f00f6978-8f23-4604-bc87-f47520cbbfa1','ORD-AGENT-001','camp-001-uuid','SUMMER25-TOY','US-MIDWEST','DC-CHICAGO','TOY-MIXED-001','Mixed Figures - Spring Promotion',4,500,125,'FedEx Freight','PRO-AGENT-001',NULL,'2025-07-20','2025-07-15','2026-04-03','DISPATCHED',NULL,'agent','2026-04-03 14:07:26','2026-04-03 14:09:08'),(4,'0d75f33a-2dbb-47d8-b5f5-df39503481f5','SHP-AGENT-61B953AA',5,'7feaa08f-a75f-4443-8fb5-734b9eb96ad3','ORD-AGENT-DD069853','44e362cb-3a5a-4230-b0e6-00d5af6f7295','SPRING-PROMOTI-45F71','US-MIDWEST','DC-CHICAGO','TOY-MIXED-001','Mixed Figures — Spring Promotion',4,500,125,'FedEx Freight','PRO-AGENT-A7FF48',NULL,'2026-04-10','2026-04-05','2026-04-03','DISPATCHED',NULL,'agent','2026-04-03 16:58:31','2026-04-03 16:58:31'),(5,'d191d9b3-8737-4fc2-a6ba-6eda047c07e7','SHP-AGENT-EF6782CC',6,'027e1cea-0bcf-43ca-8e81-a5d858973bee','ORD-AGENT-3A3CD9FE','2aaff0da-a322-4edb-8684-54b96e27dbc0','SPRING-PROMOTI-E7606','US-MIDWEST','DC-CHICAGO','TOY-MIXED-001','Mixed Figures — Spring Promotion',4,500,125,'FedEx Freight','PRO-AGENT-C37FF1',NULL,'2026-04-10','2026-04-05','2026-04-03','DISPATCHED',NULL,'agent','2026-04-03 17:10:49','2026-04-03 17:10:49'),(6,'8b9ee5c2-515e-49be-afba-ef4943716638','SHP-AGENT-C2CC276F',7,'43fcfa84-ef8e-413c-ae80-404e4ff286fa','ORD-AGENT-5CBA8E9A','9cbc529d-41eb-400b-9150-c6326af95860','SPRING-PROMOTI-179B6','US-MIDWEST','DC-CHICAGO','TOY-MIXED-001','Mixed Figures — Spring Promotion',4,500,125,'FedEx Freight','PRO-AGENT-5E984A',NULL,'2026-04-10','2026-04-05','2026-04-03','DISPATCHED',NULL,'agent','2026-04-03 17:16:27','2026-04-03 17:16:27');
/*!40000 ALTER TABLE `outbound_shipments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pick_wave_lines`
--

DROP TABLE IF EXISTS `pick_wave_lines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pick_wave_lines` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pick_wave_id` bigint unsigned NOT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `warehouse_zone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `warehouse_aisle` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `warehouse_bin` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_to_pick` int unsigned NOT NULL,
  `quantity_picked` int unsigned NOT NULL DEFAULT '0',
  `status` enum('PENDING','PICKED','SHORT','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pwl_external_id` (`external_id`),
  KEY `idx_pwl_wave_id` (`pick_wave_id`),
  KEY `idx_pwl_status` (`status`),
  CONSTRAINT `fk_pwl_wave` FOREIGN KEY (`pick_wave_id`) REFERENCES `pick_waves` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pick_wave_lines`
--

LOCK TABLES `pick_wave_lines` WRITE;
/*!40000 ALTER TABLE `pick_wave_lines` DISABLE KEYS */;
INSERT INTO `pick_wave_lines` VALUES (1,'pwl-001-uuid',1,'TOY-DINO-MIX-001','ZONE-A','A-01','BIN-A-01-001',64000,64000,'PICKED'),(2,'pwl-002-uuid',1,'TOY-DINO-MIX-001','ZONE-A','A-02','BIN-A-02-001',64000,64000,'PICKED'),(3,'e37888af-dc7a-481c-a51a-f46d00c70a69',2,'TOY-DINO-MIX-001','ZONE-A','A-01','BIN-A-01-001',52000,52000,'PICKED'),(4,'69afc906-e37a-414b-b740-8a98b8d6e09f',2,'TOY-DINO-MIX-001','ZONE-A','A-02','BIN-A-02-001',52000,52000,'PICKED');
/*!40000 ALTER TABLE `pick_wave_lines` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `pick_waves`
--

DROP TABLE IF EXISTS `pick_waves`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `pick_waves` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `wave_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. WV-2025-001',
  `store_order_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'cs_oms.store_orders.external_id',
  `store_order_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `toy_description` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_quantity` int unsigned NOT NULL,
  `picked_quantity` int unsigned NOT NULL DEFAULT '0',
  `pick_zone` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. ZONE-A',
  `assigned_to` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `required_ship_date` date NOT NULL,
  `started_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `status` enum('CREATED','ASSIGNED','PICKING','COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CREATED',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_pw_external_id` (`external_id`),
  UNIQUE KEY `uq_pw_wave_number` (`wave_number`),
  KEY `idx_pw_status` (`status`),
  KEY `idx_pw_campaign` (`campaign_code`),
  KEY `idx_pw_order` (`store_order_external_id`),
  KEY `idx_pw_sku` (`sku`)
) ENGINE=InnoDB AUTO_INCREMENT=8 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pick_waves`
--

LOCK TABLES `pick_waves` WRITE;
/*!40000 ALTER TABLE `pick_waves` DISABLE KEYS */;
INSERT INTO `pick_waves` VALUES (1,'pw-001-uuid','WV-2025-001','ord-001-uuid','ORD-2025-001','camp-001-uuid','SUMMER25-TOY','US-MIDWEST','TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',128000,128000,'ZONE-A','picker.team.01','2025-05-20','2025-05-18 07:00:00','2025-05-18 16:00:00','COMPLETED','Full pick completed from ZONE-A. 128,000 units across 4 Midwest stores.','wms.outbound.coordinator','2026-03-19 09:11:28','2026-03-19 09:11:28'),(2,'0d0c6b98-867c-49d8-9dd7-9fd55268f2b3','WV-2025-002','ord-003-ext-uuid','ORD-2025-003','camp-001-uuid','SUMMER25-TOY','US-SOUTHEAST','TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',104000,104000,'ZONE-A','picker.team.02','2025-05-28','2026-03-19 14:12:14','2026-03-19 14:12:14','COMPLETED','Southeast allocation pick — 4 stores x 26,000 units from ZONE-A.','wms.outbound.coordinator','2026-03-19 14:12:14','2026-03-19 14:12:14'),(3,'6744c5e1-e3d6-4440-a9f5-29d504f57e1a','WV-2025-GUARD','x','x','x','x','x','x','x',100,0,NULL,NULL,'2025-06-01',NULL,NULL,'CREATED',NULL,'test','2026-03-19 14:12:14','2026-03-19 14:12:14'),(4,'a952d5d5-259f-4b70-b9d0-5d8e4b7fbf54','WV-AGENT-001','f00f6978-8f23-4604-bc87-f47520cbbfa1','ORD-AGENT-001','camp-001-uuid','SUMMER25-TOY','US-MIDWEST','TOY-MIXED-001','Mixed Figures - Spring Promotion',500,500,'ZONE-A','agent','2025-07-20','2026-04-03 14:03:27','2026-04-03 14:03:55','COMPLETED',NULL,'agent','2026-04-03 14:02:13','2026-04-03 14:03:55'),(5,'db0667b6-550d-4951-b8da-ab8a3534cffe','WV-AGENT-0D1C6AF4','7feaa08f-a75f-4443-8fb5-734b9eb96ad3','ORD-AGENT-DD069853','44e362cb-3a5a-4230-b0e6-00d5af6f7295','SPRING-PROMOTI-45F71','US-MIDWEST','TOY-MIXED-001','Mixed Figures — Spring Promotion',500,500,'ZONE-A','agent','2026-04-10','2026-04-03 16:58:31','2026-04-03 16:58:31','COMPLETED',NULL,'agent','2026-04-03 16:58:31','2026-04-03 16:58:31'),(6,'f6d1174a-c44d-45a0-a4c2-99c3aeefdd79','WV-AGENT-35BD74A1','027e1cea-0bcf-43ca-8e81-a5d858973bee','ORD-AGENT-3A3CD9FE','2aaff0da-a322-4edb-8684-54b96e27dbc0','SPRING-PROMOTI-E7606','US-MIDWEST','TOY-MIXED-001','Mixed Figures — Spring Promotion',500,500,'ZONE-A','agent','2026-04-10','2026-04-03 17:10:49','2026-04-03 17:10:49','COMPLETED',NULL,'agent','2026-04-03 17:10:49','2026-04-03 17:10:49'),(7,'d5b29720-5d9d-4c79-9399-69fd7802691f','WV-AGENT-6271826E','43fcfa84-ef8e-413c-ae80-404e4ff286fa','ORD-AGENT-5CBA8E9A','9cbc529d-41eb-400b-9150-c6326af95860','SPRING-PROMOTI-179B6','US-MIDWEST','TOY-MIXED-001','Mixed Figures — Spring Promotion',500,500,'ZONE-A','agent','2026-04-10','2026-04-03 17:16:27','2026-04-03 17:16:27','COMPLETED',NULL,'agent','2026-04-03 17:16:27','2026-04-03 17:16:27');
/*!40000 ALTER TABLE `pick_waves` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `shipment_store_lines`
--

DROP TABLE IF EXISTS `shipment_store_lines`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `shipment_store_lines` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `shipment_id` bigint unsigned NOT NULL,
  `store_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int unsigned NOT NULL,
  `carton_label` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Barcode label for carton',
  `status` enum('PENDING','PACKED','DISPATCHED','DELIVERED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_ssl_external_id` (`external_id`),
  KEY `idx_ssl_shipment` (`shipment_id`),
  KEY `idx_ssl_store` (`store_external_id`),
  CONSTRAINT `fk_ssl_shipment` FOREIGN KEY (`shipment_id`) REFERENCES `outbound_shipments` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=25 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `shipment_store_lines`
--

LOCK TABLES `shipment_store_lines` WRITE;
/*!40000 ALTER TABLE `shipment_store_lines` DISABLE KEYS */;
INSERT INTO `shipment_store_lines` VALUES (1,'ssl-001-uuid',1,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-DINO-MIX-001',32000,'CTN-MW-0001','DISPATCHED'),(2,'ssl-002-uuid',1,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-DINO-MIX-001',32000,'CTN-MW-0002','DISPATCHED'),(3,'ssl-003-uuid',1,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-DINO-MIX-001',32000,'CTN-MW-0003','DISPATCHED'),(4,'ssl-004-uuid',1,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-DINO-MIX-001',32000,'CTN-MW-0004','DISPATCHED'),(5,'de5afa4c-2c4b-4eb5-bc44-f034a912e04c',2,'str-009-uuid','STR-0201','Burger Bliss Atlanta Midtown','Atlanta','GA','TOY-DINO-MIX-001',26000,'CTN-SE-0001','DISPATCHED'),(6,'d6cc92db-af7b-4b50-a00a-988385fc6f55',2,'str-010-uuid','STR-0202','Burger Bliss Miami Brickell','Miami','FL','TOY-DINO-MIX-001',26000,'CTN-SE-0002','DISPATCHED'),(7,'994efa84-7e16-4052-897b-282b801d40c8',2,'str-011-uuid','STR-0203','Burger Bliss Charlotte','Charlotte','NC','TOY-DINO-MIX-001',26000,'CTN-SE-0003','DISPATCHED'),(8,'0d7cc534-425b-4c4b-bbae-12f45aabb0a1',2,'str-012-uuid','STR-0204','Burger Bliss Nashville','Nashville','TN','TOY-DINO-MIX-001',26000,'CTN-SE-0004','DISPATCHED'),(9,'e4a76936-2c8b-43bf-a639-ca4e439b7a69',3,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-MIXED-001',125,'CTN-STR-0001-97FE51','DISPATCHED'),(10,'4d02a384-872f-48f8-8852-f42d1b3dfe66',3,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-MIXED-001',125,'CTN-STR-0002-661B26','DISPATCHED'),(11,'d26d8a28-56c9-46ea-8512-103ff83be7f7',3,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-MIXED-001',125,'CTN-STR-0003-21A378','DISPATCHED'),(12,'574c6882-ddba-450f-a314-fc6260f1bdf8',3,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-MIXED-001',125,'CTN-STR-0004-846C38','DISPATCHED'),(13,'39254003-7de9-4cbd-95f9-18d93be895fe',4,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-MIXED-001',125,'CTN-STR-0001-457C0B','DISPATCHED'),(14,'1227139d-2f90-4868-9c58-ae835469f603',4,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-MIXED-001',125,'CTN-STR-0002-5E142D','DISPATCHED'),(15,'9d39fd1b-b3b3-4291-96a1-0746aae8c515',4,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-MIXED-001',125,'CTN-STR-0003-94C490','DISPATCHED'),(16,'42bbc789-c613-45d0-863f-aa0222502c21',4,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-MIXED-001',125,'CTN-STR-0004-703EC6','DISPATCHED'),(17,'26e2fbd1-b918-4a7f-81da-2f2c9288d316',5,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-MIXED-001',125,'CTN-STR-0001-CD3AEB','DISPATCHED'),(18,'df97e67e-5d41-447b-b447-cea54fb4393c',5,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-MIXED-001',125,'CTN-STR-0002-9F5439','DISPATCHED'),(19,'f4b3a365-fe1f-46ed-88f1-d7d7367f2c48',5,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-MIXED-001',125,'CTN-STR-0003-0B268C','DISPATCHED'),(20,'3d812574-f1a4-42f3-a5f1-5a236ecdfdc0',5,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-MIXED-001',125,'CTN-STR-0004-9D8426','DISPATCHED'),(21,'201036cd-f243-4328-8e82-4033b2744c56',6,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-MIXED-001',125,'CTN-STR-0001-12EDAE','DISPATCHED'),(22,'b746b21f-6e94-4084-99d6-cfc65c32113f',6,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-MIXED-001',125,'CTN-STR-0002-E64671','DISPATCHED'),(23,'3995f69b-a7ab-4ddb-92b0-a8fac642574b',6,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-MIXED-001',125,'CTN-STR-0003-5E6105','DISPATCHED'),(24,'cfb86dd1-6fc6-4389-bae4-d68566c42b7f',6,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-MIXED-001',125,'CTN-STR-0004-1A9D5F','DISPATCHED');
/*!40000 ALTER TABLE `shipment_store_lines` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-04 10:22:26
