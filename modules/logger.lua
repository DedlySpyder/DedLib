local Stringify = require("stringify")
local Debug = require("debug")
local Table = require("table")
local Util = require("util")

local Logger = {} -- TODO - make sure this works and organize this file
Logger.__index = Logger


-- -- Static Values -- --
Logger.ALL_LOG_LEVELS = {"off", "fatal", "error", "warn", "info", "debug", "trace"}

-- All valid logging method names
Logger.LOG_METHODS = Table.flatten(Table.map(Logger.ALL_LOG_LEVELS, function(level)
    if level ~= "off" then
        return {level, level .. "_block"}
    end
end))



-- -- Public Usage -- --
--TODO docs
-- prefix
-- modName
-- levelOverride
-- consoleLevelOverride
-- fileLevelOverride
-- Note about off file logging being a lie

--TODO uses
-- log levels
-- [log]_block methods
-- _LOG_LEVEL if you want to act on a certain level
function Logger.create(args)
    if not args then
        args = {}
    elseif type(args) == "string" then
        args = {prefix = args}
    end

    local log = {}
    setmetatable(log, Logger)

    -- Precedence:
    --  - modName arg
    --  - script.mod_name (in control)
    --  - default to "Data"
    log.MOD_NAME = args.modName or Util.ternary(script ~= nil, script.mod_name, "Data")
    log.PREFIX = Util.ternary(
            args.prefix ~= nil and args.prefix ~= "",
            string.format("[%s]", args.prefix),
            ""
    )

    if args.consoleLevelOverride or args.fileLevelOverride or args.levelOverride then
        log:override_log_levels(
                args.consoleLevelOverride or args.levelOverride,
                args.fileLevelOverride or args.levelOverride
        )
    end

    return log
end

function Logger:override_log_levels(consoleLogLevel, fileLogLevel)
    self.CONSOLE_LOG_LEVEL = consoleLogLevel
    self.FILE_LOG_LEVEL = fileLogLevel

    self:_calculate_highest_log_level()
    self:_generate_log_functions()
end


-- -- Log Level  -- --
function Logger:get_console_log_level_value()
    return self.get_level_value(self.CONSOLE_LOG_LEVEL)
end

function Logger:get_file_log_level_value()
    return self.get_level_value(self.FILE_LOG_LEVEL)
end

-- Get the passed in level as a comparable value
-- 0 is off, then increasing numbers are more verbose
function Logger.get_level_value(level)
    local levelType = type(level)
    if levelType == "number" then
        return level
    elseif levelType ~= "string" then
        log("[WARN] Logger init: Attempted to get value of non-string level: " .. serpent.line(level))
        return 0
    end

    for i, l in ipairs(Logger.ALL_LOG_LEVELS) do
        if l == level then
            return i
        end
    end
    return 0 -- Below off
end

-- Quick check to see if a log level will print anything
-- Returns true when the provided log level WILL print something
function Logger:will_print_for_level(level)
    return self.get_level_value(self.HIGHEST_LOG_LEVEL) >= self.get_level_value(level)
end

function Logger:is_overriding_log_levels()
    return rawget(self, "CONSOLE_LOG_LEVEL") ~= nil or rawget(self, "FILE_LOG_LEVEL") ~= nil
end



-- -- Internal Functions -- --
-- Use at your own risk

-- -- Logger Setup -- --
function Logger:_calculate_highest_log_level()
    local consoleLogLevel = self.CONSOLE_LOG_LEVEL
    local fileLogLevel = self.FILE_LOG_LEVEL

    if self.get_level_value(consoleLogLevel) > self.get_level_value(fileLogLevel) then
        self.HIGHEST_LOG_LEVEL = consoleLogLevel
    else
        -- Either file is higher, or they are the same
        self.HIGHEST_LOG_LEVEL = fileLogLevel
    end
end

