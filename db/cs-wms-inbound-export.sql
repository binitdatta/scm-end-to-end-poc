CREATE DATABASE  IF NOT EXISTS `cs_wms_inbound` /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci */ /*!80016 DEFAULT ENCRYPTION='N' */;
USE `cs_wms_inbound`;
-- MySQL dump 10.13  Distrib 8.0.45, for macos15 (x86_64)
--
-- Host: localhost    Database: cs_wms_inbound
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
-- Table structure for table `advance_shipment_notices`
--

DROP TABLE IF EXISTS `advance_shipment_notices`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `advance_shipment_notices` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `asn_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. ASN-2025-001',
  `po_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'cs_procurement.purchase_orders.external_id',
  `po_number` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `vendor_country` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Internal toy SKU',
  `toy_description` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `expected_quantity` int unsigned NOT NULL,
  `unit_of_measure` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PIECES',
  `carrier_name` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `tracking_number` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Vessel / AWB / PRO number',
  `origin_port` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `destination_port` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `incoterms` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `estimated_arrival_date` date DEFAULT NULL,
  `actual_arrival_date` date DEFAULT NULL,
  `dock_appointment_date` datetime DEFAULT NULL,
  `dock_door` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. DOOR-05',
  `status` enum('CREATED','SCHEDULED','IN_TRANSIT','ARRIVED','RECEIVING','RECEIVED','PUTAWAY_IN_PROGRESS','PUTAWAY_COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'CREATED',
  `notes` text COLLATE utf8mb4_unicode_ci,
  `created_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_asn_external_id` (`external_id`),
  UNIQUE KEY `uq_asn_number` (`asn_number`),
  UNIQUE KEY `uq_asn_po` (`po_external_id`) COMMENT 'One ASN per PO',
  KEY `idx_asn_status` (`status`),
  KEY `idx_asn_po` (`po_external_id`),
  KEY `idx_asn_campaign` (`campaign_external_id`),
  KEY `idx_asn_vendor` (`vendor_external_id`),
  KEY `idx_asn_arrival` (`estimated_arrival_date`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `advance_shipment_notices`
--

LOCK TABLES `advance_shipment_notices` WRITE;
/*!40000 ALTER TABLE `advance_shipment_notices` DISABLE KEYS */;
INSERT INTO `advance_shipment_notices` VALUES (1,'asn-001-uuid','ASN-2025-001','po-001-uuid','PO-2025-001','camp-001-uuid','SUMMER25-TOY','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','TOY-DINO-MIX-001','Mystery Dinosaur Figures — Summer 2025 Kids Meal Toy Surprise',500000,'PIECES','OOCL Shipping','OOCL-VIET-20250401-8821','Port of Ho Chi Minh City','Port of Los Angeles','FOB','2025-05-05','2025-05-05','2025-05-06 08:00:00','DOOR-05','PUTAWAY_COMPLETED','Vessel OOCL EUROPE arrived on schedule. 500k cartons offloaded. Awaiting dock receiving.','wms.inbound.coordinator','2026-03-18 14:04:15','2026-03-18 14:04:15'),(2,'asn-002-uuid','ASN-2025-002','po-002-uuid','PO-2025-002','camp-002-uuid','HOLIDAY25-TOY','vnd-001-uuid','VND-CN-001','Shenzhen BrightToy Manufacturing Co.','CHINA','TOY-HOLIDAY-MIX-001','Holiday 2025 Collectible Figurines — 6 Character Series',1200000,'PIECES','COSCO Shipping','COSCO-CN-20250915-4492','Port of Shenzhen','Port of Long Beach','CIF','2025-10-05',NULL,'2025-10-06 07:00:00','DOOR-03','IN_TRANSIT','Vessel departs Shenzhen Sept 15. ETA Long Beach Oct 5. Dock slot confirmed.','wms.inbound.coordinator','2026-03-18 14:04:15','2026-03-18 19:07:14'),(4,'57b0fbbb-ae84-41d1-bb35-4b4fb0228360','ASN-2025-003','po-003-test-uuid','PO-2025-003','camp-001-uuid','SUMMER25-TOY','vnd-004-uuid','VND-TH-001','Bangkok Fun Factory Co. Ltd.','THAILAND','TOY-SPACE-MIX-001','Space Explorer Figure Series — Summer 2025',250000,'PIECES','MSC Shipping','MSC-THAI-20250420-7743','Laem Chabang Port, Thailand','Port of Los Angeles','FOB','2025-05-05','2025-05-05','2025-05-06 13:00:00','DOOR-07','PUTAWAY_COMPLETED','MSC AURORA vessel. 250k space explorer figures from Bangkok Fun Factory.','wms.inbound.coordinator','2026-03-18 19:07:14','2026-03-18 19:07:14'),(5,'41879b32-4da6-4da6-bdb3-fb78bb796867','ASN-AGENT-001','d7344e34-1d7a-4bf2-8ce7-7067b0b69df7','PO-2025-004','camp-001-uuid','SUMMER25-TOY','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','TOY-MIXED-001','Mixed Figures - Spring Promotion',500,'PIECES','FedEx Freight','FX-AGENT-001','Port of Ho Chi Minh City','Port of Los Angeles','FOB','2025-07-10','2025-07-10','2025-07-11 13:00:00','DOOR-01','PUTAWAY_COMPLETED',NULL,'agent','2026-04-03 13:43:41','2026-04-03 13:49:29'),(6,'d76a939e-6743-46f5-bffc-c7c50d7cbb89','ASN-AGENT-4A2A6AA2','cb129ede-4eed-4187-b676-60b23e29d787','PO-AGENT-D9B2FED5','44e362cb-3a5a-4230-b0e6-00d5af6f7295','SPRING-PROMOTI-45F71','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','TOY-MIXED-001','Mixed Figures — Agent Inbound',500,'PIECES','FedEx Freight','FX-AGENT-5E3F77','Port of Ho Chi Minh City','Port of Los Angeles','FOB','2026-05-03',NULL,NULL,NULL,'CREATED',NULL,'agent','2026-04-03 16:58:04','2026-04-03 16:58:04'),(7,'88d7fe60-b06b-4228-9233-207484db66b8','ASN-AGENT-9EF05156','c0353401-91db-42a3-8cd4-444e16e02e6a','PO-AGENT-8EFB77B9','2aaff0da-a322-4edb-8684-54b96e27dbc0','SPRING-PROMOTI-E7606','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','TOY-MIXED-001','Mixed Figures — Agent Inbound',500,'PIECES','FedEx Freight','FX-AGENT-520F72','Port of Ho Chi Minh City','Port of Los Angeles','FOB','2026-05-03','2026-04-03','2026-04-04 17:10:32','DOOR-01','PUTAWAY_COMPLETED',NULL,'agent','2026-04-03 17:10:32','2026-04-03 17:10:32'),(8,'a5316c18-59e2-46b6-97b7-fb3975ffb063','ASN-AGENT-307B0F99','0279711c-081d-4c7c-80be-6e69391408c5','PO-AGENT-DDE4FB19','9cbc529d-41eb-400b-9150-c6326af95860','SPRING-PROMOTI-179B6','vnd-002-uuid','VND-VN-001','Ho Chi Minh Playthings Ltd.','VIETNAM','TOY-MIXED-001','Mixed Figures — Agent Inbound',500,'PIECES','FedEx Freight','FX-AGENT-D23749','Port of Ho Chi Minh City','Port of Los Angeles','FOB','2026-05-03','2026-04-03','2026-04-04 17:16:08','DOOR-01','PUTAWAY_COMPLETED',NULL,'agent','2026-04-03 17:16:09','2026-04-03 17:16:09');
/*!40000 ALTER TABLE `advance_shipment_notices` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `asn_events`
--

DROP TABLE IF EXISTS `asn_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `asn_events` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `asn_id` bigint unsigned NOT NULL,
  `event_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `previous_status` varchar(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `new_status` varchar(30) COLLATE utf8mb4_unicode_ci NOT NULL,
  `notes` text COLLATE utf8mb4_unicode_ci,
  `triggered_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `rabbitmq_published` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`id`),
  KEY `idx_ae_asn_id` (`asn_id`),
  CONSTRAINT `fk_ae_asn` FOREIGN KEY (`asn_id`) REFERENCES `advance_shipment_notices` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=40 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `asn_events`
--

LOCK TABLES `asn_events` WRITE;
/*!40000 ALTER TABLE `asn_events` DISABLE KEYS */;
INSERT INTO `asn_events` VALUES (1,1,'ASN_CREATED',NULL,'CREATED','ASN created from PO-2025-001 ready-to-ship event.','wms.inbound.coordinator','2026-03-18 14:04:15',1),(2,1,'DOCK_SCHEDULED','CREATED','SCHEDULED','Dock appointment confirmed: DOOR-05, 2025-05-06 08:00.','wms.inbound.coordinator','2026-03-18 14:04:15',1),(3,1,'VESSEL_ARRIVED','SCHEDULED','ARRIVED','OOCL EUROPE docked at Port of Los Angeles.','wms.inbound.coordinator','2026-03-18 14:04:15',1),(4,1,'RECEIVING_COMPLETED','ARRIVED','RECEIVED','499,800 units accepted. 200 damaged/rejected. QC passed.','warehouse.receiver.01','2026-03-18 14:04:15',1),(5,1,'PUTAWAY_COMPLETED','RECEIVED','PUTAWAY_COMPLETED','499,800 units stowed across ZONE-A BIN-A-01-001 and BIN-A-02-001.','warehouse.receiver.01','2026-03-18 14:04:15',1),(6,2,'ASN_CREATED',NULL,'CREATED','ASN created from PO-2025-002 ready-to-ship event.','wms.inbound.coordinator','2026-03-18 14:04:15',1),(7,2,'DOCK_SCHEDULED','CREATED','SCHEDULED','Dock appointment confirmed: DOOR-03, 2025-10-06 07:00.','wms.inbound.coordinator','2026-03-18 14:04:15',1),(13,2,'IN_TRANSIT','SCHEDULED','IN_TRANSIT','COSCO vessel departed Shenzhen. ETA Long Beach Oct 5.','cosco.tracking','2026-03-18 19:04:51',0),(14,4,'ASN_CREATED',NULL,'CREATED','ASN created','wms.inbound.coordinator','2026-03-18 19:07:14',0),(15,4,'DOCK_SCHEDULED','CREATED','SCHEDULED','Dock DOOR-07 booked for 2025-05-06T08:00','wms.inbound.coordinator','2026-03-18 19:07:14',1),(16,4,'IN_TRANSIT','SCHEDULED','IN_TRANSIT','Vessel MSC AURORA departed Laem Chabang. ETA 15 days.','msc.tracking.api','2026-03-18 19:07:14',0),(17,4,'SHIPMENT_ARRIVED','IN_TRANSIT','ARRIVED','MSC AURORA docked at Port of Los Angeles, Berth 302.','wms.inbound.coordinator','2026-03-18 19:07:14',1),(18,4,'RECEIVING_COMPLETED','ARRIVED','RECEIVED','Accepted=249900 Damaged=50 Variance=-50','warehouse.receiver.02','2026-03-18 19:07:14',1),(19,4,'PUTAWAY_COMPLETED','RECEIVED','PUTAWAY_COMPLETED','Total putaway=249950 across 2 bins','forklift.op.03','2026-03-18 19:07:14',1),(20,2,'IN_TRANSIT','SCHEDULED','IN_TRANSIT','COSCO vessel departed Shenzhen. ETA Long Beach Oct 5.','cosco.tracking','2026-03-18 19:07:14',0),(21,5,'ASN_CREATED',NULL,'CREATED','ASN created','agent','2026-04-03 13:43:41',0),(22,5,'DOCK_SCHEDULED','CREATED','SCHEDULED','Dock DOOR-01 booked for 2025-07-11T08:00','agent','2026-04-03 13:45:09',1),(23,5,'IN_TRANSIT','SCHEDULED','IN_TRANSIT',NULL,'agent','2026-04-03 13:45:50',0),(24,5,'SHIPMENT_ARRIVED','IN_TRANSIT','ARRIVED',NULL,'agent','2026-04-03 13:46:27',1),(25,5,'RECEIVING_COMPLETED','ARRIVED','RECEIVED','Accepted=500 Damaged=0 Variance=0','agent','2026-04-03 13:47:13',1),(26,5,'PUTAWAY_COMPLETED','RECEIVED','PUTAWAY_COMPLETED','Total putaway=500 across 1 bins','agent','2026-04-03 13:49:29',1),(27,6,'ASN_CREATED',NULL,'CREATED','ASN created','agent','2026-04-03 16:58:04',0),(28,7,'ASN_CREATED',NULL,'CREATED','ASN created','agent','2026-04-03 17:10:32',0),(29,7,'DOCK_SCHEDULED','CREATED','SCHEDULED','Dock DOOR-01 booked for 2026-04-04T12:10:32','agent','2026-04-03 17:10:32',1),(30,7,'IN_TRANSIT','SCHEDULED','IN_TRANSIT',NULL,'agent','2026-04-03 17:10:32',0),(31,7,'SHIPMENT_ARRIVED','IN_TRANSIT','ARRIVED',NULL,'agent','2026-04-03 17:10:32',1),(32,7,'RECEIVING_COMPLETED','ARRIVED','RECEIVED','Accepted=500 Damaged=0 Variance=0','agent','2026-04-03 17:10:32',1),(33,7,'PUTAWAY_COMPLETED','RECEIVED','PUTAWAY_COMPLETED','Total putaway=500 across 1 bins','agent','2026-04-03 17:10:32',1),(34,8,'ASN_CREATED',NULL,'CREATED','ASN created','agent','2026-04-03 17:16:09',0),(35,8,'DOCK_SCHEDULED','CREATED','SCHEDULED','Dock DOOR-01 booked for 2026-04-04T12:16:08','agent','2026-04-03 17:16:09',1),(36,8,'IN_TRANSIT','SCHEDULED','IN_TRANSIT',NULL,'agent','2026-04-03 17:16:09',0),(37,8,'SHIPMENT_ARRIVED','IN_TRANSIT','ARRIVED',NULL,'agent','2026-04-03 17:16:09',1),(38,8,'RECEIVING_COMPLETED','ARRIVED','RECEIVED','Accepted=500 Damaged=0 Variance=0','agent','2026-04-03 17:16:09',1),(39,8,'PUTAWAY_COMPLETED','RECEIVED','PUTAWAY_COMPLETED','Total putaway=500 across 1 bins','agent','2026-04-03 17:16:09',1);
/*!40000 ALTER TABLE `asn_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `inventory_locations`
--

DROP TABLE IF EXISTS `inventory_locations`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inventory_locations` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `campaign_code` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `warehouse_zone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `warehouse_aisle` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `warehouse_bin` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_on_hand` int unsigned NOT NULL DEFAULT '0',
  `quantity_reserved` int unsigned NOT NULL DEFAULT '0',
  `quantity_available` int unsigned NOT NULL DEFAULT '0',
  `last_receipt_date` date DEFAULT NULL,
  `last_updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_inv_sku_bin` (`sku`,`warehouse_bin`),
  KEY `idx_inv_sku` (`sku`),
  KEY `idx_inv_campaign` (`campaign_code`),
  KEY `idx_inv_zone` (`warehouse_zone`)
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `inventory_locations`
--

LOCK TABLES `inventory_locations` WRITE;
/*!40000 ALTER TABLE `inventory_locations` DISABLE KEYS */;
INSERT INTO `inventory_locations` VALUES (1,'TOY-DINO-MIX-001','SUMMER25-TOY','ZONE-A','A-01','BIN-A-01-001',250000,0,250000,'2025-05-06','2026-03-18 14:04:15'),(2,'TOY-DINO-MIX-001','SUMMER25-TOY','ZONE-A','A-02','BIN-A-02-001',249800,0,249800,'2025-05-06','2026-03-18 14:04:15'),(3,'TOY-SPACE-MIX-001','SUMMER25-TOY','ZONE-B','B-01','BIN-B-01-001',125000,0,125000,'2026-03-18','2026-03-18 19:07:14'),(4,'TOY-SPACE-MIX-001','SUMMER25-TOY','ZONE-B','B-02','BIN-B-02-001',124950,0,124950,'2026-03-18','2026-03-18 19:07:14'),(5,'TOY-MIXED-001','SUMMER25-TOY','ZONE-A','AISLE-3','BIN-001',1500,0,1500,'2026-04-03','2026-04-03 17:16:09');
/*!40000 ALTER TABLE `inventory_locations` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `putaway_tasks`
--

DROP TABLE IF EXISTS `putaway_tasks`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `putaway_tasks` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `asn_id` bigint unsigned NOT NULL,
  `sku` varchar(50) COLLATE utf8mb4_unicode_ci NOT NULL,
  `quantity_to_putaway` int unsigned NOT NULL,
  `quantity_putaway` int unsigned NOT NULL DEFAULT '0',
  `warehouse_zone` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'e.g. ZONE-A, ZONE-B',
  `warehouse_aisle` varchar(10) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. A-12',
  `warehouse_bin` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'e.g. BIN-A-12-003',
  `status` enum('PENDING','IN_PROGRESS','COMPLETED','CANCELLED') COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT 'PENDING',
  `assigned_to` varchar(100) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `started_at` datetime DEFAULT NULL,
  `completed_at` datetime DEFAULT NULL,
  `created_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `updated_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_putaway_ext_id` (`external_id`),
  KEY `idx_putaway_asn_id` (`asn_id`),
  KEY `idx_putaway_status` (`status`),
  KEY `idx_putaway_sku` (`sku`),
  CONSTRAINT `fk_putaway_asn` FOREIGN KEY (`asn_id`) REFERENCES `advance_shipment_notices` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=9 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `putaway_tasks`
--

LOCK TABLES `putaway_tasks` WRITE;
/*!40000 ALTER TABLE `putaway_tasks` DISABLE KEYS */;
INSERT INTO `putaway_tasks` VALUES (1,'pt-001-uuid',1,'TOY-DINO-MIX-001',250000,250000,'ZONE-A','A-01','BIN-A-01-001','COMPLETED','forklift.op.01','2025-05-06 11:00:00','2025-05-06 14:00:00','2026-03-18 14:04:15','2026-03-18 14:04:15'),(2,'pt-002-uuid',1,'TOY-DINO-MIX-001',249800,249800,'ZONE-A','A-02','BIN-A-02-001','COMPLETED','forklift.op.02','2025-05-06 11:00:00','2025-05-06 15:30:00','2026-03-18 14:04:15','2026-03-18 14:04:15'),(4,'a1a3e243-e822-4550-97d0-3b4ee3a2ae68',4,'TOY-SPACE-MIX-001',125000,125000,'ZONE-B','B-01','BIN-B-01-001','COMPLETED','forklift.op.03','2026-03-18 19:07:14','2026-03-18 19:07:14','2026-03-18 19:07:14','2026-03-18 19:07:14'),(5,'1b39cbb1-1a12-4843-b273-039ad44b5dd4',4,'TOY-SPACE-MIX-001',124950,124950,'ZONE-B','B-02','BIN-B-02-001','COMPLETED','forklift.op.03','2026-03-18 19:07:14','2026-03-18 19:07:14','2026-03-18 19:07:14','2026-03-18 19:07:14'),(6,'abe0c442-0010-4238-8538-3199e3b3af8b',5,'TOY-MIXED-001',500,500,'ZONE-A','AISLE-3','BIN-001','COMPLETED','agent','2026-04-03 13:49:29','2026-04-03 13:49:29','2026-04-03 13:49:29','2026-04-03 13:49:29'),(7,'1112d18f-4f67-49f5-9161-8a350d2b8021',7,'TOY-MIXED-001',500,500,'ZONE-A','AISLE-3','BIN-001','COMPLETED','agent','2026-04-03 17:10:32','2026-04-03 17:10:32','2026-04-03 17:10:32','2026-04-03 17:10:32'),(8,'fabc46ad-341e-4072-9910-91fc7da2eb6d',8,'TOY-MIXED-001',500,500,'ZONE-A','AISLE-3','BIN-001','COMPLETED','agent','2026-04-03 17:16:09','2026-04-03 17:16:09','2026-04-03 17:16:09','2026-04-03 17:16:09');
/*!40000 ALTER TABLE `putaway_tasks` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `receiving_records`
--

DROP TABLE IF EXISTS `receiving_records`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `receiving_records` (
  `id` bigint unsigned NOT NULL AUTO_INCREMENT,
  `external_id` varchar(64) COLLATE utf8mb4_unicode_ci NOT NULL,
  `asn_id` bigint unsigned NOT NULL,
  `received_quantity` int unsigned NOT NULL,
  `damaged_quantity` int unsigned NOT NULL DEFAULT '0',
  `rejected_quantity` int unsigned NOT NULL DEFAULT '0',
  `accepted_quantity` int unsigned NOT NULL,
  `variance_quantity` int DEFAULT NULL COMMENT 'received - expected (can be negative)',
  `received_by` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  `received_at` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `qc_passed` tinyint(1) NOT NULL DEFAULT '0',
  `qc_notes` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_rr_external_id` (`external_id`),
  UNIQUE KEY `uq_rr_asn` (`asn_id`) COMMENT 'One receiving record per ASN',
  KEY `idx_rr_asn_id` (`asn_id`),
  CONSTRAINT `fk_rr_asn` FOREIGN KEY (`asn_id`) REFERENCES `advance_shipment_notices` (`id`)
) ENGINE=InnoDB AUTO_INCREMENT=7 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `receiving_records`
--

LOCK TABLES `receiving_records` WRITE;
/*!40000 ALTER TABLE `receiving_records` DISABLE KEYS */;
INSERT INTO `receiving_records` VALUES (1,'rr-001-uuid',1,499800,200,0,499800,-200,'warehouse.receiver.01','2025-05-06 10:30:00',1,'Minor damage on 200 units from moisture. All rejected units documented. 499,800 accepted. QC PASSED.'),(3,'10b73980-84c9-48de-be33-224a7629a208',4,249950,50,0,249900,-50,'warehouse.receiver.02','2026-03-18 19:07:14',1,'50 units with minor paint defects isolated. 249,950 units accepted. All safety certifications verified. QC PASSED.'),(4,'83a029c3-b91c-4133-8f64-4635cffa6a10',5,500,0,0,500,0,'agent','2026-04-03 13:47:13',1,NULL),(5,'6efea5fc-54fe-4948-8175-521104f32b3c',7,500,0,0,500,0,'agent','2026-04-03 17:10:32',1,NULL),(6,'f87922b6-50bc-4d6c-ac38-f2d756c468cd',8,500,0,0,500,0,'agent','2026-04-03 17:16:09',1,NULL);
/*!40000 ALTER TABLE `receiving_records` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-04-04 10:21:50
