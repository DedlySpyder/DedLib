local Logger = require("modules/logger")
local Tester = require("modules/tester")

local t_log = Logger.create{ modName = "TEST"}

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
