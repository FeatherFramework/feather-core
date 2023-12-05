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

    CoreClientApi = SetupSharedAPI(CoreClientApi)

    exports('initiate', function()
        return CoreClientApi
    end)
end
