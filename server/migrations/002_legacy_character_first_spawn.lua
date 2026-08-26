CoreMigrationDefinitions = CoreMigrationDefinitions or {}

CoreMigrationDefinitions[#CoreMigrationDefinitions + 1] = {
    id = '002_legacy_character_first_spawn',
    checksumSource = 'legacy-character-first-spawn-v1',
    temporary = true,
    up = function()
        local tableExists = MySQL.scalar.await([[
            SELECT COUNT(*)
            FROM information_schema.TABLES
            WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'characters'
        ]])

        if tonumber(tableExists) ~= 1 then
            return CoreResults.Ok({ skipped = true, reason = 'characters_table_missing' })
        end

        local columnExists = MySQL.scalar.await([[
            SELECT COUNT(*)
            FROM information_schema.COLUMNS
            WHERE TABLE_SCHEMA = DATABASE()
              AND TABLE_NAME = 'characters'
              AND COLUMN_NAME = 'first_spawn'
        ]])

        if tonumber(columnExists) == 0 then
            MySQL.query.await([[
                ALTER TABLE `characters`
                ADD COLUMN `first_spawn` TINYINT(1) NOT NULL DEFAULT 1
            ]])
        end

        return CoreResults.Ok({ skipped = false })
    end
}
