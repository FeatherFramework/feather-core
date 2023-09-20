function SetupSharedAPI(SharedApi)
    SharedApi.Print = PrettyPrint
    SharedApi.DataView = DataView
    SharedApi.EventsAPI = EventsAPI
    SharedApi.Keys = Keys
    SharedApi.RPC = RPCAPI
    SharedApi.Command = CommandAPI
    SharedApi.Misc = MiscAPI
    SharedApi.Locale = LocalesAPI

    return SharedApi
end