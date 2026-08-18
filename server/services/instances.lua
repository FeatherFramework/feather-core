-- Thin wrapper over RedM's native routing buckets: a player's routing
-- bucket determines which other entities/players they can see and interact
-- with (everyone in bucket 0, the default, sees each other; a player moved
-- to bucket N is isolated from bucket 0 and from every other bucket).
-- GameInstances just tracks which src's are currently registered to which
-- bucket id so leave()/cleanup know who's still in an instance.
GameInstances = {}

InstanceAPI = {}

--An instanced math is used to keep track of prior instance ID's and prevent collision
local MathInstance = MathI:instanced()


-- Moves `tsrc` (or the caller, if omitted) into routing bucket `id`,
-- creating a fresh randomly-generated bucket id if `id` is nil. Also
-- migrates the player out of whatever instance they were previously
-- registered to, since a player can only be routed to one bucket at a time.
function InstanceAPI.create(id, tsrc)
    local src = source
    if tsrc ~= nil then
        src = tsrc
    end

    -- Check to see if the player is already in a registered instance.
    for key, value in pairs(GameInstances) do
        if value.characters[src] then
            DebugLog('Migrating user from instance ', key, ' to instance', id)

            --Remove character from old instance
            GameInstances[key].characters[src] = nil
        end
    end

    if not GameInstances[id] then
        -- Instance not found, create a new one
        --Generate an instance ID if one was not provided
        if id == nil then
            id = MathInstance:GetRandomInt()
        end

        -- (CORE-19) Was `{ characters = { src = src } }` -- a table literal
        -- with a field literally named "src", not `characters[src] = src`.
        -- Every instance's membership table was therefore keyed on the
        -- string "src" instead of the player's actual src, so lookups like
        -- `GameInstances[id].characters[someSrc]` never matched the
        -- creator -- membership tracking was broken from creation.
        GameInstances[id] = {
            characters = {
                [src] = src
            }
        }
    elseif GameInstances[id] and not GameInstances[id].characters[src] then
        -- If the instance exists, and the player is not already within the instance, add them
        GameInstances[id].characters[src] = src
    end



    SetPlayerRoutingBucket(
        src,
        id
    )

    -- Trigger Client Event for the isntanced player and send the ID
    TriggerClientEvent('Feather:Instance:Created', src, id)
    return id
end

-- Removes `tsrc` (or the caller) from instance `id` and routes them back to
-- the global bucket (0). Deletes the instance entirely once it has no
-- players left registered to it.
function InstanceAPI.leave(id, tsrc)
    local src = source
    if tsrc ~= nil then
        src = tsrc
    end

    -- If character is registered to the instance, remove them.
    if GameInstances[id] and GameInstances[id].characters[src] then
        GameInstances[id].characters[src] = nil
    end

    -- (CORE-19) `#GameInstances[id].characters` used the length operator on
    -- a table keyed by player src -- sparse, non-sequential integer keys,
    -- which `#` has no defined behavior for. Count entries explicitly
    -- instead.
    if GameInstances[id] then
        local remaining = 0
        for _ in pairs(GameInstances[id].characters) do
            remaining = remaining + 1
        end
        if remaining <= 0 then
            GameInstances[id] = nil
            MathInstance:ReleaseInt(id)
        end
    end

    -- Set the character back to the global instance (0).
    SetPlayerRoutingBucket(
        src,
        0
    )

    -- Trigger Client Event for the isntanced player and send the
    TriggerClientEvent('Feather:Instance:Leave', src, 0)
end

-- Returns a list of all characters in a given instance
function InstanceAPI.getInstanceCharacters(id)
    if not GameInstances[id] then
        print("Game instance does not exist")

        return {}
    end

    return GameInstances[id].characters
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

RPCAPI.Register("LeaveInstance", function(params, res, player)
    InstanceAPI.leave(params.id, player)
    return res()
end)

-- (CORE-19) Was referencing the undefined global `id` instead of `params.id`
-- -- always operated on nil and never actually worked.
RPCAPI.Register("GetInstancedCharacters", function(params, res, player)
    local instances = InstanceAPI.getInstanceCharacters(params.id)
    return res(instances)
end)
