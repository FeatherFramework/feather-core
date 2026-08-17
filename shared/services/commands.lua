CommandAPI = {}

-- Registers a command and its chat autocomplete suggestion in one call.
function CommandAPI.Register(command, suggestion, callback, params)
    if type(command) ~= 'string' or command == '' or not IsCallable(callback) then return false end
    RegisterCommand(command, callback)
    TriggerEvent("chat:addSuggestion", "/" .. command, suggestion, params)
    return true
end

-- Registers every command listed in Config.Commands (config.lua) -- the
-- framework's declarative way to add simple commands without writing a
-- RegisterCommand call by hand.
function SetupCommands()
    CreateThread(function()
        for _, value in pairs(Config.Commands) do
            CommandAPI.Register(value.command, value.suggestion, value.callback)
        end
    end)
end
