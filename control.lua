local LoggerInternal = require("internal/logger")
script.on_init(LoggerInternal.on_init)
script.on_event(defines.events.on_runtime_mod_setting_changed, LoggerInternal.on_runtime_mod_setting_changed)
