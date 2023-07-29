ClientReady = false

function RunCore()
    StartAPI()
    StartPopulationDensity()
    StartInteriorsFix()
    StartCharacterEssentials()
    StartWagonFix()

    ClientReady = true
end
RunCore()