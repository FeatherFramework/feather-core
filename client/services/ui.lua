local state = false

function ToggleUI()
    if ActiveCharacter == nil or ActiveCharacter == {} then
        print("No active character fount")
        return 
    end

    state = not state

    SendNUIMessage({
        type = 'toggle',
        visible = state,
        player = ActiveCharacter,
        config = {
            xp = Config.XP
        },
        locale = LocalesAPI.translations
    })
end

RegisterNUICallback('updatestate', function(args, nuicb)
    state = args.state
    SetNuiFocus(state, state)
    nuicb('ok')
end)

RegisterNUICallback('updatelocale', function(args, nuicb)
    ActiveCharacter = RPCAPI.CallAsync("UpdatePlayerLang", args.locale, function()end)
    nuicb('ok')
end)

RegisterCommand("toggleUI", function(source, args, rawCommand)
    ToggleUI()
end, false)