-- Log function generation
-- All values in `Logger.ALL_LOG_LEVELS` (except `off`) have 2 functions generated: `[level]` and `[level]_block`
-- The arguments for all of these functions will be (self, format, ...) (... being the format args)
-- Examples of logger method call:
--      Logger:info("info message")
--      Logger:debug("%s message", "debug")
--      Logger.info(Logger, "info message")
function Logger:_generate_log_functions()
    -- Stubbed logger
    if self.HIGHEST_LOG_LEVEL == "off" then
        for _, funcName in ipairs(self.LOG_METHODS) do
            self[funcName] = self._stub
        end
        return
    end

    -- If anything was overridden, then recreate all of the logger methods
    -- Otherwise all of them will be inherited up from the root logger
    if self:is_overriding_log_levels() then
        local consoleLevelValue = self:get_console_log_level_value()
        local fileLevelValue = self:get_file_log_level_value()

        -- Skip "off"
        for i = 2, #self.ALL_LOG_LEVELS do
            self:_insert_method(self.ALL_LOG_LEVELS[i], consoleLevelValue, fileLevelValue)
        end
    end
end

function Logger:_insert_method(level, consoleLevelValue, fileLevelValue)
    local upperLevel = string.upper(level)

    local logFunc = self:_get_inner_log_function(level, consoleLevelValue, fileLevelValue)
    if logFunc == nil then
        self[level] = self._stub
        self[level .. "_block"] = self._stub
        return
    end

    self[level] = self._generate_log_func(upperLevel, logFunc, false)
    self[level .. "_block"] = self._generate_log_func(upperLevel, logFunc, true)
end

function Logger:_get_inner_log_function(level, consoleLevelValue, fileLevelValue)
    local levelValue = self.get_level_value(level)
    local logConsole = consoleLevelValue >= levelValue
    local logFile = fileLevelValue >= levelValue

    if logConsole and logFile then
        return self._log_both
    elseif logConsole then
        return self._log_console
    elseif logFile then
        return self._log_file
    end
    -- Else this should be a stub function
end

function Logger._generate_log_func(upperLevel, logFunc, blockPrint)
    return function(self, format, ...)
        local formatArgs = self._stringify_args(table.pack(...), blockPrint)
        format = Stringify.to_string(format, blockPrint)
        self:_log(logFunc, format, formatArgs, upperLevel)
    end
end



-- -- Log Message Formatting -- --
function Logger._stringify_args(args, blockPrint)
    for i=1, args["n"] do
        args[i] = Stringify.to_string(args[i], blockPrint)
    end
    return args
end

function Logger:_log(logFunc, format, formatArgs, level)
    local formatted = self:_format_message(format, formatArgs, level)
    if formatted == self._LAST_MESSAGE then
        self._SAME_MESSAGE_COUNT = self._SAME_MESSAGE_COUNT + 1
        formatted = self:_format_message(format, formatArgs, level, self._SAME_MESSAGE_COUNT)
    else
        self._SAME_MESSAGE_COUNT = 0
        self._LAST_MESSAGE = formatted
    end
    logFunc(formatted)
end

function Logger:_format_message(format, formatArgs, level, count)
    if formatArgs.n > 0 then
        format = string.format(format, unpack(formatArgs))
    end
    return self._get_tick(count) .. "[" .. self.MOD_NAME .. "]" .. self.PREFIX .. "[" .. Debug.get_short_current_line_string(6) .. "] " .. level .. " - " .. format
end


function Logger._get_tick(count)
    if game then
        Logger._get_tick = Logger._get_tick_in_game
        return Logger._get_tick(count)
    end
    return ""
end

function Logger._get_tick_in_game(count)
    if count then
        count = "-" .. tostring(count)
    else
        count = ""
    end
    return "[" .. game.tick .. count .. "]"
end



-- -- Log Writing -- --
function Logger._log_console(message)
    if game then
        Logger._log_console = function(m)
            game.print(m)
        end
        Logger._log_console(message)
    end
end

Logger._log_file = log

function Logger._log_both(message)
    Logger._log_console(message)
    Logger._log_file(message)
end

function Logger._stub() end -- No-op



-- Logger Settings
function Logger._refresh_settings() -- TODO allow this to be used by child loggers as well? or atleast let them change it
    if settings then
        Logger.ROOT_CONSOLE_LOG_LEVEL = settings.startup["DedLib_logger_level_console"].value
        Logger.ROOT_FILE_LOG_LEVEL = settings.startup["DedLib_logger_level_file"].value
        if Logger.ROOT_FILE_LOG_LEVEL == "off" then Logger.ROOT_FILE_LOG_LEVEL = "fatal" end -- Choice is an illusion
    else
        -- We're in the settings phase, so just stick with the defaults, people can override if they want
        Logger.ROOT_CONSOLE_LOG_LEVEL = "off"
        Logger.ROOT_FILE_LOG_LEVEL = "error"
    end

    -- TODO refresh log functions & HIGHEST_LOG_LEVEL
    Logger:_calculate_highest_log_level()
    Logger:_generate_log_functions(true)
