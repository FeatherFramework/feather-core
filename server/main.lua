function RunCore()
    SetupCLHeader()
    SetupCache()
    StartAPI()
    StartVersioner()
    SetupPlayerEvents()
end

if GetCurrentResourceName() ~= "feather-core" then
    error("ERROR feather-core failed to load, resource must be named feather-core otherwise Feather Core will not work properly")
else
    RunCore()
end
