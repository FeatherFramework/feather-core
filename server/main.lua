function RunCore()
    SetupCLHeader()
    SetupCache()
    StartAPI()
    StartVersioner()
    SetupPlayerEvents()
end

if GetCurrentResourceName() ~= "feather-core" then
    print("ERROR, resource must be named feather-core otherwise Feather Core will not work properly")
    print("Feather Core failed to load.")
else
    RunCore()
end