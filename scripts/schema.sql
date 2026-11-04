-- The app's database structure only (tables and views, no rows), for CI and
-- for building an empty database. The data itself comes from
-- pg_export/mysql_dump.sql (not in git); the Better Auth tables are in
-- scripts/better-auth-schema.sql, so load both:
--   mysql -u <user> -p <database> < scripts/schema.sql
--   mysql -u <user> -p <database> < scripts/better-auth-schema.sql
-- Regenerate after any schema change, from a database that has the change:
--   mysqldump --no-data --skip-comments --set-gtid-purged=OFF --no-tablespaces \
--     --ignore-table=<db>.user --ignore-table=<db>.session \
--     --ignore-table=<db>.account --ignore-table=<db>.verification <db>
-- then delete the DEFINER=... clauses (so views belong to whoever loads this)
-- and the AUTO_INCREMENT=<n> counters.


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!50503 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;
DROP TABLE IF EXISTS `_check_errors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `_check_errors` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `coin_type_code` longtext COLLATE utf8mb4_0900_bin NOT NULL,
  `failed_field` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `raw_value` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `check_errors_failed_field_idx` (`failed_field`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ans_data`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ans_data` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `upload_id` varchar(768) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `issue_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `catalog_number` longtext COLLATE utf8mb4_0900_bin,
  `inscription_raw` longtext COLLATE utf8mb4_0900_bin,
  `reverse_inscription` longtext COLLATE utf8mb4_0900_bin,
  `hierarchy_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `mint_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `state_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `inscription_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `ans_data_upload_id_key` (`upload_id`),
  KEY `ans_data_inscription_id_fkey` (`inscription_id`),
  KEY `ans_data_mint_id_fkey` (`mint_id`),
  KEY `ans_data_state_id_fkey` (`state_id`),
  KEY `ans_data_hierarchy_id_idx` (`hierarchy_id`),
  KEY `ans_data_issue_id_idx` (`issue_id`),
  CONSTRAINT `ans_data_hierarchy_id_fkey` FOREIGN KEY (`hierarchy_id`) REFERENCES `coin_type_hierarchy` (`id`),
  CONSTRAINT `ans_data_inscription_id_fkey` FOREIGN KEY (`inscription_id`) REFERENCES `inscriptions` (`id`),
  CONSTRAINT `ans_data_issue_id_fkey` FOREIGN KEY (`issue_id`) REFERENCES `coin_issues` (`id`),
  CONSTRAINT `ans_data_mint_id_fkey` FOREIGN KEY (`mint_id`) REFERENCES `mints` (`id`),
  CONSTRAINT `ans_data_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `states` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `ans_data_upload`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `ans_data_upload` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `coin_type_zh` varchar(768) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `coin_type_en` longtext COLLATE utf8mb4_0900_bin,
  `catalog_number` varchar(768) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `inscription_raw` longtext COLLATE utf8mb4_0900_bin,
  `inscription` varchar(768) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `reverse_inscription` longtext COLLATE utf8mb4_0900_bin,
  `state_zh` longtext COLLATE utf8mb4_0900_bin,
  `state_en` longtext COLLATE utf8mb4_0900_bin,
  `mint_zh` longtext COLLATE utf8mb4_0900_bin,
  `mint_en` longtext COLLATE utf8mb4_0900_bin,
  `inscription_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  KEY `idx_ans_data_catalog_number` (`catalog_number`),
  KEY `idx_ans_data_coin_type` (`coin_type_zh`),
  KEY `idx_ans_data_inscription` (`inscription`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `coin_issues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coin_issues` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `coin_type_code` varchar(768) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `description_zh` longtext COLLATE utf8mb4_0900_bin,
  `description_en` longtext COLLATE utf8mb4_0900_bin,
  `note_zh` longtext COLLATE utf8mb4_0900_bin,
  `note_en` longtext COLLATE utf8mb4_0900_bin,
  `reverse_inscription` longtext COLLATE utf8mb4_0900_bin,
  `mint_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `state_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `inscription_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `coin_type_hierarchy_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `legacy_type` longtext COLLATE utf8mb4_0900_bin,
  `legacy_inscription` longtext COLLATE utf8mb4_0900_bin,
  `legacy_mint` longtext COLLATE utf8mb4_0900_bin,
  `legacy_state` longtext COLLATE utf8mb4_0900_bin,
  PRIMARY KEY (`id`),
  UNIQUE KEY `coin_issues_coin_type_code_key` (`coin_type_code`),
  KEY `coin_issues_coin_type_hierarchy_id_idx` (`coin_type_hierarchy_id`),
  KEY `coin_issues_inscription_id_idx` (`inscription_id`),
  KEY `coin_issues_mint_id_idx` (`mint_id`),
  KEY `coin_issues_state_id_idx` (`state_id`),
  CONSTRAINT `coin_issues_coin_type_hierarchy_id_fkey` FOREIGN KEY (`coin_type_hierarchy_id`) REFERENCES `coin_type_hierarchy` (`id`) ON DELETE SET NULL,
  CONSTRAINT `coin_issues_inscription_id_fkey` FOREIGN KEY (`inscription_id`) REFERENCES `inscriptions` (`id`) ON DELETE SET NULL,
  CONSTRAINT `coin_issues_mint_id_fkey` FOREIGN KEY (`mint_id`) REFERENCES `mints` (`id`) ON DELETE SET NULL,
  CONSTRAINT `coin_issues_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `states` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `coin_items`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coin_items` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `coin_item_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `find_code` varchar(768) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `deprecated_coin_type_code` longtext COLLATE utf8mb4_0900_bin,
  `field_no` longtext COLLATE utf8mb4_0900_bin,
  `artifact_no` longtext COLLATE utf8mb4_0900_bin,
  `length_mm` longtext COLLATE utf8mb4_0900_bin,
  `width_mm` longtext COLLATE utf8mb4_0900_bin,
  `shoulder_width_mm` longtext COLLATE utf8mb4_0900_bin,
  `foot_width_mm` longtext COLLATE utf8mb4_0900_bin,
  `weight_g` longtext COLLATE utf8mb4_0900_bin,
  `condition_zh` longtext COLLATE utf8mb4_0900_bin,
  `condition_en` longtext COLLATE utf8mb4_0900_bin,
  `measurement_note_zh` longtext COLLATE utf8mb4_0900_bin,
  `measurement_note_en` longtext COLLATE utf8mb4_0900_bin,
  `description_zh` longtext COLLATE utf8mb4_0900_bin,
  `description_en` longtext COLLATE utf8mb4_0900_bin,
  `note_zh` longtext COLLATE utf8mb4_0900_bin,
  `note_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) DEFAULT CURRENT_TIMESTAMP(6),
  `coin_issues_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `coin_items_coin_item_code_key` (`coin_item_code`),
  KEY `coin_items_coin_issues_id_idx` (`coin_issues_id`),
  KEY `idx_coin_items_find_code` (`find_code`),
  CONSTRAINT `coin_items_coin_issues_id_fkey` FOREIGN KEY (`coin_issues_id`) REFERENCES `coin_issues` (`id`) ON DELETE SET NULL,
  CONSTRAINT `coin_items_find_code_fkey` FOREIGN KEY (`find_code`) REFERENCES `finds` (`find_code`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `coin_type_hierarchy`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `coin_type_hierarchy` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `level1_zh` varchar(153) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `level1_en` longtext COLLATE utf8mb4_0900_bin,
  `level2_zh` varchar(153) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `level2_en` longtext COLLATE utf8mb4_0900_bin,
  `level3_zh` varchar(153) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `level3_en` longtext COLLATE utf8mb4_0900_bin,
  `level4_zh` varchar(153) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `level4_en` longtext COLLATE utf8mb4_0900_bin,
  `level5_zh` varchar(153) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `level5_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `img_acc_num` longtext COLLATE utf8mb4_0900_bin,
  `name_zh` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `name_en` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `description_zh` longtext COLLATE utf8mb4_0900_bin,
  `description_en` longtext COLLATE utf8mb4_0900_bin,
  `type_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `coin_type_hierarchy_name_en_key` (`name_en`),
  UNIQUE KEY `coin_type_hierarchy_name_zh_key` (`name_zh`),
  UNIQUE KEY `coin_type_hierarchy_type_code_unique` (`type_code`),
  UNIQUE KEY `coin_type_hierarchy_path_unique` (`level1_zh`,`level2_zh`,`level3_zh`,`level4_zh`,`level5_zh`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `contexts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `contexts` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `context_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `site_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `context_name_zh` longtext COLLATE utf8mb4_0900_bin NOT NULL,
  `context_name_en` longtext COLLATE utf8mb4_0900_bin,
  `context_original_code` longtext COLLATE utf8mb4_0900_bin,
  `context_type_zh` longtext COLLATE utf8mb4_0900_bin,
  `context_type_en` longtext COLLATE utf8mb4_0900_bin,
  `description_zh` longtext COLLATE utf8mb4_0900_bin,
  `description_en` longtext COLLATE utf8mb4_0900_bin,
  `note_zh` longtext COLLATE utf8mb4_0900_bin,
  `note_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) DEFAULT CURRENT_TIMESTAMP(6),
  `period_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `contexts_context_code_key` (`context_code`),
  KEY `idx_contexts_period_id` (`period_id`),
  KEY `idx_contexts_site_code` (`site_code`),
  CONSTRAINT `contexts_period_id_fkey` FOREIGN KEY (`period_id`) REFERENCES `periods` (`id`) ON DELETE SET NULL,
  CONSTRAINT `contexts_site_code_fkey` FOREIGN KEY (`site_code`) REFERENCES `sites` (`site_code`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `deleted_rows`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `deleted_rows` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `table_name` longtext COLLATE utf8mb4_0900_bin NOT NULL,
  `row_data` json NOT NULL,
  `deleted_by` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `finds`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `finds` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `find_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `context_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `deprecated_coin_type_code` varchar(768) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `presence` tinyint(1) DEFAULT '1',
  `quantity_total` int DEFAULT NULL,
  `quantity_min` int DEFAULT NULL,
  `quantity_max` int DEFAULT NULL,
  `quantity_estimated` int DEFAULT NULL,
  `quantity_is_estimated` tinyint(1) DEFAULT '0',
  `total_weight_g` decimal(65,30) DEFAULT NULL,
  `quantity_note_zh` longtext COLLATE utf8mb4_0900_bin,
  `quantity_note_en` longtext COLLATE utf8mb4_0900_bin,
  `description_zh` longtext COLLATE utf8mb4_0900_bin,
  `description_en` longtext COLLATE utf8mb4_0900_bin,
  `note_zh` longtext COLLATE utf8mb4_0900_bin,
  `note_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) DEFAULT CURRENT_TIMESTAMP(6),
  `coin_issues_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `finds_find_code_key` (`find_code`),
  KEY `finds_coin_issues_id_idx` (`coin_issues_id`),
  KEY `idx_finds_coin_type_code` (`deprecated_coin_type_code`),
  KEY `idx_finds_context_code` (`context_code`),
  CONSTRAINT `finds_coin_issues_id_fkey` FOREIGN KEY (`coin_issues_id`) REFERENCES `coin_issues` (`id`) ON DELETE SET NULL,
  CONSTRAINT `finds_context_code_fkey` FOREIGN KEY (`context_code`) REFERENCES `contexts` (`context_code`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `images`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `images` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `filename` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `source_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `source_text` longtext COLLATE utf8mb4_0900_bin,
  `caption_zh` longtext COLLATE utf8mb4_0900_bin,
  `caption_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `note_zh` longtext COLLATE utf8mb4_0900_bin,
  `note_en` longtext COLLATE utf8mb4_0900_bin,
  PRIMARY KEY (`id`),
  UNIQUE KEY `images_filename_key` (`filename`),
  KEY `images_source_id_idx` (`source_id`),
  CONSTRAINT `images_source_id_fkey` FOREIGN KEY (`source_id`) REFERENCES `sources` (`id`),
  CONSTRAINT `images_source_exclusive` CHECK (((`source_id` is null) or (`source_text` is null)))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `inscriptions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `inscriptions` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `inscription_zh` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `inscription_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `inscriptions_inscription_zh_key` (`inscription_zh`),
  KEY `idx_inscription_term_inscription_zh` (`inscription_zh`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `mints`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `mints` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `name_zh` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `name_en` longtext COLLATE utf8mb4_0900_bin,
  `precision_level` int DEFAULT NULL,
  `latitude` decimal(10,7) DEFAULT NULL,
  `longitude` decimal(10,7) DEFAULT NULL,
  `description_zh` longtext COLLATE utf8mb4_0900_bin,
  `description_en` longtext COLLATE utf8mb4_0900_bin,
  `citation` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `state_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `modern_location_zh` longtext COLLATE utf8mb4_0900_bin,
  `modern_location_en` longtext COLLATE utf8mb4_0900_bin,
  `location_note` longtext COLLATE utf8mb4_0900_bin,
  `image_ids` json NOT NULL DEFAULT (_utf8mb4'{}'),
  `sources_unlinked` json NOT NULL DEFAULT (_utf8mb4'{}'),
  `mint_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `alternative_names` json NOT NULL DEFAULT (_utf8mb4'{}'),
  PRIMARY KEY (`id`),
  UNIQUE KEY `mint_town_name_zh_unique` (`name_zh`),
  UNIQUE KEY `mints_mint_code_key` (`mint_code`),
  KEY `mints_state_id_idx` (`state_id`),
  CONSTRAINT `mints_state_id_fkey` FOREIGN KEY (`state_id`) REFERENCES `states` (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `periods`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `periods` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `period_zh` varchar(768) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `period_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `periods_period_zh_key` (`period_zh`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sites`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sites` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `site_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `site_name_zh` longtext COLLATE utf8mb4_0900_bin NOT NULL,
  `site_name_en` longtext COLLATE utf8mb4_0900_bin,
  `province_zh` varchar(256) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `province_en` longtext COLLATE utf8mb4_0900_bin,
  `city_zh` varchar(256) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `city_en` longtext COLLATE utf8mb4_0900_bin,
  `county_zh` varchar(256) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  `county_en` longtext COLLATE utf8mb4_0900_bin,
  `location_detail_zh` longtext COLLATE utf8mb4_0900_bin,
  `location_detail_en` longtext COLLATE utf8mb4_0900_bin,
  `lat` double DEFAULT NULL,
  `lng` double DEFAULT NULL,
  `precision_level` int DEFAULT NULL,
  `site_type_zh` longtext COLLATE utf8mb4_0900_bin,
  `site_type_en` longtext COLLATE utf8mb4_0900_bin,
  `description_zh` longtext COLLATE utf8mb4_0900_bin,
  `description_en` longtext COLLATE utf8mb4_0900_bin,
  `note_zh` longtext COLLATE utf8mb4_0900_bin,
  `note_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) DEFAULT CURRENT_TIMESTAMP(6),
  `period_id` char(36) COLLATE utf8mb4_0900_bin DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sites_site_code_key` (`site_code`),
  KEY `idx_sites_lat_lng` (`lat`,`lng`),
  KEY `idx_sites_location` (`province_zh`,`city_zh`,`county_zh`),
  KEY `idx_sites_period_id` (`period_id`),
  CONSTRAINT `sites_period_id_fkey` FOREIGN KEY (`period_id`) REFERENCES `periods` (`id`) ON DELETE SET NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `source_links`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `source_links` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `source_link_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `source_code` varchar(256) COLLATE utf8mb4_0900_bin NOT NULL,
  `target_type` varchar(256) COLLATE utf8mb4_0900_bin NOT NULL,
  `target_code` varchar(256) COLLATE utf8mb4_0900_bin NOT NULL,
  `page` longtext COLLATE utf8mb4_0900_bin,
  `note_zh` longtext COLLATE utf8mb4_0900_bin,
  `note_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) DEFAULT CURRENT_TIMESTAMP(6),
  PRIMARY KEY (`id`),
  UNIQUE KEY `source_links_source_link_code_key` (`source_link_code`),
  UNIQUE KEY `source_links_unique` (`source_code`,`target_type`,`target_code`),
  CONSTRAINT `source_links_source_code_fkey` FOREIGN KEY (`source_code`) REFERENCES `sources` (`source_code`) ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT `source_links_target_type_check` CHECK ((`target_type` in (_utf8mb4'site',_utf8mb4'context',_utf8mb4'find',_utf8mb4'coin_item',_utf8mb4'coin_type',_utf8mb4'mint')))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `sources`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `sources` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `source_code` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `author1_zh` longtext COLLATE utf8mb4_0900_bin,
  `author1_en` longtext COLLATE utf8mb4_0900_bin,
  `title_zh` longtext COLLATE utf8mb4_0900_bin,
  `title_en` longtext COLLATE utf8mb4_0900_bin,
  `language` longtext COLLATE utf8mb4_0900_bin,
  `year` int DEFAULT NULL,
  `publication_zh` longtext COLLATE utf8mb4_0900_bin,
  `publication_en` longtext COLLATE utf8mb4_0900_bin,
  `page` longtext COLLATE utf8mb4_0900_bin,
  `citation_zh` longtext COLLATE utf8mb4_0900_bin,
  `citation_en` longtext COLLATE utf8mb4_0900_bin,
  `url` longtext COLLATE utf8mb4_0900_bin,
  `note_zh` longtext COLLATE utf8mb4_0900_bin,
  `note_en` longtext COLLATE utf8mb4_0900_bin,
  `created_at` datetime(6) DEFAULT CURRENT_TIMESTAMP(6),
  `type` longtext COLLATE utf8mb4_0900_bin,
  `editor_zh` longtext COLLATE utf8mb4_0900_bin,
  `editor_en` longtext COLLATE utf8mb4_0900_bin,
  `book_zh` longtext COLLATE utf8mb4_0900_bin,
  `book_en` longtext COLLATE utf8mb4_0900_bin,
  `place_zh` longtext COLLATE utf8mb4_0900_bin,
  `place_en` longtext COLLATE utf8mb4_0900_bin,
  `author2_zh` longtext COLLATE utf8mb4_0900_bin,
  `author2_en` longtext COLLATE utf8mb4_0900_bin,
  `author3_zh` longtext COLLATE utf8mb4_0900_bin,
  `author3_en` longtext COLLATE utf8mb4_0900_bin,
  `volume` longtext COLLATE utf8mb4_0900_bin,
  `date` longtext COLLATE utf8mb4_0900_bin,
  `museum` longtext COLLATE utf8mb4_0900_bin,
  PRIMARY KEY (`id`),
  UNIQUE KEY `sources_source_code_key` (`source_code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `states`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!50503 SET character_set_client = utf8mb4 */;
CREATE TABLE `states` (
  `id` char(36) COLLATE utf8mb4_0900_bin NOT NULL DEFAULT (uuid()),
  `created_at` datetime(6) NOT NULL DEFAULT CURRENT_TIMESTAMP(6),
  `state_zh` varchar(768) COLLATE utf8mb4_0900_bin NOT NULL,
  `state_en` longtext COLLATE utf8mb4_0900_bin,
  PRIMARY KEY (`id`),
  UNIQUE KEY `states_state_key` (`state_zh`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_bin;
/*!40101 SET character_set_client = @saved_cs_client */;
DROP TABLE IF EXISTS `v_ans_flat`;
/*!50001 DROP VIEW IF EXISTS `v_ans_flat`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_ans_flat` AS SELECT 
 1 AS `id`,
 1 AS `catalog_number`,
 1 AS `level1_zh`,
 1 AS `level1_en`,
 1 AS `level2_zh`,
 1 AS `level2_en`,
 1 AS `level3_zh`,
 1 AS `level3_en`,
 1 AS `level4_zh`,
 1 AS `level4_en`,
 1 AS `level5_zh`,
 1 AS `level5_en`,
 1 AS `inscription_zh`,
 1 AS `inscription_en`,
 1 AS `mint_zh`,
 1 AS `mint_en`,
 1 AS `state_zh`,
 1 AS `state_en`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `v_coin_finds`;
/*!50001 DROP VIEW IF EXISTS `v_coin_finds`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_coin_finds` AS SELECT 
 1 AS `find_code`,
 1 AS `context_code`,
 1 AS `site_code`,
 1 AS `coin_issues_id`,
 1 AS `coin_type_id`,
 1 AS `coin_type_zh`,
 1 AS `coin_type_en`,
 1 AS `inscription_id`,
 1 AS `inscription_zh`,
 1 AS `inscription_en`,
 1 AS `state_id`,
 1 AS `state_zh`,
 1 AS `state_en`,
 1 AS `mint_id`,
 1 AS `mint_zh`,
 1 AS `mint_en`,
 1 AS `quantity_for_map`,
 1 AS `unquantified`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `v_coin_issues_flat`;
/*!50001 DROP VIEW IF EXISTS `v_coin_issues_flat`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_coin_issues_flat` AS SELECT 
 1 AS `id`,
 1 AS `coin_type_code`,
 1 AS `description_zh`,
 1 AS `description_en`,
 1 AS `mint_id`,
 1 AS `state_id`,
 1 AS `inscription_id`,
 1 AS `coin_type_hierarchy_id`,
 1 AS `mint_zh`,
 1 AS `mint_en`,
 1 AS `state_zh`,
 1 AS `state_en`,
 1 AS `inscription`,
 1 AS `inscription_en`,
 1 AS `level2_zh`,
 1 AS `level2_en`,
 1 AS `major_type_zh`,
 1 AS `major_type_en`,
 1 AS `minor_type_zh`,
 1 AS `minor_type_en`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `v_coin_map_sites`;
/*!50001 DROP VIEW IF EXISTS `v_coin_map_sites`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_coin_map_sites` AS SELECT 
 1 AS `site_code`,
 1 AS `site_name_zh`,
 1 AS `site_name_en`,
 1 AS `province_zh`,
 1 AS `province_en`,
 1 AS `city_zh`,
 1 AS `city_en`,
 1 AS `county_zh`,
 1 AS `county_en`,
 1 AS `lat`,
 1 AS `lng`,
 1 AS `precision_level`,
 1 AS `site_type_zh`,
 1 AS `site_type_en`,
 1 AS `find_record_count`,
 1 AS `total_quantity_for_map`,
 1 AS `level1_types_zh`,
 1 AS `level2_types_zh`,
 1 AS `level3_types_zh`,
 1 AS `level4_types_zh`,
 1 AS `level5_types_zh`,
 1 AS `inscriptions`,
 1 AS `states_zh`,
 1 AS `mints_zh`,
 1 AS `level1_types_en`,
 1 AS `level2_types_en`,
 1 AS `level3_types_en`,
 1 AS `level4_types_en`,
 1 AS `level5_types_en`,
 1 AS `inscriptions_en`,
 1 AS `states_en`,
 1 AS `mints_en`,
 1 AS `description_zh`,
 1 AS `description_en`,
 1 AS `period_zh`,
 1 AS `period_en`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `v_mint_stats`;
/*!50001 DROP VIEW IF EXISTS `v_mint_stats`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_mint_stats` AS SELECT 
 1 AS `mint_id`,
 1 AS `mint_code`,
 1 AS `find_count`,
 1 AS `coin_count`,
 1 AS `site_count`,
 1 AS `inscriptions`,
 1 AS `issue_count`,
 1 AS `type_labels`*/;
SET character_set_client = @saved_cs_client;
DROP TABLE IF EXISTS `v_source_link_targets`;
/*!50001 DROP VIEW IF EXISTS `v_source_link_targets`*/;
SET @saved_cs_client     = @@character_set_client;
/*!50503 SET character_set_client = utf8mb4 */;
/*!50001 CREATE VIEW `v_source_link_targets` AS SELECT 
 1 AS `target_type`,
 1 AS `target_code`,
 1 AS `label`,
 1 AS `href`*/;
SET character_set_client = @saved_cs_client;
/*!50001 DROP VIEW IF EXISTS `v_ans_flat`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_ans_flat` AS select `a`.`id` AS `id`,`a`.`catalog_number` AS `catalog_number`,`cth`.`level1_zh` AS `level1_zh`,`cth`.`level1_en` AS `level1_en`,`cth`.`level2_zh` AS `level2_zh`,`cth`.`level2_en` AS `level2_en`,`cth`.`level3_zh` AS `level3_zh`,`cth`.`level3_en` AS `level3_en`,`cth`.`level4_zh` AS `level4_zh`,`cth`.`level4_en` AS `level4_en`,`cth`.`level5_zh` AS `level5_zh`,`cth`.`level5_en` AS `level5_en`,`insc`.`inscription_zh` AS `inscription_zh`,`insc`.`inscription_en` AS `inscription_en`,`m`.`name_zh` AS `mint_zh`,`m`.`name_en` AS `mint_en`,`st`.`state_zh` AS `state_zh`,`st`.`state_en` AS `state_en` from ((((`ans_data` `a` left join `coin_type_hierarchy` `cth` on((`cth`.`id` = `a`.`hierarchy_id`))) left join `inscriptions` `insc` on((`insc`.`id` = `a`.`inscription_id`))) left join `mints` `m` on((`m`.`id` = `a`.`mint_id`))) left join `states` `st` on((`st`.`id` = `a`.`state_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_coin_finds`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_coin_finds` AS select `f`.`find_code` AS `find_code`,`f`.`context_code` AS `context_code`,`c`.`site_code` AS `site_code`,`ci`.`id` AS `coin_issues_id`,`cth`.`id` AS `coin_type_id`,`cth`.`name_zh` AS `coin_type_zh`,`cth`.`name_en` AS `coin_type_en`,`ins`.`id` AS `inscription_id`,`ins`.`inscription_zh` AS `inscription_zh`,`ins`.`inscription_en` AS `inscription_en`,`st`.`id` AS `state_id`,`st`.`state_zh` AS `state_zh`,`st`.`state_en` AS `state_en`,`m`.`id` AS `mint_id`,`m`.`name_zh` AS `mint_zh`,`m`.`name_en` AS `mint_en`,coalesce(`f`.`quantity_total`,`f`.`quantity_estimated`,`f`.`quantity_min`,1) AS `quantity_for_map`,((`f`.`quantity_total` is null) and (`f`.`quantity_estimated` is null) and (`f`.`quantity_min` is null)) AS `unquantified` from ((((((`finds` `f` left join `contexts` `c` on((`c`.`context_code` = `f`.`context_code`))) left join `coin_issues` `ci` on((`ci`.`id` = `f`.`coin_issues_id`))) left join `coin_type_hierarchy` `cth` on((`cth`.`id` = `ci`.`coin_type_hierarchy_id`))) left join `inscriptions` `ins` on((`ins`.`id` = `ci`.`inscription_id`))) left join `states` `st` on((`st`.`id` = `ci`.`state_id`))) left join `mints` `m` on((`m`.`id` = `ci`.`mint_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_coin_issues_flat`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_coin_issues_flat` AS select `ci`.`id` AS `id`,`ci`.`coin_type_code` AS `coin_type_code`,`ci`.`description_zh` AS `description_zh`,`ci`.`description_en` AS `description_en`,`ci`.`mint_id` AS `mint_id`,`ci`.`state_id` AS `state_id`,`ci`.`inscription_id` AS `inscription_id`,`ci`.`coin_type_hierarchy_id` AS `coin_type_hierarchy_id`,`m`.`name_zh` AS `mint_zh`,`m`.`name_en` AS `mint_en`,`s`.`state_zh` AS `state_zh`,`s`.`state_en` AS `state_en`,`ins`.`inscription_zh` AS `inscription`,`ins`.`inscription_en` AS `inscription_en`,`cth`.`level2_zh` AS `level2_zh`,`cth`.`level2_en` AS `level2_en`,(case when (`cth`.`level1_zh` = '钱币') then `cth`.`level2_zh` else `cth`.`level1_zh` end) AS `major_type_zh`,(case when (`cth`.`level1_zh` = '钱币') then `cth`.`level2_en` else `cth`.`level1_en` end) AS `major_type_en`,(case when (`cth`.`level1_zh` = '钱币') then coalesce(`cth`.`level5_zh`,`cth`.`level4_zh`,`cth`.`level3_zh`) else coalesce(`cth`.`level5_zh`,`cth`.`level4_zh`,`cth`.`level3_zh`,`cth`.`level2_zh`) end) AS `minor_type_zh`,(case when (`cth`.`level1_zh` = '钱币') then coalesce(`cth`.`level5_en`,`cth`.`level4_en`,`cth`.`level3_en`) else coalesce(`cth`.`level5_en`,`cth`.`level4_en`,`cth`.`level3_en`,`cth`.`level2_en`) end) AS `minor_type_en` from ((((`coin_issues` `ci` left join `mints` `m` on((`m`.`id` = `ci`.`mint_id`))) left join `states` `s` on((`s`.`id` = `ci`.`state_id`))) left join `inscriptions` `ins` on((`ins`.`id` = `ci`.`inscription_id`))) left join `coin_type_hierarchy` `cth` on((`cth`.`id` = `ci`.`coin_type_hierarchy_id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_coin_map_sites`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_coin_map_sites` AS select `s`.`site_code` AS `site_code`,`s`.`site_name_zh` AS `site_name_zh`,`s`.`site_name_en` AS `site_name_en`,`s`.`province_zh` AS `province_zh`,`s`.`province_en` AS `province_en`,`s`.`city_zh` AS `city_zh`,`s`.`city_en` AS `city_en`,`s`.`county_zh` AS `county_zh`,`s`.`county_en` AS `county_en`,`s`.`lat` AS `lat`,`s`.`lng` AS `lng`,`s`.`precision_level` AS `precision_level`,`s`.`site_type_zh` AS `site_type_zh`,`s`.`site_type_en` AS `site_type_en`,count(`f`.`find_code`) AS `find_record_count`,sum(coalesce(`f`.`quantity_total`,`f`.`quantity_estimated`,`f`.`quantity_min`,1)) AS `total_quantity_for_map`,group_concat(distinct `cth`.`level1_zh` separator '、') AS `level1_types_zh`,group_concat(distinct `cth`.`level2_zh` separator '、') AS `level2_types_zh`,group_concat(distinct `cth`.`level3_zh` separator '、') AS `level3_types_zh`,group_concat(distinct `cth`.`level4_zh` separator '、') AS `level4_types_zh`,group_concat(distinct `cth`.`level5_zh` separator '、') AS `level5_types_zh`,group_concat(distinct `ins`.`inscription_zh` separator '、') AS `inscriptions`,group_concat(distinct `st`.`state_zh` separator '、') AS `states_zh`,group_concat(distinct `m`.`name_zh` separator '、') AS `mints_zh`,group_concat(distinct `cth`.`level1_en` separator '、') AS `level1_types_en`,group_concat(distinct `cth`.`level2_en` separator '、') AS `level2_types_en`,group_concat(distinct `cth`.`level3_en` separator '、') AS `level3_types_en`,group_concat(distinct `cth`.`level4_en` separator '、') AS `level4_types_en`,group_concat(distinct `cth`.`level5_en` separator '、') AS `level5_types_en`,group_concat(distinct `ins`.`inscription_en` separator '、') AS `inscriptions_en`,group_concat(distinct `st`.`state_en` separator '、') AS `states_en`,group_concat(distinct `m`.`name_en` separator '、') AS `mints_en`,`s`.`description_zh` AS `description_zh`,`s`.`description_en` AS `description_en`,`p`.`period_zh` AS `period_zh`,`p`.`period_en` AS `period_en` from ((((((((`sites` `s` left join `periods` `p` on((`p`.`id` = `s`.`period_id`))) join `contexts` `c` on((`c`.`site_code` = `s`.`site_code`))) join `finds` `f` on((`f`.`context_code` = `c`.`context_code`))) left join `coin_issues` `ci` on((`ci`.`id` = `f`.`coin_issues_id`))) left join `coin_type_hierarchy` `cth` on((`cth`.`id` = `ci`.`coin_type_hierarchy_id`))) left join `inscriptions` `ins` on((`ins`.`id` = `ci`.`inscription_id`))) left join `states` `st` on((`st`.`id` = `ci`.`state_id`))) left join `mints` `m` on((`m`.`id` = `ci`.`mint_id`))) where ((`s`.`lat` is not null) and (`s`.`lng` is not null)) group by `s`.`site_code`,`s`.`site_name_zh`,`s`.`site_name_en`,`s`.`province_zh`,`s`.`province_en`,`s`.`city_zh`,`s`.`city_en`,`s`.`county_zh`,`s`.`county_en`,`s`.`lat`,`s`.`lng`,`s`.`precision_level`,`s`.`site_type_zh`,`s`.`site_type_en`,`s`.`description_zh`,`s`.`description_en`,`p`.`period_zh`,`p`.`period_en` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_mint_stats`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_mint_stats` AS select `m`.`id` AS `mint_id`,`m`.`mint_code` AS `mint_code`,coalesce(`fs`.`find_count`,0) AS `find_count`,coalesce(`fs`.`coin_count`,0) AS `coin_count`,coalesce(`fs`.`site_count`,0) AS `site_count`,coalesce(`fi`.`inscriptions`,json_array()) AS `inscriptions`,coalesce(`ic`.`issue_count`,0) AS `issue_count`,coalesce(`tl`.`type_labels`,json_array()) AS `type_labels` from ((((`mints` `m` left join (select `ci`.`mint_id` AS `mint_id`,count(`f`.`id`) AS `find_count`,cast(sum(coalesce(`f`.`quantity_total`,`f`.`quantity_estimated`,`f`.`quantity_min`,0)) as signed) AS `coin_count`,count(distinct `ctx`.`site_code`) AS `site_count` from ((`coin_issues` `ci` join `finds` `f` on((`f`.`coin_issues_id` = `ci`.`id`))) join `contexts` `ctx` on((`ctx`.`context_code` = `f`.`context_code`))) group by `ci`.`mint_id`) `fs` on((`fs`.`mint_id` = `m`.`id`))) left join (select `d`.`mint_id` AS `mint_id`,json_arrayagg(`d`.`inscription`) AS `inscriptions` from (select distinct `ci`.`mint_id` AS `mint_id`,trim(`ins`.`inscription_zh`) AS `inscription` from (((`coin_issues` `ci` join `finds` `f` on((`f`.`coin_issues_id` = `ci`.`id`))) join `contexts` `ctx` on((`ctx`.`context_code` = `f`.`context_code`))) join `inscriptions` `ins` on((`ins`.`id` = `ci`.`inscription_id`))) where (trim(`ins`.`inscription_zh`) <> '')) `d` group by `d`.`mint_id`) `fi` on((`fi`.`mint_id` = `m`.`id`))) left join (select `coin_issues`.`mint_id` AS `mint_id`,count(0) AS `issue_count` from `coin_issues` group by `coin_issues`.`mint_id`) `ic` on((`ic`.`mint_id` = `m`.`id`))) left join (select `deduped`.`mint_id` AS `mint_id`,json_arrayagg(json_object('zh',`deduped`.`zh`,'en',`deduped`.`en`)) AS `type_labels` from (select `labels`.`mint_id` AS `mint_id`,`labels`.`zh` AS `zh`,`labels`.`en` AS `en`,row_number() OVER (PARTITION BY `labels`.`mint_id`,`labels`.`zh` ORDER BY (`labels`.`coin_type_code` is null),`labels`.`coin_type_code` )  AS `rn` from (select `v_coin_issues_flat`.`mint_id` AS `mint_id`,coalesce(`v_coin_issues_flat`.`minor_type_zh`,`v_coin_issues_flat`.`major_type_zh`) AS `zh`,(case when (`v_coin_issues_flat`.`minor_type_zh` is not null) then `v_coin_issues_flat`.`minor_type_en` else `v_coin_issues_flat`.`major_type_en` end) AS `en`,`v_coin_issues_flat`.`coin_type_code` AS `coin_type_code` from `v_coin_issues_flat`) `labels` where (`labels`.`zh` <> '')) `deduped` where (`deduped`.`rn` = 1) group by `deduped`.`mint_id`) `tl` on((`tl`.`mint_id` = `m`.`id`))) */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!50001 DROP VIEW IF EXISTS `v_source_link_targets`*/;
/*!50001 SET @saved_cs_client          = @@character_set_client */;
/*!50001 SET @saved_cs_results         = @@character_set_results */;
/*!50001 SET @saved_col_connection     = @@collation_connection */;
/*!50001 SET character_set_client      = utf8mb4 */;
/*!50001 SET character_set_results     = utf8mb4 */;
/*!50001 SET collation_connection      = utf8mb4_0900_ai_ci */;
/*!50001 CREATE ALGORITHM=UNDEFINED */
/*!50013 SQL SECURITY DEFINER */
/*!50001 VIEW `v_source_link_targets` AS select 'site' AS `target_type`,`s`.`site_code` AS `target_code`,(case when (`s`.`site_name_zh` is not null) then concat(concat(`s`.`site_code`,' · '),`s`.`site_name_zh`) else `s`.`site_code` end) AS `label`,concat('/sites/',`s`.`site_code`) AS `href` from `sites` `s` union all select 'context' AS `target_type`,`c`.`context_code` AS `target_code`,(case when (`c`.`context_name_zh` is not null) then concat(concat(`c`.`context_code`,' · '),`c`.`context_name_zh`) else `c`.`context_code` end) AS `label`,concat('/sites/',`c`.`site_code`) AS `href` from `contexts` `c` union all select 'find' AS `target_type`,`f`.`find_code` AS `target_code`,`f`.`find_code` AS `label`,concat('/sites/',`c`.`site_code`) AS `href` from (`finds` `f` join `contexts` `c` on((`c`.`context_code` = `f`.`context_code`))) union all select 'coin_item' AS `target_type`,`it`.`coin_item_code` AS `target_code`,(case when (`it`.`description_zh` is not null) then concat(concat(`it`.`coin_item_code`,' · '),`it`.`description_zh`) else `it`.`coin_item_code` end) AS `label`,concat('/sites/',`c`.`site_code`) AS `href` from ((`coin_items` `it` join `finds` `f` on((`f`.`find_code` = `it`.`find_code`))) join `contexts` `c` on((`c`.`context_code` = `f`.`context_code`))) union all select 'mint' AS `target_type`,`m`.`mint_code` AS `target_code`,(case when (`m`.`name_zh` is not null) then concat(concat(`m`.`mint_code`,' · '),`m`.`name_zh`) else `m`.`mint_code` end) AS `label`,concat('/mints/',`m`.`mint_code`) AS `href` from `mints` `m` */;
/*!50001 SET character_set_client      = @saved_cs_client */;
/*!50001 SET character_set_results     = @saved_cs_results */;
/*!50001 SET collation_connection      = @saved_col_connection */;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

