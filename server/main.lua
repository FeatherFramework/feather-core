ServerReady = false

function RunCore()
    SetupCLHeader()
    SetupCache()
    StartAPI()
    SetupPlayerEvents()
    ServerReady = true

end

RunCore()