end
Logger._refresh_settings() -- TODO root logger setup at the end of this













--[[
function Logger.create(loggerArgs)
    if not loggerArgs then
        loggerArgs = {}
    end
    if type(loggerArgs) == "string" then
        loggerArgs = { prefix = loggerArgs }
    end
    local modName = get_mod_name(loggerArgs.modName)

    local consoleLogLevel = loggerArgs.consoleLevelOverride or loggerArgs.levelOverride or Logger.ROOT_CONSOLE_LOG_LEVEL
    local consoleConfiguredLogLevel = Logger.get_level_value(consoleLogLevel)
    local fileLogLevel = loggerArgs.fileLevelOverride or loggerArgs.levelOverride or Logger.ROOT_FILE_LOG_LEVEL
    local fileConfiguredLogLevel = Logger.get_level_value(fileLogLevel)

    local prefix = ""
    if loggerArgs.prefix then
        prefix = "[" .. loggerArgs.prefix .. "]"
    end

    local l = {}
    local function stub() end

    if consoleConfiguredLogLevel > fileConfiguredLogLevel then
        l._LOG_LEVEL = consoleLogLevel
    else
        -- Either file is higher, or they are the same
        l._LOG_LEVEL = fileLogLevel
    end

    function l.level_is_less_than(level)
        return Logger.get_level_value(l._LOG_LEVEL) < Logger.get_level_value(level)
    end

    -- Return stub logger
    if consoleConfiguredLogLevel <= 1 and fileConfiguredLogLevel <= 1 then
        l.fatal = stub
        l.error = stub
        l.warn = stub
        l.info = stub
        l.debug = stub
        l.trace = stub
        return l
    end

    function l._format_message(format, formatArgs, level, count)
        if formatArgs.n > 0 then
            format = string.format(format, unpack(formatArgs))
        end
        return Logger._get_tick(count) .. "[" .. modName .. "]" .. prefix .. "[" .. Debug.get_short_current_line_string(6) .. "] " .. level .. " - " .. format
    end

    -- All args are assumed non-nil
    function l._log(logFunc, format, formatArgs, level)
        local formatted = l._format_message(format, formatArgs, level)
        if formatted == l._LAST_MESSAGE then
            l._SAME_MESSAGE_COUNT = l._SAME_MESSAGE_COUNT + 1
            formatted = l._format_message(format, formatArgs, level, l._SAME_MESSAGE_COUNT)
        else
            l._SAME_MESSAGE_COUNT = 0
            l._LAST_MESSAGE = formatted
        end
        logFunc(formatted)
    end

    function l._generate_log_func(upperLevel, logFunc, blockPrint)
        return function(format, ...)
            local formatArgs = Logger._stringify_args(table.pack(...), blockPrint)
            format = Stringify.to_string(format, blockPrint)
            l._log(logFunc, format, formatArgs, upperLevel)
        end
    end

    local function insert_method(level)
        local levelValue = Logger.get_level_value(level)
        local upperLevel = string.upper(level)

        local logConsole = consoleConfiguredLogLevel >= levelValue
        local logFile = fileConfiguredLogLevel >= levelValue

        local logFunc = nil
        if logConsole and logFile then
            logFunc = Logger._log_both
        elseif logConsole then
            logFunc = Logger._log_console
        elseif logFile then
            logFunc = Logger._log_file
        else
            l[level] = stub
            l[level .. "_block"] = stub
            return
        end

        l[level] = l._generate_log_func(upperLevel, logFunc, false)
        l[level .. "_block"] = l._generate_log_func(upperLevel, logFunc, true)
    end

    -- Create all the `.[level]` and `.[level]_block` methods on the logger
    insert_method("fatal")
    insert_method("error")
    insert_method("warn")
    insert_method("info")
    insert_method("debug")
    insert_method("trace")

    return l
end
]]--

return Logger
