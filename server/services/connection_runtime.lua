local function LicenseIdentifier(source)
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:sub(1, 8) == 'license:' then return identifier end
    end
    return nil
end

function SetupConnectionRuntime()
    local registered = ConnectionAPI.RegisterGate('feather-core:credentials', function(source, playerName)
        local username = type(playerName) == 'string' and playerName:gsub('%s+', '') or ''
        if not LicenseIdentifier(source) then return 'Invalid License' end
        if username == '' then return 'Invalid Username' end
        return nil
    end, {
        priority = 0,
        timeoutMs = 5000,
        failClosed = true,
        label = 'credentials',
        failureMessage = 'Credential validation could not be completed. Please try again.'
    })

    if not registered then error('Core credential gate could not be registered.') end

    AddEventHandler('playerConnecting', function(name, _, deferrals)
        local source = source
        deferrals.defer()
        Wait(0)

        local rejection = ConnectionAPI.RunGates(source, name, deferrals)
        if rejection then
            deferrals.done(rejection)
            return
        end

        deferrals.update('Connecting to server...')
        deferrals.done()
    end)
end
