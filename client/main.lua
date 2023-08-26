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
RunCore()