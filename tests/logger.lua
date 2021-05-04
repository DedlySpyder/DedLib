local Logger = require("modules/logger")
local Tester = require("modules/tester")

local t_log = Logger.create{ modName = "TEST"} -- TODO - delete if still unused when done

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


-- Format message tests
local formatMessageLogger = Logger.create{modName = "ModName", prefix = "Prefix"}
function LoggerTests.test_format_message_with_count()
    local message = ""
    local actual = formatMessageLogger._format_message(message, "LEVEL", false, "foo")
    local expected = "[" .. game.tick .. "-foo][ModName][Prefix] LEVEL - " .. message

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test_format_message_string()
    local message = "string_message"
    local actual = formatMessageLogger._format_message(message, "LEVEL", false, nil)
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. message

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test_format_message_number()
    local message = 42
    local actual = formatMessageLogger._format_message(message, "LEVEL", false, nil)
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. message

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test_format_message_nil()
    local message = nil
    local actual = formatMessageLogger._format_message(message, "LEVEL", false, nil)
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. tostring(message)

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test_format_message_table()
    local message = {foo = "bar"}
    local actual = formatMessageLogger._format_message(message, "LEVEL", false, nil)
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. serpent.line(message)

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test_format_message_table_block()
    local message = {foo = "bar"}
    local actual = formatMessageLogger._format_message(message, "LEVEL", true, nil)
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. serpent.block(message)

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(message))
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

    local actualMessage
    local logFunc = function(m) actualMessage = m end
    logLogger._log(logFunc, message, "LEVEL")
    local expected = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. message

    Tester.assert_equals(expected, logLogger._LAST_MESSAGE, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test__log_same_message_count()
    resetLogLogger()
    local message = "message"

    local actualMessage
    local logFunc = function(m) actualMessage = m end
    logLogger._log(logFunc, message, "LEVEL")
    Tester.assert_equals(0, logLogger._SAME_MESSAGE_COUNT, "Input failed: " .. serpent.line(message))
    logLogger._log(logFunc, message, "LEVEL")
    Tester.assert_equals(1, logLogger._SAME_MESSAGE_COUNT, "Input failed: " .. serpent.line(message))
end

function LoggerTests.test__log_duplicate_messages()
    resetLogLogger()
    local message = "dup_message"

    local actualMessage
    local logFunc = function(m) actualMessage = m end
    logLogger._log(logFunc, message, "LEVEL")
    local expected1 = "[" .. game.tick .. "][ModName][Prefix] LEVEL - " .. message
    Tester.assert_equals(expected1, actualMessage, "Input failed: " .. serpent.line(message))
    logLogger._log(logFunc, message, "LEVEL")
    local expected2 = "[" .. game.tick .. "-1][ModName][Prefix] LEVEL - " .. message
    Tester.assert_equals(expected2, actualMessage, "Input failed: " .. serpent.line(message))
end


-- Log level tests -- fully on
local fullyOnLogger = Logger.create({ modName = "ModName", prefix = "Prefix", levelOverride = Logger.ALL_LOG_LEVELS[#Logger.ALL_LOG_LEVELS]})
local fullyOnLoggerUpperLevel
fullyOnLogger._log = function(logFunc, m, upperLevel, blockPrint) fullyOnLoggerUpperLevel = upperLevel end

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


-- Log level tests -- fully off
local fullyOffLogger = Logger.create({ modName = "ModName", prefix = "Prefix", levelOverride = Logger.ALL_LOG_LEVELS[1]})
local fullyOffLoggerUpperLevel
fullyOffLogger._log = function(logFunc, m, upperLevel, blockPrint) fullyOffLoggerUpperLevel = upperLevel end

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


return LoggerTests
