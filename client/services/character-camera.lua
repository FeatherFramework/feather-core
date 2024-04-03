------- File Information --------
-- Inspired by Vorp Legacy Death Camera
-----------------------------------

local deathcam = nil
local angleY = 0.0
local angleZ = 0.0

function StartDeathCam()
    CreateThread(function()
        ClearFocus()
        local playerPed = PlayerPedId()
        deathcam = CreateCamWithParams("DEFAULT_SCRIPTED_CAMERA", GetEntityCoords(playerPed), 0, 0, 0,
            GetGameplayCamFov())
        SetCamActive(deathcam, true)
        RenderScriptCams(true, true, 1000, true, false)
    end)
end

function EndDeathCam()
    CreateThread(function()
        NetworkSetInSpectatorMode(false, PlayerPedId())
        ClearFocus()
        RenderScriptCams(false, false, 0, true, false)
        DestroyCam(deathcam, false)
        deathcam = nil
    end)
end

function ProcessCamControls()
   CreateThread(function()
        local playerCoords = GetEntityCoords(PlayerPedId())
        local newPos = ProcessNewPosition()
        SetCamCoord(deathcam, newPos.x, newPos.y, newPos.z)
        PointCamAtCoord(deathcam, playerCoords.x, playerCoords.y, playerCoords.z + 0.5)
    end)
end

function ProcessNewPosition()
    local mouseX = 0.0
    local mouseY = 0.0

    if (IsInputDisabled(0)) then
        mouseX = GetDisabledControlNormal(1, 0x4D8FB4C1) * 1.5
        mouseY = GetDisabledControlNormal(1, 0xFDA83190) * 1.5
    else
        mouseX = GetDisabledControlNormal(1, 0x4D8FB4C1) * 0.5
        mouseY = GetDisabledControlNormal(1, 0xFDA83190) * 0.5
    end

    angleZ = angleZ - mouseX
    angleY = angleY + mouseY

    if (angleY > 89.0) then angleY = 89.0 elseif (angleY < -89.0) then angleY = -89.0 end
    local pCoords = GetEntityCoords(PlayerPedId())
    local behindCam = {
        x = pCoords.x + ((Cos(angleZ) * Cos(angleY)) + (Cos(angleY) * Cos(angleZ))) / 2 * (3.0 + 0.5),
        y = pCoords.y + ((Sin(angleZ) * Cos(angleY)) + (Cos(angleY) * Sin(angleZ))) / 2 * (3.0 + 0.5),
        z = pCoords.z + ((Sin(angleY))) * (3.0 + 0.5)
    }
    local rayHandle = StartShapeTestRay(pCoords.x, pCoords.y, pCoords.z + 0.5, behindCam.x, behindCam.y, behindCam.z, -1
    , PlayerPedId(), 0)
    local _, hitBool, hitCoords, _, _ = GetShapeTestResult(rayHandle)

    local maxRadius = 3.0
    if (hitBool and Vdist(pCoords.x, pCoords.y, pCoords.z + 0.5, hitCoords) < 3.0 + 0.5) then
        maxRadius = Vdist(pCoords.x, pCoords.y, pCoords.z + 0.5, hitCoords)
    end

    local offset = {
        x = ((Cos(angleZ) * Cos(angleY)) + (Cos(angleY) * Cos(angleZ))) / 2 * maxRadius,
        y = ((Sin(angleZ) * Cos(angleY)) + (Cos(angleY) * Sin(angleZ))) / 2 * maxRadius,
        z = ((Sin(angleY))) * maxRadius
    }

    return {
        x = pCoords.x + offset.x,
        y = pCoords.y + offset.y,
        z = pCoords.z + offset.z
    }
end
