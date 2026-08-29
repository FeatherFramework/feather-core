-- Entry point for the retained Core kernel.
function RunCore()
    local foundation = CoreFoundation.BeginStartup()
    if not foundation.ok then
        error(('[%s] %s'):format(foundation.code, foundation.message))
    end

    local migrations = CoreMigrationRunner.Run()
    if not migrations.ok then
        error(('[%s] %s'):format(migrations.code, migrations.message))
    end

    local migrationReady = CoreFoundation.MarkMigrationsComplete(migrations.value)
    if not migrationReady.ok then
        error(('[%s] %s'):format(migrationReady.code, migrationReady.message))
    end

    SetupCLHeader()
    SetupConnectionRuntime()
    SetupAccountIdentity()

    local ready = CoreFoundation.MarkReady()
    if not ready.ok then
        error(('[%s] %s'):format(ready.code, ready.message))
    end
end

-- Public contracts and first-party consumers require the canonical name.
if GetCurrentResourceName() ~= "feather-core" then
    error("ERROR feather-core failed to load, resource must be named feather-core otherwise Feather Core will not work properly")
else
    local ok, failure = xpcall(RunCore, debug.traceback)
    if not ok then
        CoreFoundation.MarkFailed('startup_failed', 'Feather Core failed during startup.', {
            reason = tostring(failure)
        })
        error(failure)
    end
end
