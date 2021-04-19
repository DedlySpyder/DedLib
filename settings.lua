data:extend({
	-- Startup settings
	{
		name = "DedLib_debug_level",
		type = "string-setting",
		setting_type = "startup",
		default_value = "warn",
		allowed_values = {"off", "fatal", "error", "warn", "info", "debug", "trace"},
		order = "900"
	},
	{
		name = "DedLib_debug_location",
		type = "string-setting",
		setting_type = "startup",
		default_value = "console",
		allowed_values = {"console", "file", "both"},
		order = "950"
	},

	{
		name = "DedLib_run_tests",
		type = "bool-setting",
		setting_type = "startup",
		default_value = false,
		order = "999"
	}
})
