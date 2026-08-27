function StartAPI()
    local CoreServerApi = {}
    CoreServerApi.Discord = {}
    CoreServerApi.Discord.Webhook = DiscordWebHookAPI
    
    CoreServerApi.User = UserAPI
    CoreServerApi.Files = FilesAPI
    CoreServerApi.Instance = InstanceAPI
    CoreServerApi.Notify = SNotifyAPI
    CoreServerApi.Database = DatabaseAPI
    CoreServerApi.Connection = ConnectionAPI

    CoreServerApi = SetupSharedAPI(CoreServerApi)
    
    exports('initiate', function()
        return CoreServerApi
    end)
end
