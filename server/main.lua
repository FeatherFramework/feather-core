-- Entry point, run once when the resource starts. The temporary non-Character
-- legacy API is registered before migrations, and account cache/connection
-- handlers are installed before players may join.
function RunCore()
    local foundation = CoreFoundation.BeginStartup()
    if not foundation.ok then
        error(('[%s] %s'):format(foundation.code, foundation.message))
    end

    -- Temporary non-Character compatibility surface. Character domain state
    -- and behavior are no longer exposed here.
    StartAPI()

    local migrations = CoreMigrationRunner.Run()
    if not migrations.ok then
        error(('[%s] %s'):format(migrations.code, migrations.message))
    end

    local migrationReady = CoreFoundation.MarkMigrationsComplete(migrations.value)
    if not migrationReady.ok then
        error(('[%s] %s'):format(migrationReady.code, migrationReady.message))
    end

    SetupCLHeader()
    SetupCache()
    StartVersioner()
    SetupAccountIdentity()
    SetupPlayerEvents()

    local notificationProvider = SetupNotificationProvider()
    if not notificationProvider.ok then
        error(('[%s] %s'):format(notificationProvider.code, notificationProvider.message))
    end

    local ready = CoreFoundation.MarkReady()
    if not ready.ok then
        error(('[%s] %s'):format(ready.code, ready.message))
    end
end

-- feather-core hardcodes its own resource name in several places (routing
-- bucket/RPC internals assume it), so refuse to run under a renamed folder.
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
