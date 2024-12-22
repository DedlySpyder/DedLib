data:extend({
	-- Startup settings
	{
		name = "DedLib_logger_level_file",
		type = "string-setting",
		setting_type = "startup",
		default_value = "error",
		allowed_values = {"off", "fatal", "error", "warn", "info", "debug", "trace"},
		order = "910"
	},

	-- Runtime settings
	{
		name = "DedLib_tester_game_speed",
		type = "double-setting",
		setting_type = "runtime-global",
		default_value = 5,
		minimum_value = 0.01,
		order = "800"
	},
	{
		name = "DedLib_logger_level_console",
		type = "string-setting",
		setting_type = "runtime-global",
		default_value = "off",
		allowed_values = {"off", "fatal", "error", "warn", "info", "debug", "trace"},
		order = "900"
	}
})
