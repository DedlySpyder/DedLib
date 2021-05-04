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


return LoggerTests

--return function()
--    local log = Logger.create()
--
--
--    -- TODO need to test in order (kinda)
--    --[[
--    log._log
--    then need to modify it to catch the messages for testing different levels
--    ]]--
--
--    t_log.trace("Testing Levels:")
--    log.fatal("fatal message")
--    log.error("error message")
--    log.warn("warn message")
--    log.info("info message")
--    log.debug("debug message")
--    log.trace("trace message")
--
--    t_log.trace("Testing Duplicates:")
--    log.info("duplicate")
--    log.info("duplicate")
--    log.info("duplicate")
--
--    t_log.trace("Testing Table:")
--    log.info({foo = "bar"})
--
--    local newLog = Logger.create{ modName = "new_test_mod"}
--    t_log.trace("Testing new logger (just fatal and trace):")
--    newLog.fatal("fatal message")
--    newLog.trace("trace message")
--
--    local prefixLog = Logger.create{ modName = "prefix_mod", prefix = "foobar"}
--    t_log.trace("Testing prefix logger:")
--    prefixLog.info("test")
--
--    local infoConsoleLogger = Logger.create{ modName = "info_console_logger", consoleLevelOverride = "error", fileLevelOverride = "off"}
--    t_log.trace("Testing console error logger (running all, expecting just fatal and error):")
--    infoConsoleLogger.fatal("fatal message")
--    infoConsoleLogger.error("error message")
--    infoConsoleLogger.warn("warn message")
--    infoConsoleLogger.info("info message")
--    infoConsoleLogger.debug("debug message")
--    infoConsoleLogger.trace("trace message")
--
--    local infoFileLogger = Logger.create{ modName = "info_file_logger", consoleLevelOverride = "off", fileLevelOverride = "info"}
--    t_log.trace("Testing file info logger (running all, expecting no debug or trace):")
--    infoFileLogger.fatal("fatal message")
--    infoFileLogger.error("error message")
--    infoFileLogger.warn("warn message")
--    infoFileLogger.info("info message")
--    infoFileLogger.debug("debug message")
--    infoFileLogger.trace("trace message")
--
--    local offLogger = Logger.create{ modName = "off_logger", levelOverride = "off"}
--    t_log.trace("Testing off logger (running all, expecting none):")
--    offLogger.fatal("fatal message")
--    offLogger.error("error message")
--    offLogger.warn("warn message")
--    offLogger.info("info message")
--    offLogger.debug("debug message")
--    offLogger.trace("trace message")
--    t_log.trace("Done testing off logger")
--end
