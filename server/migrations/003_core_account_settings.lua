CoreMigrationDefinitions = CoreMigrationDefinitions or {}

CoreMigrationDefinitions[#CoreMigrationDefinitions + 1] = {
    id = '003_core_account_settings',
    statements = {
        [[
            CREATE TABLE IF NOT EXISTS `core_account_settings` (
                `account_id` CHAR(36) NOT NULL,
                `locale` VARCHAR(16) NOT NULL,
                `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`account_id`),
                CONSTRAINT `fk_core_account_settings_account`
                    FOREIGN KEY (`account_id`) REFERENCES `core_accounts` (`id`) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]]
    }
}
