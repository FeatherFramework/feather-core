function RunCore()
    SetupCLHeader()
    StartReleaseFileCheck(GetCurrentResourceName(), "https://github.com/FeatherFramework/feather-core/releases/latest")
    SetupCache()
    StartAPI()
    SetupPlayerEvents()
end

RunCore()
