function SetupSharedAPI(SharedApi)
    SharedApi.Print = PrettyPrint
    SharedApi.RPC = RPCAPI
    SharedApi.DataView = DataView
    
    return SharedApi
end