local Logger = require("modules/logger").create()

local testRunner = require("tests/main")
function run_tests()
    script.on_event(defines.events.on_tick, function(e)
        testRunner()
        script.on_event(defines.events.on_tick, nil)
    end)
end
if settings.startup["DedLib_run_tests"].value then
    Logger:trace("Attempting to run tests")
    local status, err = pcall(run_tests)
    if not status then
        Logger:error("Failed to run tests: %s", err)
    end
end

local LoggerInternal = require("internal/logger")
script.on_init(LoggerInternal.on_init)
script.on_event(defines.events.on_runtime_mod_setting_changed, LoggerInternal.on_runtime_mod_setting_changed)
