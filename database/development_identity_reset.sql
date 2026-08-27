-- Feather clean-slate development identity reset.
-- DESTRUCTIVE: run only with the server fully stopped and only on a development database.
-- Preserves item/category definitions and Core/Character migration ledgers.

SET FOREIGN_KEY_CHECKS = 0;

-- Admin runtime authority and history.
DELETE FROM `feather_admin_case_links`;
DELETE FROM `feather_admin_cases`;
DELETE FROM `feather_admin_reports`;
DELETE FROM `feather_admin_role_changes`;
DELETE FROM `feather_admin_actions`;
DELETE FROM `feather_admin_bans`;
DELETE FROM `feather_admin_warnings`;
DELETE FROM `feather_admin_kicks`;
DELETE FROM `feather_admin_staff_accounts`;

-- Inventory instances and Character-owned containers. Item/category definitions remain.
DELETE FROM `character_equipment`;
DELETE FROM `inventory_access`;
DELETE FROM `item_metadata`;
DELETE FROM `inventory_blacklist`;
DELETE FROM `inventory_items`;
DELETE FROM `inventory`;
DELETE FROM `ground`;

-- Contract 1 Character documents and ownership.
DELETE FROM `character_creation_requests`;
DELETE FROM `character_appearance_documents`;
DELETE FROM `character_spawn_state`;
DELETE FROM `character_profiles`;
DELETE FROM `character_account_state`;

-- Core identity last, after every dependent owner record is gone.
DELETE FROM `core_account_identifiers`;
DELETE FROM `core_accounts`;

SET FOREIGN_KEY_CHECKS = 1;

-- Reset development-only sequence counters for readable test data.
ALTER TABLE `feather_admin_case_links` AUTO_INCREMENT = 1;
ALTER TABLE `feather_admin_cases` AUTO_INCREMENT = 1;
ALTER TABLE `feather_admin_reports` AUTO_INCREMENT = 1;
ALTER TABLE `feather_admin_role_changes` AUTO_INCREMENT = 1;
ALTER TABLE `feather_admin_actions` AUTO_INCREMENT = 1;
ALTER TABLE `feather_admin_bans` AUTO_INCREMENT = 1;
ALTER TABLE `feather_admin_warnings` AUTO_INCREMENT = 1;
ALTER TABLE `feather_admin_kicks` AUTO_INCREMENT = 1;
ALTER TABLE `inventory_items` AUTO_INCREMENT = 1;
ALTER TABLE `inventory` AUTO_INCREMENT = 1;
ALTER TABLE `ground` AUTO_INCREMENT = 1;
