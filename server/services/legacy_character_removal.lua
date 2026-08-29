RegisterCommand('CoreLegacyCharacterRemovalSmokeTest', function(source, args)
    if source ~= 0 then return end

    local target = tonumber(args and args[1])
    if not target then
        local players = GetPlayers()
        target = players[1] and tonumber(players[1]) or nil
    end

    local routesResult = exports['feather-core']:GetRpcRoutes()
    local routes = {}
    if type(routesResult) == 'table' and routesResult.ok == true then
        for _, route in ipairs(routesResult.value or {}) do routes[route.route] = true end
    end
    local provider = exports['feather-core']:GetProvider('character-profile', nil, 1)
    local session = target and exports['feather-core']:GetSessionContext(target) or nil
    local inventoryClient = LoadResourceFile('feather-inventory', 'client/helpers/main.lua') or ''
    local adminServer = LoadResourceFile('feather-admin', 'server/services/boosters.lua') or ''

    local tests = {
        {
            name = 'legacy globals absent',
            passed = CharacterAPI == nil and CharacterController == nil and CharacterCache == nil
        },
        {
            name = 'legacy files removed',
            passed = LoadResourceFile('feather-core', 'server/services/character.lua') == nil
                and LoadResourceFile('feather-core', 'server/controllers/characters.lua') == nil
                and LoadResourceFile('feather-core', 'client/services/character.lua') == nil
                and LoadResourceFile('feather-core', 'client/services/character-camera.lua') == nil
                and LoadResourceFile('feather-core', 'server/controllers/users.lua') == nil
                and LoadResourceFile('feather-core', 'server/services/users.lua') == nil
                and LoadResourceFile('feather-core', 'server/services/cache.lua') == nil
                and LoadResourceFile('feather-core', 'server/services/api.lua') == nil
                and LoadResourceFile('feather-core', 'server/migrations/002_legacy_character_first_spawn.lua') == nil
        },
        {
            name = 'legacy routes absent',
            passed = routesResult and routesResult.ok == true
                and routes.GetCharacter == nil
                and routes.LogoutCharacter == nil
                and routes.UpdatePlayerCoords == nil
                and routes.CharacterDeath == nil
        },
        {
            name = 'legacy caches absent',
            passed = UserCache == nil and CacheAPI == nil and CharacterCache == nil
        },
        {
            name = 'consumers cut over',
            passed = not inventoryClient:find('UpdatePlayerCoords', 1, true)
                and not adminServer:find('Feather:Character:Revive', 1, true)
        },
        {
            name = 'profile provider ready',
            passed = type(provider) == 'table' and provider.ok == true
                and type(provider.value) == 'table'
                and type(provider.value.provider) == 'table'
                and provider.value.provider.owner == 'feather-character'
        },
        {
            name = 'session kernel ready',
            passed = target ~= nil and type(session) == 'table' and session.ok == true
                and type(session.value.characterId) == 'string'
        }
    }

    local passed = 0
    for _, test in ipairs(tests) do
        if test.passed then passed = passed + 1 end
        print(('[CoreLegacyCharacterRemovalSmokeTest] %-24s %s')
            :format(test.name, test.passed and 'PASS' or 'FAIL'))
    end
    print(('[CoreLegacyCharacterRemovalSmokeTest] done %d/%d passed source=%s')
        :format(passed, #tests, tostring(target or 'none')))
end, true)
