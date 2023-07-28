CommandAPI = {}

function CommandAPI.Register(command, callback)
    RegisterCommand(command, callback)
    TriggerEvent("chat:addSuggestion", "/" .. value.command, value.suggestion)
end

function CommandAPI.Create(command, callback)
    Commands[command] = callback
    CommandAPI.Register(command, callback)
end

function SetupCommands()
    CreateThread(function()
        for key, value in pairs(Config.Commands) do
            CommandAPI.Create(key, value)
        end
    end)
end
