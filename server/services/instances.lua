GameInstances = {}

InstanceAPI = {}

--An instanced math is used to keep track of prior instance ID's and prevent collision
local MathInstance = MathI:instanced()


-- Create an instance for a given player/src
function InstanceAPI.create(id)
    local src = source

    -- Check to see if the player is already in a registered instance.
    for key, value in pairs(GameInstances) do
        if value.characters[src] then
            print('Migrating user from instance ', key, ' to instance', id)

            --Remove character from old instance
            GameInstances[key].characters[src] = nil
        end
    end

    if not GameInstances[id] then
        -- Instance not found, create a new one
         --Generate an instance ID if one was not provided
        if id == nil then
            id = MathInstance:GetRandomInt(0)
        end

        GameInstances[id] = {
            characters = {
                src = src
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

    return instanceID
end

function InstanceAPI.leave(id)
    local src = source

    -- If character is registered to the instance, remove them.
    if GameInstances[id] and GameInstances[id].characters[src] then
        GameInstances[id].characters[src] = nil
    end
    
    -- If the instance has no more characters registered, then remove the instance.
    if GameInstances[id] and #GameInstances[id].characters <= 0 then
        GameInstances[id] = nil
    else
        id = 0
    end

    -- Set the character back to the global instance (0).
    SetPlayerRoutingBucket(
        src,
        0
    )
end

-- Returns a list of all characters in a given instance
function InstanceAPI.getInstanceCharacters(id)
    if not GameInstances[id] then
        print("Game instance does not exist")
        
        return {}
    end

    return GameInstances[id].characters
end