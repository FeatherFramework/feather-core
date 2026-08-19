function StartAPI()
    local CoreClientApi = {}

    CoreClientApi.Blip = BlipAPI
    CoreClientApi.Horse = HorseAPI
    CoreClientApi.Map = MapAPI
    CoreClientApi.Notify = NotifyAPI
    CoreClientApi.Object = ObjectAPI
    CoreClientApi.Ped = PedAPI
    CoreClientApi.Prompt = PromptsAPI
    CoreClientApi.Render = RenderAPI
    CoreClientApi.Wagon = WagonsAPI
    CoreClientApi.Keys = KeyPressAPI
    CoreClientApi.Clip = ClipAPI
    CoreClientApi.Teleport = TeleportAPI
    -- (CORE-30) PVPAPI was a real global (client/services/pvp.lua) but never
    -- attached to the exported API table, so `Feather.PVP` didn't exist for
    -- any other resource despite the export mechanism existing for exactly
    -- this purpose.
    CoreClientApi.PVP = PVPAPI
    -- Read-only passthrough so resources like feather-hud can display
    -- core economy config (e.g. XP-per-level) without duplicating it in
    -- their own config.lua.
    CoreClientApi.Config = {
        XP = Config.XP
    }

    CoreClientApi = SetupSharedAPI(CoreClientApi)

    exports('initiate', function()
        return CoreClientApi
    end)
end
