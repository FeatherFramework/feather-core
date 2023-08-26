UIState = false
function ToggleUI()
    if ActiveCharacter == nil or ActiveCharacter == {} then
        print("No active character fount")
        return 
    end

    UIState = not UIState
    SendNUIMessage({
        type = 'toggle',
        visible = UIState,
        player = ActiveCharacter,
        config = {
            xp = Config.XP
        },
        locale = LocalesAPI.translations
    })
end

RegisterNUICallback('updatestate', function(args, nuicb)
    UIState = args.state
    SetNuiFocus(UIState, UIState)
    nuicb('ok')
end)

RegisterNUICallback('updatelocale', function(args, nuicb)
    ActiveCharacter = RPCAPI.CallAsync("UpdatePlayerLang", args.locale, function()end)
    nuicb('ok')
end)

CommandAPI.Register(Config.UI.command, Config.UI.suggestion, function()
    ToggleUI()
end)

KeyPressAPI:RegisterListener(Config.UI.hotkey, function()
    ToggleUI()
end)