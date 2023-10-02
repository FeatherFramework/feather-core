ClientReady = false

function RunCore()
    StartAPI()
    StartKeyListeners()
    StartPopulationDensity()
    StartInteriorsFix()
    StartCharacterEssentials()
    StartWagonFix()

    ClientReady = true
end

if GetCurrentResourceName() ~= "feather-core" then
    print("ERROR feather-core failed to load if you are a player report this to the server owner, if you are the server owner Feather Core resource must be named feather-core")
    print("Feather Core faled to load.")
else
    RunCore()
end