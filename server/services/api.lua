function StartAPI()
    local CoreServerApi = {}
    CoreServerApi.Discord = {}
    CoreServerApi.Discord.Webhook = DiscordWebHookAPI
    
    CoreServerApi.User = UserAPI
    CoreServerApi.Character = CharacterAPI
    CoreServerApi.Instance = InstanceAPI

    CoreServerApi = SetupSharedAPI(CoreServerApi)
    
    exports('initiate', function()
        return CoreServerApi
    end)
end
