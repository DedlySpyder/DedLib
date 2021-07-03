local Logger = require("modules/logger")
local Assert = require("modules/testing/assert")

local LoggerTests = {}


-- Create Tests -- TODO - testing - test for mod_name default in data stage? (somehow?)
function LoggerTests.test_create_default()
    local log = Logger.create()

    Assert.assert_equals(script.mod_name, log.MOD_NAME, "Unexpected mod name")
    Assert.assert_equals("", log.PREFIX, "Unexpected prefix")
    Assert.assert_nil(log.CONSOLE_LOG_LEVEL, "Unexpected console log level")
    Assert.assert_nil(log.FILE_LOG_LEVEL, "Unexpected file log level")
    Assert.assert_nil(rawget(log, "HIGHEST_LOG_LEVEL"), "Unexpected highest log level")
    Assert.assert_nil(rawget(log, "fatal"), "Unexpected fatal log function")
end

function LoggerTests.test_create_set_mod_name()
    local log = Logger.create{modName = "MOD"}

    Assert.assert_equals("MOD", log.MOD_NAME, "Unexpected mod name")
    Assert.assert_equals("", log.PREFIX, "Unexpected prefix")
    Assert.assert_nil(log.CONSOLE_LOG_LEVEL, "Unexpected console log level")
    Assert.assert_nil(log.FILE_LOG_LEVEL, "Unexpected file log level")
    Assert.assert_nil(rawget(log, "HIGHEST_LOG_LEVEL"), "Unexpected highest log level")
    Assert.assert_nil(rawget(log, "fatal"), "Unexpected fatal log function")
end

function LoggerTests.test_create_set_prefix()
    local log = Logger.create{prefix = "PREFIX"}

    Assert.assert_equals(script.mod_name, log.MOD_NAME, "Unexpected mod name")
    Assert.assert_equals("[PREFIX]", log.PREFIX, "Unexpected prefix")
    Assert.assert_nil(log.CONSOLE_LOG_LEVEL, "Unexpected console log level")
    Assert.assert_nil(log.FILE_LOG_LEVEL, "Unexpected file log level")
    Assert.assert_nil(rawget(log, "HIGHEST_LOG_LEVEL"), "Unexpected highest log level")
    Assert.assert_nil(rawget(log, "fatal"), "Unexpected fatal log function")
end

function LoggerTests.test_create_set_prefix_no_table()
    local log = Logger.create("PREFIX_1")

    Assert.assert_equals(script.mod_name, log.MOD_NAME, "Unexpected mod name")
    Assert.assert_equals("[PREFIX_1]", log.PREFIX, "Unexpected prefix")
    Assert.assert_nil(log.CONSOLE_LOG_LEVEL, "Unexpected console log level")
    Assert.assert_nil(log.FILE_LOG_LEVEL, "Unexpected file log level")
    Assert.assert_nil(rawget(log, "HIGHEST_LOG_LEVEL"), "Unexpected highest log level")
    Assert.assert_nil(rawget(log, "fatal"), "Unexpected fatal log function")
end

function LoggerTests.test_create_set_console_log_level()
    local log = Logger.create{consoleLevelOverride = "warn"}

    Assert.assert_equals(script.mod_name, log.MOD_NAME, "Unexpected mod name")
    Assert.assert_equals("", log.PREFIX, "Unexpected prefix")
    Assert.assert_equals("warn", log.CONSOLE_LOG_LEVEL, "Unexpected console log level")
    Assert.assert_nil(log.FILE_LOG_LEVEL, "Unexpected file log level")
    Assert.assert_not_nil(rawget(log, "HIGHEST_LOG_LEVEL"), "Unexpected highest log level")
    Assert.assert_not_nil(rawget(log, "fatal"), "Unexpected fatal log function")
end

function LoggerTests.test_create_set_file_log_level()
    local log = Logger.create{fileLevelOverride = "warn"}

    Assert.assert_equals(script.mod_name, log.MOD_NAME, "Unexpected mod name")
    Assert.assert_equals("", log.PREFIX, "Unexpected prefix")
    Assert.assert_nil(log.CONSOLE_LOG_LEVEL, "Unexpected console log level")
    Assert.assert_equals("warn", log.FILE_LOG_LEVEL, "Unexpected file log level")
    Assert.assert_not_nil(rawget(log, "HIGHEST_LOG_LEVEL"), "Unexpected highest log level")
    Assert.assert_not_nil(rawget(log, "fatal"), "Unexpected fatal log function")
end

function LoggerTests.test_create_set_both_log_levels()
    local log = Logger.create{consoleLevelOverride = "warn", fileLevelOverride = "info"}

    Assert.assert_equals(script.mod_name, log.MOD_NAME, "Unexpected mod name")
    Assert.assert_equals("", log.PREFIX, "Unexpected prefix")
    Assert.assert_equals("warn", log.CONSOLE_LOG_LEVEL, "Unexpected console log level")
    Assert.assert_equals("info", log.FILE_LOG_LEVEL, "Unexpected file log level")
    Assert.assert_not_nil(rawget(log, "HIGHEST_LOG_LEVEL"), "Unexpected highest log level")
    Assert.assert_not_nil(rawget(log, "fatal"), "Unexpected fatal log function")
