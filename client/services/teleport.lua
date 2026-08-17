-- Shared client teleport mechanics. Calling resources remain responsible for
-- permissions, coordinate parsing, menu behavior, and user notifications.
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

local function findRaycastSurface(x, y, entity, options)
    local top = number(options.probeTop) or 1000.0
    local bottom = number(options.probeBottom) or -100.0
    local ray = StartShapeTestRay(x, y, top, x, y, bottom, -1, entity, 7)
    local deadline = GetGameTimer() + (number(options.surfaceTimeout) or 1000)

    while GetGameTimer() < deadline do
        local status, hit, hitCoords = GetShapeTestResult(ray)
        if status == 2 then
            return hit and hitCoords.z or nil
        end
        Wait(0)
    end
end

local function findGround(x, y, options)
    local top = math.floor(number(options.probeTop) or 1000)
    local bottom = math.floor(number(options.groundBottom) or 0)
    local step = math.max(1, math.floor(number(options.probeStep) or 25))

    RequestCollisionAtCoord(x, y, number(options.collisionZ) or top + 0.0)
    for height = top, bottom, -step do
        local found, groundZ = GetGroundZAndNormalFor_3dCoord(x, y, height + 0.0)
        if found then return groundZ end
        Wait(0)
    end
end

function TeleportAPI:IsBusy()
    return teleporting
end

function TeleportAPI:FindSurface(x, y, fallbackZ, options)
    options = type(options) == 'table' and options or {}
    x, y, fallbackZ = number(x), number(y), number(fallbackZ)
    if not x or not y then return nil end

    local entity = tonumber(options.entity) or PlayerPedId()
    RequestCollisionAtCoord(x, y, fallbackZ or number(options.probeTop) or 1000.0)

    local surfaceZ = findRaycastSurface(x, y, entity, options)
    if surfaceZ then return surfaceZ, 'surface' end

    local groundZ = findGround(x, y, options)
    if groundZ then return groundZ, 'ground' end

    if fallbackZ then return fallbackZ, 'fallback' end
    return nil
end

