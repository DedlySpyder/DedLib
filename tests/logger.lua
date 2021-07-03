local Logger = require("modules/logger")
local Assert = require("modules/testing/assert")

local LoggerTests = {}


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
