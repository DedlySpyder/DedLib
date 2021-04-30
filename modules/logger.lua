local Logger = {}

Logger.LOG_LEVEL_CONSOLE = settings.startup["DedLib_logger_level_console"].value
Logger.LOG_LEVEL_FILE = settings.startup["DedLib_logger_level_file"].value

Logger.ALL_LOG_LEVELS = { "off", "fatal", "error", "warn", "info", "debug", "trace" }

function Logger.get_level_value(level)
    if type(level) == "number" then
        return level
    end
    for i, l in ipairs(Logger.ALL_LOG_LEVELS) do
        if l == level then
            return i
        end
    end
    return 0 -- Below off
end

local get_mod_name = function(modName)
    if modName then
        return modName
    elseif script then
        return script.mod_name
    else
        return "Data"
    end
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
    for _, player in pairs(game.players) do
        if player and player.valid then
            player.print(message)
        end
    end
end

Logger._log_file = log

function Logger._log_both(message)
    Logger._log_console(message)
    Logger._log_file(message)
end


if Logger.LOG_LOCATION == "console" then
    Logger._log = Logger._log_console
elseif Logger.LOG_LOCATION == "file" then
    Logger._log = Logger._log_file
else
    Logger._log = Logger._log_both
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
    return "[" .. game.tick .. count .. "]"
end

--TODO docs
-- prefix
-- modName
-- levelOverride
-- consoleLevelOverride
-- fileLevelOverride

--TODO uses
-- log levels
-- _LOG_LEVEL if you want to act on a certain level
function Logger.create(args)
    if not args then
        args = {}
    end
    if type(args) == "string" then
        args = { prefix = args }
    end
    local modName = get_mod_name(args.modName)

    local consoleLogLevel = args.consoleLevelOverride or args.levelOverride or Logger.LOG_LEVEL_CONSOLE
    local consoleConfiguredLogLevel = Logger.get_level_value(consoleLogLevel)
    local fileLogLevel = args.fileLevelOverride or args.levelOverride or Logger.LOG_LEVEL_FILE
    local fileConfiguredLogLevel = Logger.get_level_value(fileLogLevel)

    local prefix = ""
    if args.prefix then
        prefix = "[" .. args.prefix .. "]"
    end

    local l = {}
    local stub = function() end

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

    function l._format_message(message, level, blockPrint, count)
        if count then
            count = "-" .. tostring(count)
        else
            count = ""
        end

        local mType = type(message)
        if mType == "table" then
            if blockPrint then
                message = serpent.block(message)
            else
                message = serpent.line(message)
            end
        elseif mType ~= "string" then
            message = tostring(message)
        end

        return Logger._get_tick(count) .. "[" .. modName .. "]" .. prefix .. " " .. level .. " - " .. message
    end

    function l._log(logFunc, message, level, blockPrint)
        if message == nil then message = "[nil]" end -- nil safety
        local formatted = l._format_message(message, level, blockPrint)
        if formatted == l._LAST_MESSAGE then
            l._SAME_MESSAGE_COUNT = l._SAME_MESSAGE_COUNT + 1
            formatted = l._format_message(message, level, blockPrint, l._SAME_MESSAGE_COUNT)
        else
            l._SAME_MESSAGE_COUNT = 0
            l._LAST_MESSAGE = formatted
        end
        logFunc(formatted)
    end

    local insert_method = function(level)
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
            return
        end

        l[level] = function(m, blockPrint)
            l._log(logFunc, m, upperLevel, blockPrint)
        end
    end

    insert_method("fatal")
    insert_method("error")
    insert_method("warn")
    insert_method("info")
    insert_method("debug")
    insert_method("trace")

    return l
end

return Logger
