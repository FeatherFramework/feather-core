-- Entry point, run once when the resource starts. Order matters: StartAPI()
-- (server/services/api.lua) must run before any other resource's
-- `exports['feather-core'].initiate()` call can succeed, and SetupCache()/
-- SetupPlayerEvents() must be wired up before the first playerJoining event
-- can be handled correctly.
function RunCore()
    SetupCLHeader()
    SetupCache()
    StartAPI()
    StartVersioner()
    SetupPlayerEvents()
end

-- feather-core hardcodes its own resource name in several places (routing
-- bucket/RPC internals assume it), so refuse to run under a renamed folder.
if GetCurrentResourceName() ~= "feather-core" then
    error("ERROR feather-core failed to load, resource must be named feather-core otherwise Feather Core will not work properly")
else
    RunCore()
end
