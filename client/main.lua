-- Flipped true once every client subsystem below has started; the spawn
-- handler in client/services/character.lua waits on this (and on
-- InteriorsActive/IMapsActive) before finishing the spawn sequence.
ClientReady = false

function RunCore()
    StartAPI()
    StartKeyListeners()
    StartPopulationDensity()
    StartInteriorsFix()
    StartPlayerRuntime()
    StartWagonFix()

    ClientReady = true
end

if GetCurrentResourceName() ~= "feather-core" then
    error("ERROR feather-core failed to load if you are a player report this to the server owner, if you are the server owner Feather Core resource must be named feather-core")
else
    RunCore()
end