function TeleportAPI:ToCoords(coords, options)
    options = type(options) == 'table' and options or {}
    if teleporting then return { success = false, reason = 'busy' } end

    if coords == nil then return { success = false, reason = 'invalid_coordinates' } end

    local coordsType = type(coords)
    if coordsType ~= 'table' and coordsType ~= 'vector3' and coordsType ~= 'vector4' then
        return { success = false, reason = 'invalid_coordinates' }
    end

    local x, y, fallbackZ, coordinateHeading
    if coordsType == 'table' then
        x = number(coords.x or coords[1])
        y = number(coords.y or coords[2])
        fallbackZ = number(coords.z or coords[3])
        coordinateHeading = number(coords.w or coords.h or coords[4])
    else
        x, y, fallbackZ = number(coords.x), number(coords.y), number(coords.z)
        if coordsType == 'vector4' then coordinateHeading = number(coords.w) end
    end

    local heading = number(options.heading) or coordinateHeading
    if not x or not y or not fallbackZ then
        return { success = false, reason = 'invalid_coordinates' }
    end

    local entity = tonumber(options.entity) or PlayerPedId()
    if entity == 0 or not DoesEntityExist(entity) then
        return { success = false, reason = 'invalid_entity' }
    end
    local originalCoords = GetEntityCoords(entity)
    local originalHeading = GetEntityHeading(entity)

    teleporting = true
    local fade = options.fade ~= false
    local freeze = options.freeze ~= false
    activeEntity = freeze and entity or nil
    local fadeDuration = math.max(0, math.floor(number(options.fadeDuration) or 500))

    if fade and not waitForFadeOut(fadeDuration, math.max(fadeDuration, number(options.fadeTimeout) or 2000)) then
        teleporting = false
        activeEntity = nil
        fadeIn(fadeDuration)
        return { success = false, reason = 'fade_failed' }
    end

    if freeze then FreezeEntityPosition(entity, true) end

    -- Move into the destination streaming area before probing. Without this,
    -- terrain may load before dock, bridge, or building collision and place the
    -- entity on the surface underneath it.
    if options.streamDestination ~= false then
        local streamHeight = number(options.streamHeight) or 50.0
        SetEntityCoordsNoOffset(entity, x, y, fallbackZ + streamHeight, false, false, false)
        local streamStarted = GetGameTimer()
        local streamMinimum = math.max(0, number(options.streamMinimum) or 1000)
        local streamDeadline = streamStarted + (number(options.streamTimeout) or 1500)
        repeat
            RequestCollisionAtCoord(x, y, fallbackZ)
            Wait(0)
        until (GetGameTimer() - streamStarted >= streamMinimum and HasCollisionLoadedAroundEntity(entity))
            or GetGameTimer() >= streamDeadline
    end

    local destinationZ, surfaceType
    if options.findSurface == false then
        destinationZ, surfaceType = fallbackZ, 'coordinates'
    else
        destinationZ, surfaceType = self:FindSurface(x, y, fallbackZ, {
            entity = entity,
            probeTop = options.probeTop,
            probeBottom = options.probeBottom,
            groundBottom = options.groundBottom,
            probeStep = options.probeStep,
            surfaceTimeout = options.surfaceTimeout,
            collisionZ = fallbackZ
        })
    end

    if not destinationZ then
        if freeze then FreezeEntityPosition(entity, false) end
        teleporting = false
        activeEntity = nil
        if fade then fadeIn(fadeDuration) end
        return { success = false, reason = 'surface_not_found' }
    end

    destinationZ = destinationZ + (number(options.zOffset) or 0.0)
    -- SET_ENTITY_COORDS accounts for the entity's placement offset, which is
    -- safer for peds on uneven or sloped collision than an exact no-offset set.
    SetEntityCoords(entity, x, y, destinationZ, false, false, false, false)
    if heading then SetEntityHeading(entity, heading) end
    SetEntityVelocity(entity, 0.0, 0.0, 0.0)

    RequestCollisionAtCoord(x, y, destinationZ)
    local collisionDeadline = GetGameTimer() + (number(options.collisionTimeout) or 2000)
    while not HasCollisionLoadedAroundEntity(entity) and GetGameTimer() < collisionDeadline do Wait(0) end

    local collisionLoaded = HasCollisionLoadedAroundEntity(entity)
    if not collisionLoaded then
        SetEntityCoordsNoOffset(entity, originalCoords.x, originalCoords.y, originalCoords.z, false, false, false)
        SetEntityHeading(entity, originalHeading)
        SetEntityVelocity(entity, 0.0, 0.0, 0.0)
        RequestCollisionAtCoord(originalCoords.x, originalCoords.y, originalCoords.z)
        if freeze then FreezeEntityPosition(entity, false) end
        teleporting = false
        activeEntity = nil
        if fade then fadeIn(fadeDuration) end
        return { success = false, reason = 'collision_timeout' }
    end

    local settled = not freeze
    if freeze then
        FreezeEntityPosition(entity, false)

        -- Reveal only after physics and the camera have settled. Consecutive
        -- stable frames avoid relying on a fixed delay that varies by client.
        local settleStarted = GetGameTimer()
        local settleMinimum = math.max(0, number(options.settleMinimum) or 250)
        local settleDeadline = settleStarted + (number(options.settleTimeout) or 4000)
        local requiredStableFrames = math.max(1, math.floor(number(options.stableFrames) or 10))
        local speedTolerance = math.max(0.0, number(options.speedTolerance) or 0.05)
        local zTolerance = math.max(0.0, number(options.zTolerance) or 0.01)
        local stableFrames = 0
        local previousZ = GetEntityCoords(entity).z

        while GetGameTimer() < settleDeadline do
            RequestCollisionAtCoord(x, y, destinationZ)
            local currentZ = GetEntityCoords(entity).z
            local stable = GetGameTimer() - settleStarted >= settleMinimum
                and not IsEntityInAir(entity)
                and GetEntitySpeed(entity) <= speedTolerance
                and math.abs(currentZ - previousZ) <= zTolerance

            stableFrames = stable and stableFrames + 1 or 0
            previousZ = currentZ
            if stableFrames >= requiredStableFrames then
                settled = true
                break
            end
            Wait(0)
        end
    end

    local finalCoords = GetEntityCoords(entity)
    teleporting = false
    activeEntity = nil
    if fade then fadeIn(fadeDuration) end

    return {
        success = true,
        coords = finalCoords,
        heading = heading,
        surface = surfaceType,
        collisionLoaded = collisionLoaded,
        settled = settled
    }
end

function TeleportAPI:ToWaypoint(options)
    if not IsWaypointActive() then return { success = false, reason = 'no_waypoint' } end

    local waypoint = GetWaypointCoords()
    return self:ToCoords(waypoint, options)
end

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName ~= GetCurrentResourceName() then return end

    if activeEntity and DoesEntityExist(activeEntity) then FreezeEntityPosition(activeEntity, false) end
    activeEntity = nil
    teleporting = false
    fadeIn(0)
end)