end

function LoggerTests.test_create_set_general_level_override()
    local log = Logger.create{levelOverride = "warn"}

    Assert.assert_equals(script.mod_name, log.MOD_NAME, "Unexpected mod name")
    Assert.assert_equals("", log.PREFIX, "Unexpected prefix")
    Assert.assert_equals("warn", log.CONSOLE_LOG_LEVEL, "Unexpected console log level")
    Assert.assert_equals("warn", log.FILE_LOG_LEVEL, "Unexpected file log level")
    Assert.assert_not_nil(rawget(log, "HIGHEST_LOG_LEVEL"), "Unexpected highest log level")
    Assert.assert_not_nil(rawget(log, "fatal"), "Unexpected fatal log function")
end


-- Get specific log level value tests
LoggerTests["test_get_console_log_level_value_override"] = {
    generateArgsFunc = function()
        -- Don't pick the root level for the test
        if Logger.ROOT_CONSOLE_LOG_LEVEL == "off" then
            return "fatal"
        else
            return "off"
        end
    end,
    func = function(override)
        local logger = Logger.create({consoleLevelOverride = override})
        local actual = logger:get_console_log_level_value()
        local expected = Logger.get_level_value(override)

        Assert.assert_equals(expected, actual)
    end
}

LoggerTests["test_get_console_log_level_value_root"] = {
    func = function()
        local logger = Logger.create()
        local actual = logger:get_console_log_level_value()
        local expected = Logger.get_level_value(Logger.ROOT_CONSOLE_LOG_LEVEL)

        Assert.assert_equals(expected, actual)
    end
}

LoggerTests["test_get_file_log_level_value_override"] = {
    generateArgsFunc = function()
        -- Don't pick the root level for the test
        if Logger.ROOT_FILE_LOG_LEVEL == "off" then
            return "info"
        else
            return "off"
        end
    end,
    func = function(override)
        local logger = Logger.create({fileLevelOverride = override})
        local actual = logger:get_file_log_level_value()
        local expected = Logger.get_level_value(override)

        Assert.assert_equals(expected, actual)
    end
}

LoggerTests["test_get_file_log_level_value_root"] = {
    func = function()
        local logger = Logger.create()
        local actual = logger:get_file_log_level_value()
        local expected = Logger.get_level_value(Logger.ROOT_FILE_LOG_LEVEL)

        Assert.assert_equals(expected, actual)
    end
}


-- Get level value tests
function LoggerTests.test_get_level_value_number()
    local test = 1
    local actual = Logger.get_level_value(test)
    local expected = 1

    Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_level_value_not_string()
    local test = {"info"}
    local actual = Logger.get_level_value(test)
    local expected = 0

    Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_level_value_not_real_log_level()
    local test = "fake_log_level"
    local actual = Logger.get_level_value(test)
    local expected = 0

    Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_level_value_off()
    local test = "off"
    local actual = Logger.get_level_value(test)
    local expected = 1

    Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_level_value_trace()
    local test = "trace"
    local actual = Logger.get_level_value(test)
    local expected = #Logger.ALL_LOG_LEVELS

    Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end


-- _log tests
local logLogger = Logger.create{modName = "ModName", prefix = "Prefix"}
local resetLogLogger = function()
    logLogger._LAST_MESSAGE = nil
    logLogger._SAME_MESSAGE_COUNT = nil
end

