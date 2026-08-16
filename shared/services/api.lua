-- (CORE-12) Referenced below as SharedApi.Misc but never defined anywhere
-- in the repo -- `Feather.Misc` was always nil for every consumer. Defined
-- here (rather than alongside FilesAPI in server/services/file.lua) so it
-- exists identically on both client and server.
MiscAPI = {}

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