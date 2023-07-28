function StartAPI()
    local CoreClientApi = {}
    
    CoreClientApi.Notify = NotifyAPI

    CoreClientApi = SetupSharedAPI(CoreClientApi)

    exports('initiate', function()
        return CoreClientApi
    end)
end