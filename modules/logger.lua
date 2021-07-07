local Stringify = require("stringify")
local Debug = require("debug")
local Table = require("table")
local Util = require("util")

local Logger = {}
Logger.__index = Logger
Logger._IS_LOGGER = true


-- -- Static Values -- --
Logger.ALL_LOG_LEVELS = {"off", "fatal", "error", "warn", "info", "debug", "trace"}
Logger._ALL_LOG_LEVELS_INDEX = Table.indexify(Logger.ALL_LOG_LEVELS)

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
    if not ((consoleLogLevel == nil or Logger.is_valid_log_level(consoleLogLevel)) and
            (fileLogLevel == nil or Logger.is_valid_log_level(fileLogLevel))) then
        log(string.format(
                "[ERROR] Logger override log levels failed for %s/%s logger.\nLevels used: %s, %s\nValid levels: %s",
                self.MOD_NAME,
                self.PREFIX,
                consoleLogLevel,
                fileLogLevel,
                serpent.line(Logger.ALL_LOG_LEVELS)
        ))
        return
    end

    self.CONSOLE_LOG_LEVEL = consoleLogLevel
    self.FILE_LOG_LEVEL = fileLogLevel

    if self:is_overriding_log_levels() then
        self:_calculate_highest_log_level()
        self:_generate_log_functions()
    else
        self.HIGHEST_LOG_LEVEL = nil
        for _, funcName in ipairs(self.LOG_METHODS) do
            self[funcName] = nil
        end
    end
end


-- -- Log Level  -- --
function Logger.is_valid_log_level(level)
    return Logger._ALL_LOG_LEVELS_INDEX[level] ~= nil
end

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
        if not self._IS_LOGGER then error("Invalid use of log function, proper syntax is Logger:" .. string.lower(upperLevel) .. "(...)") end
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
    return self._get_tick(count) ..
            "[" .. self.MOD_NAME .. "]" ..
            self.PREFIX ..
            "[" .. Debug.get_short_current_line_string(6) .. "] "
            .. level .. " - " ..
            format
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



-- -- Initialize the root logger -- --
function Logger._configure_root_logger()
    if settings then
        local fileLogLevel = settings.startup["DedLib_logger_level_file"].value
        Logger:override_log_levels(
                settings.global["DedLib_logger_level_console"].value,
                Util.ternary(fileLogLevel == "off", "fatal", fileLogLevel) -- Choice is an illusion
        )
    else
        -- We're in the settings phase, so just stick with the defaults, others can override if they want
        Logger:override_log_levels("off", "error")
    end
end
Logger._configure_root_logger()


return Logger
