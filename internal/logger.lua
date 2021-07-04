local Logger = require("modules/logger").create()
local CustomEvents = require("modules/events/custom_events")


local LoggerInternal = {}
LoggerInternal.LOG_LEVEL_CHANGED_EVENT = "RUNTIME_LOG_LEVEL_CHANGED"

CustomEvents.Publishing.register_event(LoggerInternal.LOG_LEVEL_CHANGED_EVENT)

function LoggerInternal.on_runtime_mod_setting_changed(event)
    local settingName = event.setting

    if settingName == "DedLib_logger_level_console" and settings and settings.global[settingName] then
        Logger:info("Console logger level changed, triggering event for root loggers...")
        CustomEvents.Publishing.raise_event(LoggerInternal.LOG_LEVEL_CHANGED_EVENT)
    end
end

function LoggerInternal.on_init()
    CustomEvents.Consuming.register_handler("DedLib", LoggerInternal.LOG_LEVEL_CHANGED_EVENT, function()
        Logger:info("Event triggered for console logger level changed, updating logger configuration...")
        Logger._configure_root_logger()
    end)
end


return LoggerInternal
