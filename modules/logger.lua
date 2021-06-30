local Stringify = require("stringify")
local Debug = require("debug")

local Logger = {}

if settings then
    Logger.LOG_LEVEL_CONSOLE = settings.startup["DedLib_logger_level_console"].value
    Logger.LOG_LEVEL_FILE = settings.startup["DedLib_logger_level_file"].value
    if Logger.LOG_LEVEL_FILE == "off" then Logger.LOG_LEVEL_FILE = "fatal" end -- Choice is an illusion
else
    -- We're in the settings phase, so just stick with the defaults, people can override if they want
    Logger.LOG_LEVEL_CONSOLE = "off"
    Logger.LOG_LEVEL_FILE = "error"
end

local function get_mod_name(modName)
    if modName then
        return modName
    elseif script then
        return script.mod_name
    else
        return "Data"
    end
end


Logger.ALL_LOG_LEVELS = { "off", "fatal", "error", "warn", "info", "debug", "trace" }

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


-- Log writing functions
function Logger._check_is_game()
    if not Logger._IS_GAME then
        if game then
            Logger._IS_GAME = true
        end
    end
    return Logger._IS_GAME
end
Logger._check_is_game()

-- Not sure on init if `game` is initialized
-- If it is, then this check is no longer needed
function Logger._log_console(message)
    if Logger._check_is_game() then
        Logger._log_console = Logger._log_console_in_game
        Logger._log_console(message)
    end
end

function Logger._log_console_in_game(message)
    game.print(message)
end

Logger._log_file = log

function Logger._log_both(message)
    Logger._log_console(message)
    Logger._log_file(message)
end



-- Log message formatting
function Logger._get_tick(count)
    if Logger._check_is_game() then
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

function Logger._stringify_args(args, blockPrint)
    for i=1, args["n"] do
        args[i] = Stringify.to_string(args[i], blockPrint)
    end
    return args
end


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
function Logger.create(loggerArgs)
    if not loggerArgs then
        loggerArgs = {}
    end
    if type(loggerArgs) == "string" then
        loggerArgs = { prefix = loggerArgs }
    end
    local modName = get_mod_name(loggerArgs.modName)

    local consoleLogLevel = loggerArgs.consoleLevelOverride or loggerArgs.levelOverride or Logger.LOG_LEVEL_CONSOLE
    local consoleConfiguredLogLevel = Logger.get_level_value(consoleLogLevel)
    local fileLogLevel = loggerArgs.fileLevelOverride or loggerArgs.levelOverride or Logger.LOG_LEVEL_FILE
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

return Logger
