function SetupSharedAPI(SharedApi)
    SharedApi.Print = PrettyPrint
    SharedApi.RPC = RPCAPI
    SharedApi.DataView = DataView
    SharedApi.EventsAPI = EventsAPI

    return SharedApi
end