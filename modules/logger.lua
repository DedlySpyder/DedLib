local Logger = {}

Logger.LOG_LEVEL = settings.startup["DedLib_debug_level"].value
Logger.LOG_LOCATION = settings.startup["DedLib_debug_location"].value

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


--TODO docs
-- prefix
-- modName
-- levelOverride
function Logger.create(args)
    if not args then
        args = {}
    end
    if type(args) == "string" then
        args = { prefix = args }
    end
    local modName = get_mod_name(args.modName)
    local configuredLogLevel = Logger.get_level_value(args.levelOverride or Logger.LOG_LEVEL)

    local prefix = ""
    if args.prefix then
        prefix = "[" .. args.prefix .. "]"
    end

    local l = {}
    local stub = function()
    end


    -- Return stub logger
    if configuredLogLevel <= 1 then
        l.fatal = stub
        l.error = stub
        l.warn = stub
        l.info = stub
        l.debug = stub
        l.trace = stub
        return l
    end

    local _log_console = function(message)
        if game then
            for _, player in pairs(game.players) do
                if player and player.valid then
                    player.print(message)
                end
            end
        end
    end

    local _log_both = function(message)
        _log_console(message)
        log(message)
    end

    local _log = stub
    if Logger.LOG_LOCATION == "console" then
        _log = _log_console
    elseif Logger.LOG_LOCATION == "file" then
        _log = log
    else
        _log = _log_both
    end

    -- TODO - this is broken - init before tick 0 means I don't get any tick values
    if game then
        function l._get_tick(count)
            return "[" .. game.tick .. count .. "]"
        end
    else
        function l._get_tick()
            return ""
        end
    end

    function l._format_message(message, level, blockPrint, count)
        if count then
            count = "-" .. tostring(count)
        else
            count = ""
        end

        if type(message) == "table" then
            if blockPrint then
                message = serpent.block(message)
            else
                message = serpent.line(message)
            end
        end

        return l._get_tick(count) .. "[" .. modName .. "]" .. prefix .. " " .. level .. " - " .. message
    end

    function l._log(message, level, blockPrint)
        local s = l._format_message(message, level, blockPrint)
        if s == l._LAST_MESSAGE then
            l._SAME_MESSAGE_COUNT = l._SAME_MESSAGE_COUNT + 1
            s = l._format_message(message, level, blockPrint, l._SAME_MESSAGE_COUNT)
        else
            l._SAME_MESSAGE_COUNT = 0
            l._LAST_MESSAGE = s
        end
        _log(s)
    end

    local insert_method = function(level)
        local levelValue = Logger.get_level_value(level)
        local upperLevel = string.upper(level)

        if configuredLogLevel >= levelValue then
            l[level] = function(m, blockPrint)
                if m == nil then
                    m = "[nil]"
                end -- nil safety
                l._log(m, upperLevel, blockPrint)
            end
        else
            l[level] = stub
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