function LoggerTests.test__log_last_message()
    resetLogLogger()
    local message = "message"
    local formatArgs = { n = 0}

    local actualMessage
    local logFunc = function(m) actualMessage = m end
    logLogger:_log(logFunc, message, formatArgs, "LEVEL")
    local actual = logLogger._LAST_MESSAGE
    local startsWith = "[" .. game.tick .. "][ModName][Prefix]"
    local endsWith = "LEVEL - " .. message

    Assert.assert_starts_with(startsWith, actual, "Input failed: " .. serpent.line(message))
    Assert.assert_ends_with(endsWith, actual, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test__log_same_message_count()
    resetLogLogger()
    local message = "message"
    local formatArgs = { n = 0}

    local actualMessage
    local logFunc = function(m) actualMessage = m end
    logLogger:_log(logFunc, message, formatArgs, "LEVEL")
    Assert.assert_equals(0, logLogger._SAME_MESSAGE_COUNT, "Input failed: " .. serpent.line(message))
    logLogger:_log(logFunc, message, formatArgs, "LEVEL")
    Assert.assert_equals(1, logLogger._SAME_MESSAGE_COUNT, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test__log_duplicate_messages()
    resetLogLogger()
    local message = "dup_message"
    local formatArgs = { n = 0}

    local actualMessage
    local logFunc = function(m) actualMessage = m end
    logLogger:_log(logFunc, message, formatArgs, "LEVEL")
    local startsWith1 = "[" .. game.tick .. "][ModName][Prefix]"
    local endsWith1 = "LEVEL - " .. message

    Assert.assert_starts_with(startsWith1, actualMessage, "Input failed: " .. serpent.line(message))
    Assert.assert_ends_with(endsWith1, actualMessage, "Input failed: " .. serpent.line(message))

    logLogger:_log(logFunc, message, formatArgs, "LEVEL")
    local startsWith2 = "[" .. game.tick .. "-1][ModName][Prefix]"
    local endsWith2 = "LEVEL - " .. message

    Assert.assert_starts_with(startsWith2, actualMessage, "Input failed: " .. serpent.line(message))
    Assert.assert_ends_with(endsWith2, actualMessage, "Input failed: " .. serpent.line(message))
end


-- Format message tests -- no format string usage
local formatMessageLogger = Logger.create{modName = "ModName", prefix = "Prefix"}
function LoggerTests.test_format_message_with_count()
    local message = ""
    local formatArgs = {n = 0}
    local actual = formatMessageLogger:_format_message(message, formatArgs, "LEVEL", "foo")
    local startsWith = "[" .. game.tick .. "-foo][ModName][Prefix]"
    local endsWith = "LEVEL - " .. message

    Assert.assert_starts_with(startsWith, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
    Assert.assert_ends_with(endsWith, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
end

function LoggerTests.test_format_message_string()
    local message = "string_message"
    local formatArgs = {n = 0}
    local actual = formatMessageLogger:_format_message(message, formatArgs, "LEVEL", nil)
    local startsWith = "[" .. game.tick .. "][ModName][Prefix]"
    local endsWith = "LEVEL - " .. message

    Assert.assert_starts_with(startsWith, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
    Assert.assert_ends_with(endsWith, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
end

function LoggerTests.test_format_string_format_args()
    local message = "foo_%s"
    local formatArgs = {n = 1, "bar"}
    local actual = formatMessageLogger:_format_message(message, formatArgs, "LEVEL", nil)
    local startsWith = "[" .. game.tick .. "][ModName][Prefix]"
    local endsWith = "LEVEL - foo_bar"

    Assert.assert_starts_with(startsWith, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
    Assert.assert_ends_with(endsWith, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
end


-- Get tick tests (if running tests when game is established)
function LoggerTests.test_get_tick_in_game()
    local actual = Logger._get_tick_in_game()
    local expected = "[" .. game.tick .. "]"

    Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_tick_in_game_with_count()
    local test = "foo"
    local actual = Logger._get_tick_in_game(test)
    local expected = "[" .. game.tick .. "-" .. test .."]"

    Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end


-- Log level tests -- fully on
local fullyOnLogger = Logger.create({ modName = "ModName", prefix = "Prefix", levelOverride = Logger.ALL_LOG_LEVELS[#Logger.ALL_LOG_LEVELS]})
local fullyOnLoggerUpperLevel
fullyOnLogger._log = function(_, _, _, _, upperLevel) fullyOnLoggerUpperLevel = upperLevel end

function LoggerTests.test_log_level_fully_on_fatal()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:fatal("message")
    Assert.assert_equals("FATAL", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_error()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:error("message")
    Assert.assert_equals("ERROR", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_warn()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:warn("message")
    Assert.assert_equals("WARN", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_info()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:info("message")
    Assert.assert_equals("INFO", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_debug()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:debug("message")
    Assert.assert_equals("DEBUG", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_trace()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:trace("message")
    Assert.assert_equals("TRACE", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_fatal()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:fatal_block("message")
    Assert.assert_equals("FATAL", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_error()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:error_block("message")
    Assert.assert_equals("ERROR", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_warn()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:warn_block("message")
    Assert.assert_equals("WARN", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_info()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:info_block("message")
    Assert.assert_equals("INFO", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_debug()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:debug_block("message")
    Assert.assert_equals("DEBUG", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_trace()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:trace_block("message")
    Assert.assert_equals("TRACE", fullyOnLoggerUpperLevel)
end


-- Log level tests -- fully off
local fullyOffLogger = Logger.create({ modName = "ModName", prefix = "Prefix", levelOverride = Logger.ALL_LOG_LEVELS[1]})
local fullyOffLoggerUpperLevel
fullyOffLogger._log = function(_, _, _, _, upperLevel) fullyOffLoggerUpperLevel = upperLevel end

function LoggerTests.test_log_level_fully_off_fatal()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger:fatal("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_error()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger:error("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_warn()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger:warn("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_info()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger:info("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_debug()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger:debug("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_trace()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger:trace("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_fatal()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:fatal_block("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_error()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:error_block("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_warn()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:warn_block("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_info()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:info_block("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_debug()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:debug_block("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_trace()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger:trace_block("message")
    Assert.assert_equals(nil, fullyOffLoggerUpperLevel)
end


return LoggerTests
