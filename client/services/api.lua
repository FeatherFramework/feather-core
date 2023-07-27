function StartAPI()
    local CoreClientApi = {}
    
    CoreClientApi = SetupSharedAPI(CoreClientApi)

    exports('initiate', function()
        return CoreClientApi
    end)
end