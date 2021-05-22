local Logger = require("modules/logger").create("Control")

function run_tests()
    local testRunner = require("tests/main")
    script.on_event(defines.events.on_tick, function(e)
        testRunner()
        script.on_event(defines.events.on_tick, nil)
    end)
end
if settings.startup["DedLib_run_tests"].value then
    Logger.trace("Attempting to run tests")
    local status, err = pcall(run_tests)
    if not status then
        Logger.error("Failed to run tests: %s", err)
    end
end
