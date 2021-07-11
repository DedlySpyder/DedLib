-- Help parsing for Factorio .help() to a table
local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}
local Stringify = require("__DedLib__/modules/stringify")
local Util = require("__DedLib__/modules/util")

local Help = {}
Help._CACHE = {}

function Help.get_help(name, luaObject)
    local cacheValue = Help._CACHE[name]
    if cacheValue then return cacheValue end

    if luaObject and Stringify.is_lua_object(luaObject) then
        return Help.parse_help_string(luaObject.help())
    else
        Logger:error("Failed to find help value for %s and object <%s> is not a lua object", name, luaObject)
    end
end

function Help.parse_help_string(str)
    local parsed = {methods = {}, values = {}}
    local methods, values = false, false

    for i, line in ipairs(Util.String.split(str, "\n")) do
        -- First line for caching
        if i == 1 then
            local cached = Help._parse_first_line_and_handle_cache(line, parsed)
            if cached then return cached end
        else
            -- The actual member parsing
            if methods then
                -- During Methods
                if Util.String.starts_with(line, "Values:") then
                    methods = false
                    values = true
                else
                    local name = Help._parse_method(line)
                    if name then parsed.methods[name] = true end
                end
            elseif values then
                -- During Values
                local name, data = Help._parse_value(line)
                if name then
                    parsed.values[name] = data
                end
            else
                -- Before Methods
                if Util.String.starts_with(line, "Methods:") then
                    methods = true
                end
            end
        end
    end
    return parsed
end


function Help._parse_first_line_and_handle_cache(line, newParsedTable)
    if #line > 10 then
        -- Expecting "Help for LuaGuiElement:", looking for just "LuaGuiElement"
        local objectType = string.sub(line, 10, #line - 1)

        local cached = Help._CACHE[objectType]
        if cached then
            Logger:trace("Found parsed help in the cache for %s", objectType)
            return cached
        else
            Logger:trace("Did not find parsed help in the cache for %s, generating now...", objectType)
            Help._CACHE[objectType] = newParsedTable
        end
    else
        Logger:error("Could not parse type for help text <%s> continuing without cache...", line)
    end
end

function Help._parse_method(line)
    return Util.String.split(line, "(")[1]
end

function Help._parse_value(line)
    local parts = Util.String.split(line, " ")
    local rw = parts[2]
    return parts[1], {
        read = Util.ternary(string.find(rw, "R"), true, false),
        write = Util.ternary(string.find(rw, "W"), true, false)
    }
end


return Help
