data:extend({
	-- Startup settings
	{
		name = "DedLib_logger_level_console",
		type = "string-setting",
		setting_type = "runtime-global",
		default_value = "off",
		allowed_values = {"off", "fatal", "error", "warn", "info", "debug", "trace"},
		order = "900"
	},
	{
		name = "DedLib_logger_level_file",
		type = "string-setting",
		setting_type = "startup",
		default_value = "error",
		allowed_values = {"off", "fatal", "error", "warn", "info", "debug", "trace"},
		order = "910"
	},

	{
		name = "DedLib_run_tests",
		type = "bool-setting",
		setting_type = "startup",
		default_value = false,
		order = "999"
	}
})
