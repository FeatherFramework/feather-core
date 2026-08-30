CoreMigrationRunner = {}

local logger = CoreLogging.Create(GetCurrentResourceName(), 'migrations')

local function Hash(value)
    local hash = 2166136261
    for index = 1, #value do
        hash = ((hash ~ value:byte(index)) * 16777619) & 0xffffffff
    end
    return ('fnv1a32:%08x'):format(hash)
end

local function Checksum(migration)
    if migration.statements then
        return Hash(table.concat(migration.statements, '\n-- next statement --\n'))
    end
    return Hash(migration.checksumSource or '')
end

local function EnsureLedger()
    MySQL.query.await([[
        CREATE TABLE IF NOT EXISTS `core_schema_migrations` (
            `id` VARCHAR(100) NOT NULL,
            `checksum` VARCHAR(64) NOT NULL,
            `applied_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
            PRIMARY KEY (`id`)
        ) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci
    ]])
end

local function LoadApplied()
    local rows = MySQL.query.await('SELECT `id`, `checksum`, `applied_at` FROM `core_schema_migrations`') or {}
    local applied = {}
    for _, row in ipairs(rows) do
        applied[row.id] = row
    end
    return applied
end

local function ValidateDefinition(migration)
    if type(migration) ~= 'table'
        or type(migration.id) ~= 'string' or migration.id == '' then
        return CoreResults.Err('invalid_migration', 'A Core migration definition is invalid.')
    end

    if type(migration.statements) ~= 'table' and type(migration.up) ~= 'function' then
        return CoreResults.Err('invalid_migration', 'A Core migration requires statements or an up function.', {
            migrationId = migration.id
        })
    end

    if migration.up and (type(migration.checksumSource) ~= 'string' or migration.checksumSource == '') then
        return CoreResults.Err('invalid_migration', 'A functional migration requires checksumSource.', {
            migrationId = migration.id
        })
    end
    return CoreResults.Ok(true)
end

local function Apply(migration, checksum)
    logger.Info('migration.applying', { migrationId = migration.id, temporary = migration.temporary == true })

    if migration.statements then
        for index, statement in ipairs(migration.statements) do
            if type(statement) ~= 'string' or statement == '' then
                return CoreResults.Err('invalid_migration', 'A migration statement is invalid.', {
                    migrationId = migration.id,
                    statementIndex = index
                })
            end
            MySQL.query.await(statement)
        end
    end

    if migration.up then
        local result = migration.up()
        if not CoreResults.Is(result) then
            return CoreResults.Err('invalid_migration_result', 'A migration returned an invalid result.', {
                migrationId = migration.id
            })
        end

        if not result.ok then
            return result
        end
    end

    MySQL.insert.await(
        'INSERT INTO `core_schema_migrations` (`id`, `checksum`) VALUES (?, ?)',
        { migration.id, checksum }
    )
    logger.Info('migration.applied', { migrationId = migration.id })
    return CoreResults.Ok(true)
end

function CoreMigrationRunner.Run()
    local ok, result = xpcall(function()
        EnsureLedger()
        local applied = LoadApplied()
        local definitions = CoreMigrationDefinitions or {}
        local seen = {}
        local appliedCount = 0

        table.sort(definitions, function(left, right)
            return left.id < right.id
        end)

        for _, migration in ipairs(definitions) do
            local validation = ValidateDefinition(migration)
            if not validation.ok then
                return validation
            end

            if seen[migration.id] then
                return CoreResults.Err('duplicate_migration', 'A Core migration ID is duplicated.', {
                    migrationId = migration.id
                })
            end
            seen[migration.id] = true

            local checksum = Checksum(migration)
            local existing = applied[migration.id]
            if existing then
                if existing.checksum ~= checksum then
                    return CoreResults.Err('migration_checksum_mismatch', 'An applied Core migration has changed.', {
                        migrationId = migration.id,
                        expected = existing.checksum,
                        actual = checksum
                    })
                end
            else
                local application = Apply(migration, checksum)
                if not application.ok then
                    return application
                end
                appliedCount = appliedCount + 1
            end
        end

        return CoreResults.Ok({ total = #definitions, applied = appliedCount })
    end, debug.traceback)

    if not ok then
        logger.Error('migration.failed', { reason = tostring(result) })
        return CoreResults.Err('migration_failed', 'A Core database migration failed.', {
            reason = tostring(result)
        })
    end
    return result
end

RegisterCommand('CoreMigrationSmokeTest', function(source)
    if source ~= 0 then
        return
    end

    local tests = {
        {
            name = 'migration ledger',
            run = function()
                return tonumber(MySQL.scalar.await([[
                    SELECT COUNT(*) FROM information_schema.TABLES
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'core_schema_migrations'
                ]])) == 1
            end
        },
        {
            name = 'accounts table',
            run = function()
                return tonumber(MySQL.scalar.await([[
                    SELECT COUNT(*) FROM information_schema.TABLES
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'core_accounts'
                ]])) == 1
            end
        },
        {
            name = 'account identifiers',
            run = function()
                return tonumber(MySQL.scalar.await([[
                    SELECT COUNT(*) FROM information_schema.TABLES
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'core_account_identifiers'
                ]])) == 1
            end
        },
        {
            name = 'account settings',
            run = function()
                return tonumber(MySQL.scalar.await([[
                    SELECT COUNT(*) FROM information_schema.TABLES
                    WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = 'core_account_settings'
                ]])) == 1
            end
        },
        {
            name = 'idempotent rerun',
            run = function()
                local result = CoreMigrationRunner.Run()
                return result.ok and result.value.applied == 0
            end
        }
    }

    local passed = 0
    for _, test in ipairs(tests) do
        local ok, result = pcall(test.run)
        local success = ok and result == true
        if success then
            passed = passed + 1
        end
        print(('[CoreMigrationSmokeTest] %-24s %s'):format(test.name, success and 'PASS' or 'FAIL'))
        if not ok then
            logger.Error('migration_smoke_test.errored', { test = test.name, reason = tostring(result) })
        end
    end
    print(('[CoreMigrationSmokeTest] done %d/%d passed'):format(passed, #tests))
end, true)
