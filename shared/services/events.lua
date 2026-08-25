-- Polls RedM's native game-event queue (GET_EVENT_AT_INDEX/GET_EVENT_DATA)
-- every tick and dispatches to whichever Lua callbacks have registered for
-- that event via EventsAPI:RegisterEventListener -- this is how the
-- framework observes native engine events (e.g. entity damage) that don't
-- have a CFX AddEventHandler equivalent. Two independent event groups are
-- polled: 0 = entity/client-side events, 1 = network events (see
-- StartGlobalEventListeners below). Only runs at all while
-- EventListenerCount > 0 or dev mode is on, to avoid an always-on Wait(0)
-- loop doing native calls for nothing.
EventsAPI = {}
EventListeners = {}
EventListenerCount = 0
EventsDevMode = {
	false,
	false
}

--? These functions are for DataView memory allocation
local function pullData(event, eventDataStruct) -- Memory address pull
    local datafields = {}

    for p = 0, event.datasize - 1, 1 do
        local current_data_element = event.dataelements[p]
        if current_data_element and current_data_element.type == 'float' then
            datafields[#datafields + 1] = eventDataStruct:GetFloat32(8 * p) 
        else
            --? Defaults to int
            datafields[#datafields + 1] = eventDataStruct:GetInt32(8 * p) 
        end
    end

    return datafields
end

local function allocateData(event, eventDataStruct) --memory pre-allocation
    for p = 0, event.datasize - 1, 1 do
        local current_data_element = event.dataelements[p]
        if current_data_element and current_data_element.type == 'float' then
            eventDataStruct:SetFloat32(8 * p, 0)
        else
            --? Defaults to int
            eventDataStruct:SetInt32(8 * p, 0)
        end
    end
end

--? Global event listener
local function startGlobalEventListeners(eventgroup)
	-- Inspired by https://github.com/femga/rdr3_discoveries/tree/master/AI/EVENTS
	CreateThread(function()
		while true do
			Wait(0)
            local eventmode = eventgroup + 1
			if EventListenerCount > 0 or EventsDevMode[eventmode] == true then
				local size = GetNumberOfEvents(eventgroup)
				if size > 0 then
					for i = 0, size - 1 do
						local eventAtIndex = GetEventAtIndex(eventgroup, i)
						if EVENTS[eventAtIndex] then
							local eventDataStruct = DataView.ArrayBuffer(8*EVENTS[eventAtIndex].datasize) --memory heap reservation


							allocateData(EVENTS[eventAtIndex], eventDataStruct)

							local is_data_exists = Citizen.InvokeNative(0x57EC5FA4D4D6AFCA, eventgroup, i, eventDataStruct:Buffer(),
								EVENTS[eventAtIndex].datasize) -- GET_EVENT_DATA

							local datafields = {}
							if is_data_exists then
                                datafields = pullData(EVENTS[eventAtIndex], eventDataStruct)
							end

                            if EventsDevMode[eventmode] == true then
								DebugLog("EVENT TRIGGERED:", EVENTS[eventAtIndex].name, datafields)
							end
          
                            local bucket = EventListeners[eventAtIndex]
                            if bucket then
                                for _, event in pairs(bucket.listeners) do
                                    local ok, err = pcall(event.trigger, datafields)
                                    if not ok then
                                        print(('[feather-core] Event listener failed for %s: %s'):format(
                                            tostring(event.eventname), tostring(err)))
                                    end
                                end
							end
						end
					end
				end
			end
		end
	end)
end

function StartGlobalEventListeners()
	startGlobalEventListeners(0) -- 0 = Client Side Events
	startGlobalEventListeners(1) -- 1 = Network Events
end

--? Register events to be listened for
function EventsAPI:RegisterEventListener(eventname, cb)
	if type(eventname) ~= 'string' or not IsCallable(cb) then return nil end
	local key = GetHashKey(eventname)
	local bucket = EventListeners[key]
	if not bucket then
		bucket = { nextId = 0, listeners = {} }
		EventListeners[key] = bucket
	end
	bucket.nextId = bucket.nextId + 1
	local position = bucket.nextId
	local owner = GetInvokingResource and GetInvokingResource() or nil
	if type(owner) ~= 'string' or owner == '' then owner = GetCurrentResourceName() end
	bucket.listeners[position] = {
		eventname = eventname,
		trigger = cb,
		owner = owner
	}
    EventListenerCount = EventListenerCount + 1

	print("EventListener Registered", eventname);
	return { key, position }
end

-- remove event listeners is best practice for memory management. however, this only applies if you are creating temporary listeners.
function EventsAPI:RemoveEventListener(listener)
	if type(listener) ~= 'table' then return false end
	local bucket, id = EventListeners[listener[1]], listener[2]
	if not bucket or id == nil or bucket.listeners[id] == nil then return false end

	bucket.listeners[id] = nil
    EventListenerCount = math.max(0, EventListenerCount - 1)
	if next(bucket.listeners) == nil then EventListeners[listener[1]] = nil end
	return true
end

if not IsOnServer() then
	AddEventHandler('onClientResourceStop', function(resourceName)
		for eventHash, bucket in pairs(EventListeners) do
			for id, listener in pairs(bucket.listeners) do
				if listener.owner == resourceName then
					bucket.listeners[id] = nil
					EventListenerCount = math.max(0, EventListenerCount - 1)
				end
			end
			if next(bucket.listeners) == nil then EventListeners[eventHash] = nil end
		end
	end)
end

-- (Tier 1 audit sweep) The poll loop above reads `EventsDevMode[eventgroup + 1]`
-- (Lua's 1-based indexing on a `{false, false}` literal, which occupies
-- slots 1 and 2, never 0) -- this wrote to `EventsDevMode[0]`/`[1]` instead
-- of `[1]`/`[2]`, so `DevMode('entities')` set a slot nothing ever reads,
-- and `DevMode('network')` set the slot the loop actually reads for
-- *entities* (eventgroup 0 -> index 1). Network logging could never be
-- enabled, and "entities" logging was silently controlled by the
-- 'network' call instead of its own.
function EventsAPI:DevMode(state, type)
	if type == 'entities' then
		EventsDevMode[1] = state
	elseif type == 'network' then
		EventsDevMode[2] = state
	else
		EventsDevMode[1] = state
		EventsDevMode[2] = state
	end
end
