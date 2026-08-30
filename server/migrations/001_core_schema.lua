CoreMigrationDefinitions = CoreMigrationDefinitions or {}

CoreMigrationDefinitions[#CoreMigrationDefinitions + 1] = {
    id = '001_core_schema',
    statements = {
        [[
            CREATE TABLE IF NOT EXISTS `core_accounts` (
                `id` CHAR(36) NOT NULL,
                `display_name` VARCHAR(100) NOT NULL,
                `status` VARCHAR(32) NOT NULL DEFAULT 'active',
                `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                `updated_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
                PRIMARY KEY (`id`),
                INDEX `idx_core_accounts_status` (`status`)
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
        [[
            CREATE TABLE IF NOT EXISTS `core_account_identifiers` (
                `account_id` CHAR(36) NOT NULL,
                `identifier_type` VARCHAR(32) NOT NULL,
                `identifier_value` VARCHAR(128) NOT NULL,
                `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
                PRIMARY KEY (`account_id`, `identifier_type`, `identifier_value`),
                UNIQUE KEY `uq_core_account_identifier` (`identifier_type`, `identifier_value`),
                CONSTRAINT `fk_core_account_identifiers_account`
                    FOREIGN KEY (`account_id`) REFERENCES `core_accounts` (`id`) ON DELETE CASCADE
            ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
        ]],
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
