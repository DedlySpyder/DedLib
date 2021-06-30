local Logger = require("modules/logger").create{modName = "DedLib", prefix = "CustomEvents_Test"}
local CustomEvents = require("modules/events/custom_events")
local Assert = require("modules/testing/assert")

local CustomEventsTests = {}


-- Register Event Tests
function CustomEventsTests.test_register_event()
    local eventName = "producing_event"
    local id = CustomEvents.Publishing.register_event(eventName)

    local eventKey = CustomEvents._mapping_key(script.mod_name, eventName)
    Assert.assert_contains_key(eventKey, CustomEvents.Publishing._ID_MAPPING, "Missing key in ephemeral event id cache")
    Assert.assert_contains_key(eventKey, remote.interfaces, "Missing key in remote")
    Assert.assert_contains_key("get_id", remote.interfaces[eventKey], "Missing get_id in remote event interface")
    Assert.assert_equals(id, remote.call(eventKey, "get_id"), "get_id returns wrong id")
end


-- Get Event Id Tests
local testGetEventId = nil
CustomEventsTests.test_get_event_id = {
    before = function()
        testGetEventId = CustomEvents.Publishing.register_event("get_event")
    end,
    func = function()
        local eventName = "get_event"
        local id = CustomEvents.Consuming._get_event_id(script.mod_name, eventName)

        Assert.assert_equals(testGetEventId, id, "Incorrect id from get event id")
    end
}

CustomEventsTests.test_get_event_id_doesnt_exist = {
    func = function()
        local eventName = "get_event_doesnt_exist"
        local id = CustomEvents.Consuming._get_event_id(script.mod_name, eventName)

        Assert.assert_nil(id, "Event id exists when it should not")
    end
}


-- Register Event Handler Tests
CustomEventsTests.test_register_handler = {
    before = function()
        CustomEvents.Publishing.register_event("consuming_event")
    end,
    func = function()
        local eventName = "consuming_event"

        local eventRan = false
        local id = CustomEvents.Consuming.register_handler(script.mod_name, eventName, function()
            eventRan = true
        end)

        Assert.assert_not_nil(id, "id from register_handler was nil")
        Assert.assert_not_nil(script.get_event_handler(id), "Registered event not found")
        script.raise_event(id, {})

        Assert.assert_true(eventRan, "Registered event did not run")
    end
}

CustomEventsTests.test_register_handler_not_yet_registered = {
    func = function()
        local eventName = "consuming_event_not_registered"

        local eventRan = false
        local id = CustomEvents.Consuming.register_handler(script.mod_name, eventName, function()
            eventRan = true
        end)

        Assert.assert_nil(id, "id returned from register_handler when it was not expected")
        Assert.assert_false(eventRan, "Registered event ran when it was not expected to")
    end
}


-- Raise Event Tests
CustomEventsTests.test_raise_event = {
    func = function()
        local eventName = "producing_event_raise"
        local id = CustomEvents.Publishing.register_event(eventName)

        local eventRan = false
        script.on_event(id, function()
            eventRan = true
        end)

        CustomEvents.Publishing.raise_event(eventName, {})

        Assert.assert_true(eventRan, "Raised event was not handled")
    end
}

CustomEventsTests.test_raise_event_nil_data = {
    func = function()
        local eventName = "producing_event_raise_nil_data"
        local id = CustomEvents.Publishing.register_event(eventName)

        local eventRan = false
        script.on_event(id, function()
            eventRan = true
        end)

        CustomEvents.Publishing.raise_event(eventName, nil)

        Assert.assert_true(eventRan, "Raised event was not handled")
    end
}


return CustomEventsTests