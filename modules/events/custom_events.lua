local Logger = require("modules/logger").create{modName = "DedLib"}

--[[
This module is for producing or consuming custom events. Either side of this interaction can use this module, or both can.

Publishing Mod - The mod that will register the event with Factorio and trigger it for downstream mods
    1. Call `CustomEvents.Publishing.register_event(eventName)` to reserve an event id and set up the
        `remote.call("DedLibEvents_[mod_name]_[eventName]", "get_id")` interface which will return the event id.
    2. Call `CustomEvents.Publishing.raise_event(eventName, data)` with the same event to trigger events for listening mods

Example:
```
CustomEvents.Publishing.register_event("foo_event")
CustomEvents.Publishing.raise_event("foo_event", {bar = "baz"})
```


Consuming Mod - The mod(s) that will be handling the events fired from the Publishing Mod
    1. Call `CustomEvents.Consuming.register_handler(modName, eventName, handler)` with desired mod's name from `info.json`
        and eventName as set by it, with a function to handle the event.

Example (using same event from above):
```
CustomEvents.Consuming.register_handler("DedLib", "foo_event", function(event)
    -- Handle event here
end)
```
]]--
local CustomEvents = {}

function CustomEvents._mapping_key(modName, eventName)
    return "DedLibEvents_" .. tostring(modName) .. "_" .. tostring(eventName)
end


-- Publishing Methods
CustomEvents.Publishing = {}
CustomEvents.Publishing._ID_MAPPING = {}
function CustomEvents.Publishing.register_event(eventName)
    local key = CustomEvents._mapping_key(script.mod_name, eventName)
    local id = script.generate_event_name()

    Logger:info("Registering event id %s for event named %s", id, key)
    CustomEvents.Publishing._ID_MAPPING[key] = id
    remote.add_interface(key, {
        get_id = function() return id end
    })
    return id
end

function CustomEvents.Publishing.raise_event(eventName, data)
    if not data then data = {} end
    local key = CustomEvents._mapping_key(script.mod_name, eventName)
    local id = CustomEvents.Publishing._ID_MAPPING[key]

    if id then
        Logger:info("Raising event for id %s for event named %s", id, key)
        Logger:trace("Event data: %s", data)
        script.raise_event(id, data)
    else
        Logger:error("Event for id %s has not been registered yet, call CustomEvents.Publishing.register_event(...) first", id)
    end
end


-- Consuming Methods
CustomEvents.Consuming = {}
CustomEvents.Consuming._ID_MAPPING = {}
function CustomEvents.Consuming._get_event_id(modName, eventName)
    local key = CustomEvents._mapping_key(modName, eventName)
    local cachedId = CustomEvents.Consuming._ID_MAPPING[key]

    if cachedId == nil then
        if remote.interfaces[key] and remote.interfaces[key]["get_id"] then
            cachedId = remote.call(key, "get_id")
            CustomEvents.Consuming._ID_MAPPING[key] = cachedId
        else
            Logger:error("Event for %s is not registered", key)
        end
    end
    return cachedId
end

function CustomEvents.Consuming.register_handler(modName, eventName, handler)
    local key = CustomEvents._mapping_key(modName, eventName)
    local id = CustomEvents.Consuming._get_event_id(modName, eventName)

    if id ~= nil then
        Logger:info("Registering handler for event id %s for event named %s", id, key)
        script.on_event(id, handler)
        return id
    else
        Logger:error("Registering handler for event named %s failed, event does not exist", key)
    end
end


return CustomEvents