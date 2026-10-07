local root = arg and arg[1] or '.'
for _, reachable in ipairs({true, false}) do
  local migrated, ready, failed = 0, false, false
  CoreFoundation = {
    BeginStartup = function() return {ok = true} end,
    MarkMigrationsComplete = function() return {ok = true} end,
    MarkReady = function() ready = true; return {ok = true} end,
    MarkFailed = function(_, _, details) failed = true; assert(details.reason:find('database_unavailable')) end,
  }
  CoreMigrationRunner = {Run = function() migrated = migrated + 1; return {ok = true} end}
  DB = {awaitReady = function(timeout) assert(timeout == 60000); coroutine.yield('waiting'); return reachable end}
  SetupCLHeader, SetupConnectionRuntime, SetupAccountIdentity = function() end, function() end, function() end
  GetCurrentResourceName = function() return 'feather-core' end
  local thread = coroutine.create(function() dofile(root .. '/server/main.lua') end)
  local ok, state = coroutine.resume(thread)
  assert(ok and state == 'waiting' and migrated == 0 and not ready)
  ok = coroutine.resume(thread)
  if reachable then assert(ok and migrated == 1 and ready and not failed)
  else assert(not ok and migrated == 0 and not ready and failed) end
end
print('PASS Core startup waits for DB readiness and fails before migrations on timeout')
