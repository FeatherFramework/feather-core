-- Polling-based key press listener system: RegisterListener attaches a
-- callback to a key name (from shared/data/keys.lua's `Keys` table);
-- StartKeyListeners() polls every registered key every 4ms via the native
-- IS_DISABLED_CONTROL_JUST_PRESSED-style check and fires callbacks for
-- whichever keys were pressed since the last tick. Only polls at all while
-- KeyListenerCount > 0, to skip the native calls otherwise.
KeyPressAPI = {}

KeyListeners = {}
KeyListenerCount = 0

function KeyPressAPI.whenKeyJustPressed(key)
    if Citizen.InvokeNative(0x580417101DDB492F, 0, key) then
        return true
    else
        return false
    end
end

function StartKeyListeners()
    CreateThread(function()
        while true do
            Wait(4)
            if KeyListenerCount > 0 then
                for key, bucket in pairs(KeyListeners) do
                    local keycode = Keys[key]
                    if Citizen.InvokeNative(0x580417101DDB492F, 0, keycode) then
                        for _, event in pairs(bucket.listeners) do
                            local ok, err = pcall(event.trigger)
                            if not ok then
                                print(('[feather-core] Key listener failed for %s: %s'):format(tostring(key), tostring(err)))
                            end
                        end
                    end
                end
            end
        end
    end)
end

--? Register events to be listened for
function KeyPressAPI:RegisterListener(keycode, cb)
    if not IsCallable(cb) or Keys[keycode] == nil then return nil end

    local bucket = KeyListeners[keycode]
    if not bucket then
        bucket = { nextId = 0, listeners = {} }
        KeyListeners[keycode] = bucket
    end
    bucket.nextId = bucket.nextId + 1
    local position = bucket.nextId
    local owner = GetInvokingResource and GetInvokingResource() or nil
    if type(owner) ~= 'string' or owner == '' then owner = GetCurrentResourceName() end
    bucket.listeners[position] = {
        trigger = cb,
        owner = owner
    }
    KeyListenerCount = KeyListenerCount + 1

    if Config.DevMode then
        print("KeyPressListener Registered", keycode);
    end

    local keyClass = {}

    keyClass.position = position
    keyClass.keycode = keycode

    function keyClass:RemoveListener()
        KeyPressAPI:RemoveListener({ self.keycode, self.position })
    end

    return keyClass
end

-- remove event listeners is best practice for memory management. however, this only applies if you are creating temporary listeners.
function KeyPressAPI:RemoveListener(listener)
    if type(listener) ~= 'table' then return false end
    local bucket, id = KeyListeners[listener[1]], listener[2]
    if not bucket or id == nil or bucket.listeners[id] == nil then return false end

    bucket.listeners[id] = nil
    KeyListenerCount = math.max(0, KeyListenerCount - 1)
    if next(bucket.listeners) == nil then KeyListeners[listener[1]] = nil end
    return true
end

AddEventHandler('onClientResourceStop', function(resourceName)
    for keycode, bucket in pairs(KeyListeners) do
        for id, listener in pairs(bucket.listeners) do
            if listener.owner == resourceName then
                bucket.listeners[id] = nil
                KeyListenerCount = math.max(0, KeyListenerCount - 1)
            end
        end
        if next(bucket.listeners) == nil then KeyListeners[keycode] = nil end
    end
end)
