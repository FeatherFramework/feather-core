function SetupSharedAPI(SharedApi)
    SharedApi.Print = PrettyPrint
    SharedApi.RPC = RPCAPI
    SharedApi.DataView = DataView
    SharedApi.EventsAPI = EventsAPI
    SharedApi.Keys = Keys

    return SharedApi
end