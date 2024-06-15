function SetupSharedAPI(SharedApi)
    SharedApi.Print = PrettyPrint
    SharedApi.DataView = DataView
    SharedApi.EventsAPI = EventsAPI
    SharedApi.KeyCodes = Keys
    SharedApi.RPC = RPCAPI
    SharedApi.Command = CommandAPI
    SharedApi.Misc = MiscAPI
    SharedApi.Locale = LocalesAPI
    SharedApi.Math = MathAPI

    return SharedApi
end