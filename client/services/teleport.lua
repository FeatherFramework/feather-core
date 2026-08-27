-- Shared client teleport controller. It owns fading, destination streaming,
-- placement, physics settling, rollback, and cleanup for every caller.
TeleportAPI = {}

local teleporting = false
local activeEntity

local function number(value)
    value = tonumber(value)
    if not value or value ~= value or value == math.huge or value == -math.huge then return nil end
    return value
end

local function waitForFadeOut(duration, timeout)
    DoScreenFadeOut(duration)
    local deadline = GetGameTimer() + timeout
    while not IsScreenFadedOut() and GetGameTimer() < deadline do Wait(0) end
    return IsScreenFadedOut()
end

local function fadeIn(duration)
    if IsScreenFadedOut() or IsScreenFadingOut() then DoScreenFadeIn(duration) end
end

local function parseCoords(coords)
    if coords == nil then return nil end
    local kind = type(coords)
    if kind ~= 'table' and kind ~= 'vector3' and kind ~= 'vector4' then return nil end

    local x, y, z, heading
    if kind == 'vector3' then
        x, y, z = number(coords.x), number(coords.y), number(coords.z)
    elseif kind == 'vector4' then
        x, y, z, heading = number(coords.x), number(coords.y), number(coords.z), number(coords.w)
    else
        x = number(coords.x or coords[1])
        y = number(coords.y or coords[2])
        z = number(coords.z or coords[3])
        heading = number(coords.w or coords.h or coords[4])
    end
    if not x or not y or not z then return nil end
    return x, y, z, heading
end

local function requestDestination(entity, x, y, z, options)
    local stageHeight = number(options.streamHeight) or 50.0
    SetEntityCoordsNoOffset(entity, x, y, z + stageHeight, false, false, false)
    local started = GetGameTimer()
    local minimum = math.max(0, number(options.streamMinimum) or 1500)
    local deadline = started + math.max(minimum, number(options.streamTimeout) or 5000)
    repeat
        RequestCollisionAtCoord(x, y, z)
        RequestCollisionAtCoord(x, y, z + stageHeight)
        Wait(0)
    until (GetGameTimer() - started >= minimum and HasCollisionLoadedAroundEntity(entity))
        or GetGameTimer() >= deadline
    return GetGameTimer() - started >= minimum and HasCollisionLoadedAroundEntity(entity)
end

local function raycastSurface(x, y, entity, options)
    local top = number(options.probeTop) or 1000.0
    local bottom = number(options.probeBottom) or -100.0
    local ray = StartShapeTestRay(x, y, top, x, y, bottom, -1, entity, 7)
    local deadline = GetGameTimer() + (number(options.raycastTimeout) or 750)
    while GetGameTimer() < deadline do
        local status, hit, hitCoords = GetShapeTestResult(ray)
        if status == 2 then return hit and hitCoords.z or nil end
        Wait(0)
    end
end

local function findStableSurface(x, y, fallbackZ, entity, options)
    local started = GetGameTimer()
    local minimum = math.max(0, number(options.surfaceMinimum) or 1000)
    local deadline = started + math.max(minimum, number(options.surfaceTimeout) or 5000)
    local required = math.max(1, math.floor(number(options.surfaceStableProbes) or 3))
    local tolerance = math.max(0.0, number(options.surfaceTolerance) or 0.05)
    local candidate
    local stable = 0
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, fallbackZ)
        local surface = raycastSurface(x, y, entity, options)
        if surface then
            if candidate and math.abs(surface - candidate) <= tolerance then
                stable = stable + 1
            else
                candidate = surface
                stable = 1
            end
            if stable >= required and GetGameTimer() - started >= minimum then return candidate, 'surface' end
        else
            stable = 0
        end
        Wait(0)
    end
end

local function waitForExactSurface(x, y, z, entity, options)
    if options.requireNearbySurface == false then return true end
    local deadline = GetGameTimer() + (number(options.exactSurfaceTimeout) or 5000)
    local top = number(options.exactProbeAbove) or 2.0
    local bottom = number(options.exactProbeBelow) or 3.0
    local stable = 0
    local previous
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, z)
        local ray = StartShapeTestRay(x, y, z + top, x, y, z - bottom, -1, entity, 7)
        local rayDeadline = GetGameTimer() + 750
        while GetGameTimer() < rayDeadline do
            local status, hit, hitCoords = GetShapeTestResult(ray)
            if status == 2 then
                if hit then
                    stable = previous and math.abs(hitCoords.z - previous) <= 0.05 and stable + 1 or 1
                    previous = hitCoords.z
                    if stable >= 3 then return true end
                else
                    stable = 0
                end
                break
            end
            Wait(0)
        end
        Wait(0)
    end
    return false
end

