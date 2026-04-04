CREATE DATABASE  IF NOT EXISTS `cs_tms` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cs_tms`;
-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (x86_64)
--
-- Host: localhost    Database: cs_tms
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
-- Table structure for table `delivery_loads`
--

DROP TABLE IF EXISTS `delivery_loads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `delivery_loads` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `load_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. LOAD-2025-001',
  `shipment_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'cs_wms_outbound.outbound_shipments.external_id',
  `shipment_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_order_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_order_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `region_code` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `distribution_dc` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `toy_description` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `total_cartons` int unsigned NOT NULL,
  `total_units` int unsigned NOT NULL,
  `carrier_name` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `pro_number` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Carrier tracking PRO',
  `driver_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `truck_number` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `required_delivery_date` date NOT NULL,
  `pickup_date` date DEFAULT NULL,
  `estimated_delivery_date` date DEFAULT NULL,
  `status` enum('CREATED','ASSIGNED','IN_TRANSIT','COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CREATED',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dl_external_id` (`external_id`),
  UNIQUE KEY `uq_dl_load_number` (`load_number`),
  UNIQUE KEY `uq_dl_shipment` (`shipment_external_id`),
  KEY `idx_dl_status` (`status`),
  KEY `idx_dl_campaign` (`campaign_code`),
  KEY `idx_dl_carrier` (`carrier_name`),
  KEY `idx_dl_shipment` (`shipment_external_id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `delivery_loads`
--

LOCK TABLES `delivery_loads` WRITE;
/*!40000 ALTER TABLE `delivery_loads` DISABLE KEYS */;
INSERT INTO `delivery_loads` VALUES (1,'load-001-uuid','LOAD-2025-001','shp-001-uuid','SHP-2025-001','ord-001-uuid','ORD-2025-001','camp-001-uuid','SUMMER25-TOY','US-MIDWEST','DC-CHICAGO','TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',4,128000,'XPO Logistics','XPO-2025-MW-0441','Mike Johnson','XPO-TRUCK-5521','2025-06-01','2025-05-20','2025-05-30','COMPLETED','All 4 Midwest store deliveries completed. POD confirmed at all locations.','tms.coordinator','2026-03-19 13:11:46','2026-03-19 13:11:46'),(2,'18ead21f-f4e2-48a1-8efa-fbad63acfb80','LOAD-2025-002','shp-002-ext-uuid','SHP-2025-002','ord-003-uuid','ORD-2025-003','camp-001-uuid','SUMMER25-TOY','US-SOUTHEAST','DC-ATLANTA','TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',4,104000,'Old Dominion Freight','OD-2025-SE-8812','Carlos Mendez','OD-TRUCK-8812','2025-06-01','2025-05-28','2025-06-01','COMPLETED','Southeast stores — 4 cartons, Old Dominion PRO OD-2025-SE-8812.','tms.coordinator','2026-03-19 18:12:37','2026-03-19 18:12:37'),(3,'bf530d6e-7ad1-4e78-ae41-b13b4dcce605','LOAD-GUARD','shp-guard-uuid','SHP-GUARD','x','x','x','x','x',NULL,'x','x',1,1,'x','x',NULL,NULL,'2025-06-01',NULL,NULL,'CREATED',NULL,'test','2026-03-19 18:12:37','2026-03-19 18:12:37'),(4,'d92cbd53-1c02-4308-b790-6320487dddad','LOAD-AGENT-001','d655b6b3-0add-4eb6-a9f6-80255fd16b58','SHP-AGENT-002','f00f6978-8f23-4604-bc87-f47520cbbfa1','ORD-AGENT-001','camp-001-uuid','SUMMER25-TOY','US-MIDWEST','DC-CHICAGO','TOY-MIXED-001','Mixed Figures - Spring Promotion',4,500,'FedEx Freight','PRO-AGENT-001','Agent Driver','TRK-AGENT-001','2025-07-20','2025-07-15','2025-07-20','IN_TRANSIT',NULL,'agent','2026-04-03 14:13:33','2026-04-03 14:15:35'),(5,'4bc3f828-bd2e-4e54-9dad-c242c3984c8f','LOAD-AGENT-408A4D9D','d191d9b3-8737-4fc2-a6ba-6eda047c07e7','SHP-AGENT-EF6782CC','027e1cea-0bcf-43ca-8e81-a5d858973bee','ORD-AGENT-3A3CD9FE','2aaff0da-a322-4edb-8684-54b96e27dbc0','SPRING-PROMOTI-E7606','US-MIDWEST','DC-CHICAGO','TOY-MIXED-001','Mixed Figures - Spring Promotion',4,500,'FedEx Freight','PRO-AGENT-6782CC','Agent Driver','TRK-AGENT-001','2026-04-10','2026-04-03','2026-04-08','COMPLETED',NULL,'agent','2026-04-03 17:10:49','2026-04-03 17:11:07'),(6,'2e29fcb4-bbbd-4771-bdc4-ec6b6b5433f0','LOAD-AGENT-319B38D1','8b9ee5c2-515e-49be-afba-ef4943716638','SHP-AGENT-C2CC276F','43fcfa84-ef8e-413c-ae80-404e4ff286fa','ORD-AGENT-5CBA8E9A','9cbc529d-41eb-400b-9150-c6326af95860','SPRING-PROMOTI-179B6','US-MIDWEST','DC-CHICAGO','TOY-MIXED-001','Mixed Figures - Spring Promotion',4,500,'FedEx Freight','PRO-AGENT-CC276F','Agent Driver','TRK-AGENT-001','2026-04-10','2026-04-03','2026-04-08','COMPLETED',NULL,'agent','2026-04-03 17:16:27','2026-04-03 17:16:46');
/*!40000 ALTER TABLE `delivery_loads` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `store_deliveries`
--

DROP TABLE IF EXISTS `store_deliveries`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `store_deliveries` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `delivery_load_id` bigint unsigned NOT NULL,
  `store_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_number` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `store_name` varchar(150) COLLATE utf8mb4_unicode_ci NOT NULL,
  `city` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `state_code` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity` int unsigned NOT NULL,
  `carton_label` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `delivered_quantity` int unsigned DEFAULT NULL,
  `pod_signatory` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Name of store manager who signed',
  `pod_notes` text COLLATE utf8mb4_unicode_ci,
  `delivered_at` datetime DEFAULT NULL,
  `pod_confirmed_at` datetime DEFAULT NULL,
  `status` enum('PENDING','OUT_FOR_DELIVERY','DELIVERED','POD_CONFIRMED','FAILED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sd_external_id` (`external_id`),
  KEY `idx_sd_load` (`delivery_load_id`),
  KEY `idx_sd_store` (`store_external_id`),
  KEY `idx_sd_status` (`status`),
  CONSTRAINT `fk_sd_load` FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=22 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `store_deliveries`
--

LOCK TABLES `store_deliveries` WRITE;
/*!40000 ALTER TABLE `store_deliveries` DISABLE KEYS */;
INSERT INTO `store_deliveries` VALUES (1,'sd-001-uuid',1,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-DINO-MIX-001',32000,'CTN-MW-0001',32000,'Sarah Chen','All 32,000 units received in good condition. Signed at dock.','2025-05-28 10:30:00','2025-05-28 11:00:00','POD_CONFIRMED'),(2,'sd-002-uuid',1,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-DINO-MIX-001',32000,'CTN-MW-0002',32000,'Tom Richards','Full carton received. Stored in back stockroom.','2025-05-28 13:15:00','2025-05-28 13:45:00','POD_CONFIRMED'),(3,'sd-003-uuid',1,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-DINO-MIX-001',32000,'CTN-MW-0003',32000,'Jessica Park','Delivered to store manager. No damage reported.','2025-05-29 09:00:00','2025-05-29 09:30:00','POD_CONFIRMED'),(4,'sd-004-uuid',1,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-DINO-MIX-001',32000,'CTN-MW-0004',32000,'David Torres','Final delivery on this load. All 32,000 units confirmed.','2025-05-30 14:00:00','2025-05-30 14:30:00','POD_CONFIRMED'),(5,'49c3fc19-c97a-4e78-b202-104dfdb7621e',2,'str-009-uuid','STR-0201','Burger Bliss Atlanta Midtown','Atlanta','GA','TOY-DINO-MIX-001',26000,'CTN-SE-0001',26000,'Maria Gonzalez','Full carton received at Atlanta. 26,000 dino toys. Signed at receiving dock.','2025-05-29 15:00:00','2026-03-19 18:12:37','POD_CONFIRMED'),(6,'1be3f572-baa0-4b88-b1bf-68cffaa549f6',2,'str-010-uuid','STR-0202','Burger Bliss Miami Brickell','Miami','FL','TOY-DINO-MIX-001',26000,'CTN-SE-0002',26000,'James Williams','All 26,000 units received in good condition. Stored in back room.','2025-05-29 19:30:00','2026-03-19 18:12:37','POD_CONFIRMED'),(7,'3056330a-dcd7-4cee-8563-5d220a1cb33f',2,'str-011-uuid','STR-0203','Burger Bliss Charlotte','Charlotte','NC','TOY-DINO-MIX-001',26000,'CTN-SE-0003',26000,'Angela Davis','Delivery accepted. No damage. Carton label CTN-SE-0003 scanned.','2025-05-30 14:15:00','2026-03-19 18:12:37','POD_CONFIRMED'),(8,'9da9c9c1-0b9c-43e3-a7c0-84eeee8b61bb',2,'str-012-uuid','STR-0204','Burger Bliss Nashville','Nashville','TN','TOY-DINO-MIX-001',26000,'CTN-SE-0004',26000,'Robert Kim','Final delivery on this load. All 26,000 Nashville units confirmed.','2025-05-30 20:00:00','2026-03-19 18:12:37','POD_CONFIRMED'),(9,'076ce664-0a7f-47ef-af58-fd5867a31609',3,'x','x','x',NULL,NULL,'x',1,NULL,NULL,NULL,NULL,NULL,NULL,'PENDING'),(10,'096ffd37-4723-469d-a860-bb39e6a71fb6',4,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0001','POD confirmed by agentic AI control tower','2025-07-20 15:00:00','2026-04-03 14:16:55','POD_CONFIRMED'),(11,'e188e1d4-8b22-425e-bc5f-45905d8ed03d',4,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-MIXED-001',125,NULL,NULL,NULL,NULL,NULL,NULL,'OUT_FOR_DELIVERY'),(12,'0a1bd3f8-fda8-4215-bd9d-ee8eec2ea0cd',4,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-MIXED-001',125,NULL,NULL,NULL,NULL,NULL,NULL,'OUT_FOR_DELIVERY'),(13,'1ec7d364-f3f6-4c87-803c-336cbe070b78',4,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-MIXED-001',125,NULL,NULL,NULL,NULL,NULL,NULL,'OUT_FOR_DELIVERY'),(14,'538049d8-bdd4-41b0-a271-9638f6636e4d',5,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0001','POD confirmed by agentic AI control tower','2026-04-03 17:11:06','2026-04-03 17:11:07','POD_CONFIRMED'),(15,'619b07f4-1eac-4a70-b7e6-e12c4f64e1e8',5,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0002','POD confirmed by agentic AI control tower','2026-04-03 17:11:07','2026-04-03 17:11:07','POD_CONFIRMED'),(16,'610fa033-9022-4353-b95c-423954d3f1e2',5,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0003','POD confirmed by agentic AI control tower','2026-04-03 17:11:07','2026-04-03 17:11:07','POD_CONFIRMED'),(17,'45e0617b-f556-40c1-b3bd-4ea4f79218db',5,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0004','POD confirmed by agentic AI control tower','2026-04-03 17:11:07','2026-04-03 17:11:07','POD_CONFIRMED'),(18,'468768c4-9103-499f-ae3a-2bcfdeef4e71',6,'str-001-uuid','STR-0001','Burger Bliss Chicago Downtown','Chicago','IL','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0001','POD confirmed by agentic AI control tower','2026-04-03 17:16:45','2026-04-03 17:16:46','POD_CONFIRMED'),(19,'e4ecba3d-93ee-4ac0-aeef-5695e069b367',6,'str-002-uuid','STR-0002','Burger Bliss Naperville','Naperville','IL','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0002','POD confirmed by agentic AI control tower','2026-04-03 17:16:45','2026-04-03 17:16:46','POD_CONFIRMED'),(20,'1a962459-d7d0-4b34-9960-5e971ed01ea0',6,'str-003-uuid','STR-0003','Burger Bliss Milwaukee','Milwaukee','WI','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0003','POD confirmed by agentic AI control tower','2026-04-03 17:16:45','2026-04-03 17:16:46','POD_CONFIRMED'),(21,'f6e5d87a-2a0a-484f-ab84-231f3051a193',6,'str-004-uuid','STR-0004','Burger Bliss Indianapolis','Indianapolis','IN','TOY-MIXED-001',125,NULL,125,'Store Manager STR-0004','POD confirmed by agentic AI control tower','2026-04-03 17:16:45','2026-04-03 17:16:46','POD_CONFIRMED');
/*!40000 ALTER TABLE `store_deliveries` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tms_events`
--

DROP TABLE IF EXISTS `tms_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `tms_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `delivery_load_id` bigint unsigned NOT NULL,
  `event_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `previous_status` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `triggered_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rabbitmq_published` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_tmse_load` (`delivery_load_id`),
  CONSTRAINT `fk_tmse_load` FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=21 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tms_events`
--

LOCK TABLES `tms_events` WRITE;
/*!40000 ALTER TABLE `tms_events` DISABLE KEYS */;
INSERT INTO `tms_events` VALUES (1,1,'LOAD_CREATED',NULL,'CREATED','Load created from WMS shipment dispatch event.','tms.coordinator','2026-03-19 13:11:46',1),(2,1,'LOAD_ASSIGNED','CREATED','ASSIGNED','Assigned to driver Mike Johnson, truck XPO-TRUCK-5521.','tms.coordinator','2026-03-19 13:11:46',0),(3,1,'LOAD_IN_TRANSIT','ASSIGNED','IN_TRANSIT','Driver picked up load from DC-CHICAGO. PRO XPO-2025-MW-0441.','xpo.carrier.api','2026-03-19 13:11:46',1),(4,1,'LOAD_COMPLETED','IN_TRANSIT','COMPLETED','All 4 Midwest stores delivered and POD confirmed.','tms.coordinator','2026-03-19 13:11:46',1),(5,2,'LOAD_CREATED',NULL,'CREATED','Load created from WMS shipment SHP-2025-002','tms.coordinator','2026-03-19 18:12:37',1),(6,2,'LOAD_ASSIGNED','CREATED','ASSIGNED','Driver: Carlos Mendez Truck: OD-TRUCK-8812','tms.coordinator','2026-03-19 18:12:37',1),(7,2,'LOAD_IN_TRANSIT','ASSIGNED','IN_TRANSIT','PRO: OD-2025-SE-8812. Driver Carlos Mendez picked up load from DC-ATLANTA. PRO OD-2025-SE-8812 active.','od.carrier.api','2026-03-19 18:12:37',1),(8,2,'LOAD_COMPLETED','IN_TRANSIT','COMPLETED','All 4 stores POD confirmed. Total delivered: 104000','tms.coordinator','2026-03-19 18:12:37',1),(9,3,'LOAD_CREATED',NULL,'CREATED','Load created from WMS shipment SHP-GUARD','test','2026-03-19 18:12:37',1),(10,4,'LOAD_CREATED',NULL,'CREATED','Load created from WMS shipment SHP-AGENT-002','agent','2026-04-03 14:13:33',1),(11,4,'LOAD_ASSIGNED','CREATED','ASSIGNED','Driver: Agent Driver Truck: TRK-AGENT-001','tms.coordinator','2026-04-03 14:15:00',1),(12,4,'LOAD_IN_TRANSIT','ASSIGNED','IN_TRANSIT','PRO: PRO-AGENT-001. null','agent','2026-04-03 14:15:35',1),(13,5,'LOAD_CREATED',NULL,'CREATED','Load created from WMS shipment SHP-AGENT-EF6782CC','agent','2026-04-03 17:10:49',1),(14,5,'LOAD_ASSIGNED','CREATED','ASSIGNED','Driver: Agent Driver Truck: TRK-AGENT-001','tms.coordinator','2026-04-03 17:10:49',1),(15,5,'LOAD_IN_TRANSIT','ASSIGNED','IN_TRANSIT','PRO: PRO-AGENT-6782CC. null','agent','2026-04-03 17:10:49',1),(16,5,'LOAD_COMPLETED','IN_TRANSIT','COMPLETED','All 4 stores POD confirmed. Total delivered: 500','tms.coordinator','2026-04-03 17:11:07',1),(17,6,'LOAD_CREATED',NULL,'CREATED','Load created from WMS shipment SHP-AGENT-C2CC276F','agent','2026-04-03 17:16:27',1),(18,6,'LOAD_ASSIGNED','CREATED','ASSIGNED','Driver: Agent Driver Truck: TRK-AGENT-001','tms.coordinator','2026-04-03 17:16:27',1),(19,6,'LOAD_IN_TRANSIT','ASSIGNED','IN_TRANSIT','PRO: PRO-AGENT-CC276F. null','agent','2026-04-03 17:16:27',1),(20,6,'LOAD_COMPLETED','IN_TRANSIT','COMPLETED','All 4 stores POD confirmed. Total delivered: 500','tms.coordinator','2026-04-03 17:16:46',1);
/*!40000 ALTER TABLE `tms_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `transit_events`
--

DROP TABLE IF EXISTS `transit_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `transit_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `delivery_load_id` bigint unsigned NOT NULL,
  `event_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. PICKUP, IN_TRANSIT, EXCEPTION, DELIVERED',
  `event_description` varchar(255) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `location` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'City, State or facility name',
  `event_at` datetime NOT NULL,
  `recorded_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `source` varchar(50) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'CARRIER_API, MANUAL, SYSTEM',
  PRIMARY KEY (`id`),
  KEY `idx_te_load` (`delivery_load_id`),
  KEY `idx_te_event_at` (`event_at`),
  CONSTRAINT `fk_te_load` FOREIGN KEY (`delivery_load_id`) REFERENCES `delivery_loads` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=13 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `transit_events`
--

LOCK TABLES `transit_events` WRITE;
/*!40000 ALTER TABLE `transit_events` DISABLE KEYS */;
INSERT INTO `transit_events` VALUES (1,1,'PICKUP','Shipment picked up from DC-CHICAGO.','Chicago, IL','2025-05-20 14:00:00','2026-03-19 13:11:46','CARRIER_API'),(2,1,'IN_TRANSIT','En route to Midwest stores.','Gary, IN','2025-05-20 16:30:00','2026-03-19 13:11:46','CARRIER_API'),(3,1,'OUT_FOR_DELIVERY','Driver beginning Chicago stops.','Chicago, IL','2025-05-28 08:00:00','2026-03-19 13:11:46','CARRIER_API'),(4,1,'DELIVERED','All Midwest stops completed.','Indianapolis, IN','2025-05-30 14:30:00','2026-03-19 13:11:46','CARRIER_API'),(5,2,'PICKUP','Load picked up from DC-ATLANTA.','Atlanta, GA','2026-03-19 18:12:37','2026-03-19 18:12:37','CARRIER_API'),(6,2,'IN_TRANSIT','En route to Southeast stores.','Macon, GA','2026-03-19 18:12:37','2026-03-19 18:12:37','CARRIER_API'),(7,5,'DEPARTED_DC','Departed distribution center','DC-CHICAGO','2026-04-03 17:10:48','2026-04-03 17:10:49','agent'),(8,5,'IN_TRANSIT','Load in transit to region','En route','2026-04-03 17:10:48','2026-04-03 17:10:49','agent'),(9,5,'OUT_FOR_DELIVERY','Out for delivery to stores','US-MIDWEST','2026-04-03 17:10:48','2026-04-03 17:10:49','agent'),(10,6,'DEPARTED_DC','Departed distribution center','DC-CHICAGO','2026-04-03 17:16:26','2026-04-03 17:16:27','agent'),(11,6,'IN_TRANSIT','Load in transit to region','En route','2026-04-03 17:16:26','2026-04-03 17:16:27','agent'),(12,6,'OUT_FOR_DELIVERY','Out for delivery to stores','US-MIDWEST','2026-04-03 17:16:26','2026-04-03 17:16:27','agent');
/*!40000 ALTER TABLE `transit_events` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-04 10:20:35
