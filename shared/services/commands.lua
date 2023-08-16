CommandAPI = {}

function CommandAPI.Register(command, suggestion, callback, params)
    RegisterCommand(command, callback)
    TriggerEvent("chat:addSuggestion", "/" .. command, suggestion, params)
end

function SetupCommands()
    CreateThread(function()
        for _, value in pairs(Config.Commands) do
            CommandAPI.Register(value.command, value.suggestion, value.callback)
        end
    end)
end