local function rollback(entity, coords, heading, fade, fadeDuration)
    FreezeEntityPosition(entity, true)
    SetEntityCoordsNoOffset(entity, coords.x, coords.y, coords.z, false, false, false)
    SetEntityHeading(entity, heading)
    SetEntityVelocity(entity, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(coords.x, coords.y, coords.z)
    local deadline = GetGameTimer() + 2000
    while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < deadline do Wait(0) end
    FreezeEntityPosition(entity, false)
    teleporting = false
    activeEntity = nil
    if fade then fadeIn(fadeDuration) end
end

local function waitUntilSettled(entity, x, y, z, options)
    local started = GetGameTimer()
    local minimum = math.max(0, number(options.settleMinimum) or 300)
    local deadline = started + (number(options.settleTimeout) or 6000)
    local required = math.max(1, math.floor(number(options.stableFrames) or 8))
    local speedTolerance = math.max(0.0, number(options.speedTolerance) or 0.15)
    local zTolerance = math.max(0.0, number(options.zTolerance) or 0.03)
    local stable = 0
    local previousZ = GetEntityCoords(entity).z
    while GetGameTimer() < deadline do
        RequestCollisionAtCoord(x, y, z)
        local currentZ = GetEntityCoords(entity).z
        local ready = GetGameTimer() - started >= minimum
            and HasCollisionLoadedAroundEntity(entity)
            and not IsEntityInAir(entity)
            and GetEntitySpeed(entity) <= speedTolerance
            and math.abs(currentZ - previousZ) <= zTolerance
        stable = ready and stable + 1 or 0
        if stable >= required then return true end
        previousZ = currentZ
        Wait(0)
    end
    return false
end

function TeleportAPI:IsBusy()
    return teleporting
end

function TeleportAPI:FindSurface(x, y, fallbackZ, options)
    options = type(options) == 'table' and options or {}
    x, y, fallbackZ = number(x), number(y), number(fallbackZ)
    if not x or not y then return nil end
    return findStableSurface(x, y, fallbackZ or 0.0,
        tonumber(options.entity) or PlayerPedId(), options)
end

function TeleportAPI:ToCoords(coords, options)
    options = type(options) == 'table' and options or {}
    if teleporting then return { success = false, reason = 'busy' } end
    local x, y, requestedZ, coordinateHeading = parseCoords(coords)
    if not x then return { success = false, reason = 'invalid_coordinates' } end

    local entity = tonumber(options.entity) or PlayerPedId()
    if entity == 0 or not DoesEntityExist(entity) then
        return { success = false, reason = 'invalid_entity' }
    end

    local mode = options.mode
    if mode ~= 'exact' and mode ~= 'surface' then
        mode = options.findSurface == true and 'surface' or 'exact'
    end
    local heading = number(options.heading) or coordinateHeading
    local fade = options.fade ~= false
    local fadeDuration = math.max(0, math.floor(number(options.fadeDuration) or 500))
    local originalCoords = GetEntityCoords(entity)
    local originalHeading = GetEntityHeading(entity)

    teleporting = true
    activeEntity = entity
    if fade and not waitForFadeOut(fadeDuration, math.max(fadeDuration, number(options.fadeTimeout) or 2000)) then
        teleporting = false
        activeEntity = nil
        fadeIn(fadeDuration)
        return { success = false, reason = 'fade_failed' }
    end

    FreezeEntityPosition(entity, true)
    SetEntityVelocity(entity, 0.0, 0.0, 0.0)
    if not requestDestination(entity, x, y, requestedZ, options) then
        rollback(entity, originalCoords, originalHeading, fade, fadeDuration)
        return { success = false, reason = 'stream_timeout' }
    end

    if mode == 'exact' and not waitForExactSurface(x, y, requestedZ, entity, options) then
        rollback(entity, originalCoords, originalHeading, fade, fadeDuration)
        return { success = false, reason = 'exact_surface_not_found' }
    end

    local destinationZ = requestedZ
    local surfaceType = 'coordinates'
    if mode == 'surface' then
        destinationZ, surfaceType = findStableSurface(x, y, requestedZ, entity, options)
        if not destinationZ then
            rollback(entity, originalCoords, originalHeading, fade, fadeDuration)
            return { success = false, reason = 'surface_not_found' }
        end
        destinationZ = destinationZ + (number(options.zOffset) or 0.0)
        SetEntityCoords(entity, x, y, destinationZ, false, false, false, false)
    else
        destinationZ = destinationZ + (number(options.zOffset) or 0.0)
        SetEntityCoordsNoOffset(entity, x, y, destinationZ, false, false, false)
    end

    if heading then SetEntityHeading(entity, heading) end
    SetEntityVelocity(entity, 0.0, 0.0, 0.0)
    RequestCollisionAtCoord(x, y, destinationZ)
    Wait(0)
    FreezeEntityPosition(entity, false)

    if not waitUntilSettled(entity, x, y, destinationZ, options) then
        rollback(entity, originalCoords, originalHeading, fade, fadeDuration)
        return { success = false, reason = 'settle_timeout' }
    end

    local finalCoords = GetEntityCoords(entity)
    teleporting = false
    activeEntity = nil
    if fade then fadeIn(fadeDuration) end
    return { success = true, coords = finalCoords, heading = heading,
        surface = surfaceType, settled = true }
end

function TeleportAPI:ToWaypoint(options)
    if not IsWaypointActive() then return { success = false, reason = 'no_waypoint' } end
    options = type(options) == 'table' and options or {}
    options.mode = 'surface'
    return self:ToCoords(GetWaypointCoords(), options)
end

-- Narrow cross-resource contract for safe, streamed coordinate placement.
exports('TeleportToCoords', function(coords, options)
    return TeleportAPI:ToCoords(coords, options)
end)

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end
    if activeEntity and DoesEntityExist(activeEntity) then FreezeEntityPosition(activeEntity, false) end
    activeEntity = nil
    teleporting = false
    fadeIn(0)
end)
