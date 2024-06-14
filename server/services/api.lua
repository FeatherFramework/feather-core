function StartAPI()
    local CoreServerApi = {}
    CoreServerApi.Discord = {}
    CoreServerApi.Discord.Webhook = DiscordWebHookAPI
    
    CoreServerApi.User = UserAPI
    CoreServerApi.Files = FilesAPI
    CoreServerApi.Character = CharacterAPI
    CoreServerApi.Instance = InstanceAPI
    CoreServerApi.Notify = SNotifyAPI
    CoreServerApi.Database = DatabaseAPI

    CoreServerApi = SetupSharedAPI(CoreServerApi)
    
    exports('initiate', function()
        return CoreServerApi
    end)
end
