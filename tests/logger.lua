local LOGGER = require("modules/logger")
local t_log = LOGGER.create{modName = "TEST"}

return function()
    local log = LOGGER.create()

    t_log.trace("Testing Levels:")
    log.fatal("fatal message")
    log.error("error message")
    log.warn("warn message")
    log.info("info message")
    log.debug("debug message")
    log.trace("trace message")

    t_log.trace("Testing Duplicates:")
    log.info("duplicate")
    log.info("duplicate")
    log.info("duplicate")
    log.info("duplicate")

    t_log.trace("Testing Table:")
    log.info({foo = "bar"})

    local newLog = LOGGER.create{modName = "new_test_mod"}
    t_log.trace("Testing new logger:")
    newLog.fatal("fatal message")
    newLog.error("error message")
    newLog.warn("warn message")
    newLog.info("info message")
    newLog.debug("debug message")
    newLog.trace("trace message")

    local prefixLog = LOGGER.create{modName = "prefix_mod", prefix = "foobar"}
    t_log.trace("Testing prefix logger:")
    prefixLog.info("test")
    prefixLog.info("test1")

    local infoLogger = LOGGER.create{modName = "info_logger", levelOverride = "info"}
    t_log.trace("Testing info logger (running all, expecting no debug or trace):")
    infoLogger.fatal("fatal message")
    infoLogger.error("error message")
    infoLogger.warn("warn message")
    infoLogger.info("info message")
    infoLogger.debug("debug message")
    infoLogger.trace("trace message")

    local offLogger = LOGGER.create{modName = "offLogger", levelOverride = "off"}
    t_log.trace("Testing off logger (running all, expecting none):")
    offLogger.fatal("fatal message")
    offLogger.error("error message")
    offLogger.warn("warn message")
    offLogger.info("info message")
    offLogger.debug("debug message")
    offLogger.trace("trace message")
    t_log.trace("Done testing off logger")
end
