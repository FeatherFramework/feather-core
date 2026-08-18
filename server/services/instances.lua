-- Thin wrapper over RedM's native routing buckets: a player's routing
-- bucket determines which other entities/players they can see and interact
-- with (everyone in bucket 0, the default, sees each other; a player moved
-- to bucket N is isolated from bucket 0 and from every other bucket).
-- GameInstances tracks which src's are currently registered to which bucket
-- id; PlayerInstances is the reverse index (src -> instance id) that makes
-- lookups/leaves/disconnect-cleanup authoritative instead of trusting
-- whatever the client claims its current instance is.
GameInstances = {}
PlayerInstances = {}

InstanceAPI = {}

--An instanced math is used to keep track of prior instance ID's and prevent collision
local MathInstance = MathI:instanced()

-- Removes src from whatever instance PlayerInstances says it's actually in
-- (not whatever a caller claims) and tears the instance down once empty,
-- releasing its id back to the pool.
local function removePlayerFromInstance(src)
    local instanceId = PlayerInstances[src]
    if not instanceId then return end

    local instance = GameInstances[instanceId]
    if instance then
        instance.characters[src] = nil

        if next(instance.characters) == nil then
            GameInstances[instanceId] = nil
            MathInstance:ReleaseInt(instanceId)
        end
    end

    PlayerInstances[src] = nil
end

-- Moves `targetSource` (or the caller, if omitted) into routing bucket `id`,
-- creating a fresh randomly-generated bucket id if `id` is nil. Also
-- migrates the player out of whatever instance they were previously
-- registered to (via the reverse index, not a scan), since a player can
-- only be routed to one bucket at a time.
function InstanceAPI.create(id, targetSource)
    local src = tonumber(targetSource) or source
    if not src or src < 1 then return nil end

    removePlayerFromInstance(src)

    id = tonumber(id)
    if not id then
        id = MathInstance:GetRandomInt()
    end

    local instance = GameInstances[id]
    if not instance then
        instance = {
            characters = {}
        }
        GameInstances[id] = instance
    end

    instance.characters[src] = true
    PlayerInstances[src] = id

    SetPlayerRoutingBucket(src, id)

    -- Trigger Client Event for the isntanced player and send the ID
    TriggerClientEvent('Feather:Instance:Created', src, id)
    return id
end

-- Removes `targetSource` (or the caller) from whatever instance they're
-- actually registered to -- looked up authoritatively via PlayerInstances,
-- never trusted from a caller-supplied instance id -- and routes them back
-- to the global bucket (0).
function InstanceAPI.leave(targetSource)
    local src = tonumber(targetSource) or source
    if not src or src < 1 then return false end

    removePlayerFromInstance(src)

    -- Set the character back to the global instance (0).
    SetPlayerRoutingBucket(src, 0)

    -- Trigger Client Event for the isntanced player and send the
    TriggerClientEvent('Feather:Instance:Leave', src, 0)
    return true
end

-- Returns the raw internal membership table for a given instance. Not
-- exposed to clients directly (see the GetInstancedCharacters RPC below) --
-- intended for trusted server-side resources (e.g. feather-admin, after its
-- own permission check) calling this export directly.
function InstanceAPI.getInstanceCharacters(id)
    id = tonumber(id)
    local instance = id and GameInstances[id]
    return instance and instance.characters or {}
end

function InstanceAPI.getPlayerInstance(src)
    return PlayerInstances[tonumber(src)]
end

-- Public, RPC-safe view of an instance's roster: a plain sorted array of
-- src ids, not the internal membership table (which uses src as both key
-- and a `true` sentinel value -- an implementation detail callers shouldn't
-- see or be able to hold a reference into).
local function publicRoster(instanceId)
    local roster = {}

    for src in pairs(InstanceAPI.getInstanceCharacters(instanceId)) do
        roster[#roster + 1] = src
    end

    table.sort(roster)
    return roster
end

-- Client-callable entry points for the API above.
-- (CORE-03) `params.id` used to be honored verbatim -- any client could
-- request any existing bucket id and join an instance meant to isolate
-- someone else. Only ids in Config.PublicInstanceIds may be requested by
-- number now; anything else silently falls back to a fresh, private,
-- randomly-generated bucket (InstanceAPI.create with id = nil), same as if
-- the caller hadn't requested a specific id at all.
RPCAPI.Register("CreateInstance", function(params, res, player)
    local requestedId = params.id
    if requestedId ~= nil and not (Config.PublicInstanceIds and Config.PublicInstanceIds[requestedId]) then
        DebugLog(("[feather-core] CreateInstance: src %s requested non-public instance %s, issuing a private one instead"):format(player, tostring(requestedId)))
        requestedId = nil
    end
    local id = InstanceAPI.create(requestedId, player)
    return res(id)
end)

-- (CORE-19 follow-up) Used to take a client-supplied instance id and leave
-- *that* instance regardless of whether the caller was actually in it.
-- Now only ever leaves whatever instance PlayerInstances says this src is
-- actually registered to -- there's no longer an id for the client to lie
-- about.
RPCAPI.Register("LeaveInstance", function(_, res, player)
    InstanceAPI.leave(player)
    return res()
end)

-- (CORE-19 / info-disclosure follow-up) Was referencing the undefined
-- global `id` instead of `params.id`, so it always operated on nil and
-- returned {} -- but naively fixing that to `params.id` without adding
-- authorization would let any client query any instance's full roster by
-- id (a private instance's membership is meant to be isolated from anyone
-- not routed into it). Now only returns a roster when the caller is
-- asking about the instance it's actually currently in -- cross-checked
-- both against the framework's own PlayerInstances bookkeeping and the
-- real native routing bucket, so a desync between the two fails closed.
--
-- Deliberately not admin-gated as an alternative path: core has no way to
-- know which admin permission should justify an arbitrary instance lookup,
-- and a client has no legitimate reason to discover another instance's
-- roster at all. A trusted server resource (e.g. feather-admin, after its
-- own permission check) should call InstanceAPI.getInstanceCharacters(id)
-- directly rather than going through this RPC.
RPCAPI.Register("GetInstancedCharacters", function(params, res, player)
    if type(params) ~= 'table' then
        return res({})
    end

    local requestedId = tonumber(params.id)
    local currentId = InstanceAPI.getPlayerInstance(player)

    if not requestedId
        or requestedId ~= currentId
        or GetPlayerRoutingBucket(player) ~= currentId then
        return res({})
    end

    return res(publicRoster(currentId))
end)

AddEventHandler('playerDropped', function()
    removePlayerFromInstance(source)
end)
