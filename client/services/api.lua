function StartAPI()
    local CoreClientApi = {}

    CoreClientApi.Notify = NotifyAPI
    CoreClientApi.Blip = BlipAPI
    CoreClientApi.Object = ObjectAPI
    CoreClientApi.Ped = PedAPI
    CoreClientApi.Prompt = PromptsAPI
    CoreClientApi.Render = RenderAPI
    CoreClientApi.Map = MapAPI

    CoreClientApi = SetupSharedAPI(CoreClientApi)

    exports('initiate', function()
        return CoreClientApi
    end)
end