function RunCore()
    SetupCLHeader()
    SetupCache()
    StartAPI()
    StartVersioner()
    SetupPlayerEvents()
end

RunCore()
