-- Entry point, run once when the resource starts. Order matters: StartAPI()
-- (server/services/api.lua) must run before any other resource's
-- `exports['feather-core'].initiate()` call can succeed, and SetupCache()/
-- SetupPlayerEvents() must be wired up before the first playerJoining event
-- can be handled correctly.
function RunCore()
    local foundation = CoreFoundation.BeginStartup()
    if not foundation.ok then
        error(('[%s] %s'):format(foundation.code, foundation.message))
    end

    -- Temporary construction bridge: first-party resources still import the
    -- legacy API during their own script initialization. Register it before
    -- the migration runner performs its first yielding database call. The
    -- Contract 1 readiness exports continue to report `migrating` until the
    -- database and remaining Core services are actually ready.
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
