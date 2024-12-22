local Logger = require("__DedLib__/modules/logger").create()
local Table = require("__DedLib__/modules/table")

local Events = {}
Events._IDS_TO_NAMES = Table.swap_key_values(defines.events)
Events._REGISTRY = {}

Events._ROOT_EVENT_REGISTER = {crash_dump = false}
Events._ROOT_EVENT_REGISTER.__index = Events._ROOT_EVENT_REGISTER


-- TODO - events - automatically add other module on_init to the Events on_init (in case the other mods use both)


function Events.set_up_root_crash_dump(crashDump)
    if type(crashDump) == "function" then
        Logger:debug("Setting root crash dump")
        Events._ROOT_EVENT_REGISTER.crash_dump = crashDump
    elseif not crashDump then
        Events._ROOT_EVENT_REGISTER.crash_dump = false
    else
        Logger:error("Failed to set up root crash dump, function, nil, or false expected, received: %s", crashDump)
    end
end

-- nil handler will clear the entire event
-- options is a table that can contain any of the following:
--  tick - required for on_nth_tick
--  filters - optional - all filters for a single event are naively joined together (for complex filters for multiple events it may be better to set them in Events.____ TODO********)
function Events.register(eventNameOrId, handler, options) -- TODO add - options.crash_dump
    local eventName, eventId = Events.get_event_id_and_name(eventNameOrId)
    Logger:debug("Registering event handler for %s, id %s", eventName, eventId)

    if eventName == "on_nth_tick" then
        Events.register_on_nth_tick(handler, options.tick, options.crash_dump)
        return
    end

    if handler == nil then
        Logger:debug("Handler is nil, so clearing handlers for %s", eventName)
        Events.deregister(eventName)
        return
    end

    if type(handler) ~= "function" then
        Logger:error("Failed to add handler %s for event %s", handler, eventName)
        return
    end

    Events._add_to_registry(eventName, eventId, handler, options.filters, options.crash_dump)
    Events._register_with_script(eventId, eventName, Events._root_callback(eventName))
end

function Events.set_filters(eventName, filters) -- TODO - need a set filters for eventName, to just handle it explicitly instead of the ehhhhhhh implicit one
end

function Events.register_on_nth_tick(handler, tick, crashDump)
    local tickIsValid = Events._is_valid_tick(tick)
    if handler == nil then
        if tick then
            if tickIsValid then
                Logger:debug("Handler is nil, so clearing handlers for on_nth_tick %s", tick)
                script.on_nth_tick(tick)
            else
                Logger:error("Handler is nil, tick is invalid, expected number, list of numbers, or nil, received: %s", tick)
            end
        else
            Logger:debug("Handler is nil, and tick is nil, so clearing ALL tick handlers for on_nth_tick")
            script.on_nth_tick()
        end
        return
    end

    if type(handler) ~= "function" then
        Logger:error("Failed to add handler %s for event on_nth_tick %s", handler, tick)
        return
    end

    if not tickIsValid then
        Logger:error("Failed to register on_nth_tick with invalid tick: %s", tick)
        return
    end

    Logger:debug("Registering on_nth_tick handler for tick %s", tick)
    local eventName = "on_nth_tick_" .. tick
    Events._add_to_registry(eventName, nil, handler, nil, crashDump)
    script.on_nth_tick(tick, Events._root_callback(eventName))
end

function Events.deregister(eventNameOrId, tick)
    local eventName, eventId = Events.get_event_id_and_name(eventNameOrId)
    Logger:debug("De-registering event handlers for %s, id %s", eventName, eventId)

    if eventName == "on_nth_tick" then
        Events.register_on_nth_tick(nil, tick)
        return
    end

    Events._REGISTRY[eventName] = nil
    Events._register_with_script(eventId, eventName, nil)
end

function Events.get_event_id_and_name(eventNameOrId)
    if type(eventNameOrId) == "string" then
        -- Given a Name
        return eventNameOrId, defines.events[eventNameOrId]
    else
        -- Given an ID
        return Events._IDS_TO_NAMES[eventNameOrId], eventNameOrId
    end
end



function Events._add_to_registry(eventName, eventId, handler, filters, crashDump)
    local register = Events._REGISTRY[eventName]
    if not register then
        register = {handlers = {}, filters = {}, id = eventId}
        setmetatable(register, Events._ROOT_EVENT_REGISTER)
        Events._REGISTRY[eventName] = register
    end

    local newHandler = {func = handler}
    table.insert(register.handlers, newHandler)
    if filters and type(filters) == "table" and #filters > 0 then
        Logger:trace("Adding filters for %s: %s", eventName, filters)
        for _, filter in ipairs(filters) do
            table.insert(register.filters, filter)
        end
    end

    if crashDump ~= nil and type(crashDump) ~= "function" then
        Logger:error("Failed to add crash dump to %s, expected function, received: %s", eventName, crashDump)
        return
    end
    newHandler.crash_dump = crashDump
end

function Events._register_with_script(eventId, eventName, callBack)
    if eventId then
        -- Normal event
        script.on_event(eventId, callBack, Events._REGISTRY[eventName].filters)
    else
        -- Non-Standard Event (i.e. on_init)
        script[eventName] = callBack
    end
end

function Events._is_valid_tick(tick)
    local tickType = type(tick)
    return tickType == "number" or (tickType == "table" and #tick > 0 and type(tick[1]) == "number")
end

function Events._root_callback(eventName)
    local register = Events._REGISTRY[eventName]
    local hasCrashDumps = Events._register_has_crash_dumps(register)

    if hasCrashDumps then
        local failureCallback = function()
            --TODO - return debug info about the crash, so I can rethrow (it will end up in "err")
        end
        return function(event)
            for _, handler in register.handlers do
                local status, err = xpcall(function() handler.func(event) end, failureCallback) --TODO - perf? - build extra func and call it for EVERY event sounds bad
                if not status then
                    Logger:fatal("Fatal error when processing handler for event %s", eventName)
                    local crashDump = handler.crash_dump
                    if crashDump then
                        Logger:debug("Found crash_dump for handler, running now...")
                        local s, e = pcall(crashDump)
                        if not s then
                            Logger:fatal("Crash_dump failed with error: %s", e)
                        end
                    end
                end
            end
        end
    else
        return function(event)
            for _, handler in register.handlers do
                handler.func(event)
            end
        end
    end
end

function Events._register_has_crash_dumps(register)
    for _, handler in pairs(register.handlers) do
        if handler.crash_dump then return true end
    end
    return false
end


return Events