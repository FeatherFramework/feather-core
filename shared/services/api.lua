function SetupSharedAPI(SharedApi)
    SharedApi.Print = PrettyPrint
    SharedApi.RPC = RPCAPI

    return SharedApi
end