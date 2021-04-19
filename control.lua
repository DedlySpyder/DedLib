-- TODO - info description & does it need base?

local LOGGER = require("modules/logger")


if settings.startup["DedLib_run_tests"].value then
    local testRunner = require("tests/main")
    script.on_event(defines.events.on_tick, function(e)
        testRunner()
        script.on_event(defines.events.on_tick, nil)
    end)
end

remote.add_interface("DedLib", { --TODO - just requiring the files directly, these aren't needed
    logger = function(modName, prefix)
        return LOGGER.create(modName, prefix)
    end
})
