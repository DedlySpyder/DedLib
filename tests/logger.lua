local Logger = require("modules/logger")
local Tester = require("modules/tester")

local LoggerTests = {}


-- Get level value tests
function LoggerTests.test_get_level_value_number()
    local test = 1
    local actual = Logger.get_level_value(test)
    local expected = 1

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_level_value_not_string()
    local test = {"info"}
    local actual = Logger.get_level_value(test)
    local expected = 0

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_level_value_not_real_log_level()
    local test = "fake_log_level"
    local actual = Logger.get_level_value(test)
    local expected = 0

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_level_value_off()
    local test = "off"
    local actual = Logger.get_level_value(test)
    local expected = 1

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_level_value_trace()
    local test = "trace"
    local actual = Logger.get_level_value(test)
    local expected = #Logger.ALL_LOG_LEVELS

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end


-- Get tick tests (if running tests when game is established)
function LoggerTests.test_get_tick_in_game()
    local actual = Logger._get_tick_in_game()
    local expected = "[" .. game.tick .. "]"

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_get_tick_in_game_with_count()
    local test = "foo"
    local actual = Logger._get_tick_in_game(test)
    local expected = "[" .. game.tick .. "-" .. test .."]"

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end


-- Stringify & Stringify Args tests
function LoggerTests.test_stringify_int()
    local test = 42
    local actual = Logger._stringify(test)
    local expected = "42"

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_stringify_double()
    local test = 2.005
    local actual = Logger._stringify(test)
    local expected = "2.005"

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_stringify_string()
    local test = "valid_string"
    local actual = Logger._stringify(test)
    local expected = "valid_string"

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function LoggerTests.test_stringify_table()
    local test = { foo = "bar" }
    local actual = Logger._stringify(test, serpent.line)
    local expected = '{foo = "bar"}'

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end


-- Format message tests -- no format string usage
local formatMessageLogger = Logger.create{modName = "ModName", prefix = "Prefix"}
function LoggerTests.test_format_message_with_count()
    local message = ""
    local formatArgs = { n = 0}
    local actual = formatMessageLogger._format_message(message, formatArgs, "LEVEL", "foo")
    local expected = "[" .. game.tick .. "-foo][ModName][Prefix] LEVEL - " .. message

    Tester.assert_equals(expected, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
end

function LoggerTests.test_format_message_string()
    local message = "string_message"
    local formatArgs = { n = 0}
    local actual = formatMessageLogger._format_message(message, formatArgs, "LEVEL", nil)
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. message

    Tester.assert_equals(expected, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
end

function LoggerTests.test_format_string_format_args()
    local message = "foo_%s"
    local formatArgs = {n = 1, "bar"}
    local actual = formatMessageLogger._format_message(message, formatArgs, "LEVEL", nil)
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - foo_bar"

    Tester.assert_equals(expected, actual, "Input failed <" .. message .. "> with formatArgs: " .. serpent.line(formatArgs))
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
    logLogger._log(logFunc, message, formatArgs, "LEVEL")
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. message

    Tester.assert_equals(expected, logLogger._LAST_MESSAGE, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test__log_same_message_count()
    resetLogLogger()
    local message = "message"
    local formatArgs = { n = 0}

    local actualMessage
    local logFunc = function(m) actualMessage = m end
    logLogger._log(logFunc, message, formatArgs, "LEVEL")
    Tester.assert_equals(0, logLogger._SAME_MESSAGE_COUNT, "Input failed: " .. serpent.line(message))
    logLogger._log(logFunc, message, formatArgs, "LEVEL")
    Tester.assert_equals(1, logLogger._SAME_MESSAGE_COUNT, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test__log_duplicate_messages()
    resetLogLogger()
    local message = "dup_message"
    local formatArgs = { n = 0}

    local actualMessage
    local logFunc = function(m) actualMessage = m end
    logLogger._log(logFunc, message, formatArgs, "LEVEL")
    local expected1 = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. message
    Tester.assert_equals(expected1, actualMessage, "Input failed: " .. serpent.line(message))
    logLogger._log(logFunc, message, formatArgs, "LEVEL")
    local expected2 = "[" .. game.tick .. "-1][ModName][Prefix] LEVEL - " .. message
    Tester.assert_equals(expected2, actualMessage, "Input failed: " .. serpent.line(message))
end


-- Log level tests -- fully on
local fullyOnLogger = Logger.create({ modName = "ModName", prefix = "Prefix", levelOverride = Logger.ALL_LOG_LEVELS[#Logger.ALL_LOG_LEVELS]})
local fullyOnLoggerUpperLevel
fullyOnLogger._log = function(_, _, _, upperLevel) fullyOnLoggerUpperLevel = upperLevel end

function LoggerTests.test_log_level_fully_on_fatal()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.fatal("message")
    Tester.assert_equals("FATAL", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_error()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.error("message")
    Tester.assert_equals("ERROR", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_warn()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.warn("message")
    Tester.assert_equals("WARN", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_info()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.info("message")
    Tester.assert_equals("INFO", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_debug()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.debug("message")
    Tester.assert_equals("DEBUG", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_on_trace()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.trace("message")
    Tester.assert_equals("TRACE", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_fatal()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.fatal_block("message")
    Tester.assert_equals("FATAL", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_error()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.error_block("message")
    Tester.assert_equals("ERROR", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_warn()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.warn_block("message")
    Tester.assert_equals("WARN", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_info()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.info_block("message")
    Tester.assert_equals("INFO", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_debug()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.debug_block("message")
    Tester.assert_equals("DEBUG", fullyOnLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_on_trace()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.trace_block("message")
    Tester.assert_equals("TRACE", fullyOnLoggerUpperLevel)
end


-- Log level tests -- fully off
local fullyOffLogger = Logger.create({ modName = "ModName", prefix = "Prefix", levelOverride = Logger.ALL_LOG_LEVELS[1]})
local fullyOffLoggerUpperLevel
fullyOffLogger._log = function(_, _, _, upperLevel) fullyOffLoggerUpperLevel = upperLevel end

function LoggerTests.test_log_level_fully_off_fatal()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger.fatal("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_error()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger.error("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_warn()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger.warn("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_info()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger.info("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_debug()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger.debug("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_level_fully_off_trace()
    fullyOffLoggerUpperLevel = nil
    fullyOffLogger.trace("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_fatal()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.fatal_block("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_error()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.error_block("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_warn()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.warn_block("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_info()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.info_block("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_debug()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.debug_block("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end

function LoggerTests.test_log_block_level_fully_off_trace()
    fullyOnLoggerUpperLevel = nil
    fullyOnLogger.trace_block("message")
    Tester.assert_equals(nil, fullyOffLoggerUpperLevel)
end


return LoggerTests
