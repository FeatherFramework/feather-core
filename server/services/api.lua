function StartAPI()
    local CoreServerApi = {}
    CoreServerApi.Discord = {}
    CoreServerApi.Discord.Webhook = DiscordWebHookAPI
    CoreServerApi.User = UserAPI


    CoreServerApi = SetupSharedAPI(CoreServerApi)
    
    exports('initiate', function()
        return CoreServerApi
    end)
end
