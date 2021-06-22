local Stringify = {}

Stringify._SERPENT_LINE = serpent.line
Stringify._SERPENT_BLOCK = serpent.block

Stringify._ALWAYS_VALID = {
    LuaBootstrap = true,
    LuaCommandProcessor = true,
    LuaCustomTable = true,
    LuaDifficultySettings = true,
    LuaGameScript = true,
    LuaGameViewSettings = true,
    LuaMapSettings = true,
    LuaRCON = true,
    LuaRemote = true,
    LuaRendering = true,
    LuaSettings = true,
}


Stringify.Formatters = {}
function Stringify.Formatters.LuaCustomTable(arg)
    return string.format("<LuaCustomTable>{%d item(s)}", #arg)
end

function Stringify.Formatters.LuaEntity(arg)
    local pos = arg.position
    return string.format("<LuaEntity>{type=%s, name=%s, unit_number=%s, position={%s,%s}}",
            arg.type,
            arg.name,
            tostring(arg.unit_number),
            tostring(pos.x),
            tostring(pos.y)
    )
end

function Stringify.Formatters.LuaEntityPrototype(arg)
    return string.format("<LuaEntityPrototype>{type=%s, name=%s}",
            arg.type,
            arg.name
    )
end

function Stringify.Formatters.LuaForce(arg)
    return string.format("<LuaForce>{name=%s, player_count=%s}",
            arg.name,
            tostring(#arg.players)
    )
end

function Stringify.Formatters.LuaGuiElement(arg)
    return string.format("<LuaGuiElement>{player_index=%s, name=%s, type=%d, index=%s}",
            arg.player_index,
            arg.name,
            arg.type,
            tostring(#arg.index)
    )
end

function Stringify.Formatters.LuaItemPrototype(arg)
    return string.format("<LuaItemPrototype>{type=%s, name=%s}",
            arg.type,
            arg.name
    )
end

function Stringify.Formatters.LuaItemStack(arg)
    if arg.valid_for_read then
        return string.format("<LuaItemStack>{type=%s, name=%s, count=%s}",
                arg.type,
                arg.name
        )
    else
        return "<LuaItemStack{invalid for reading}>"
    end
end

function Stringify.Formatters.LuaPlayer(arg)
    return string.format("<LuaPlayer>{name=%s, index=%s}",
            arg.name,
            arg.index
    )
end

function Stringify.Formatters.LuaRecipe(arg)
    return string.format("<LuaRecipe>{name=%s}",
            arg.name
    )
end

function Stringify.Formatters.LuaRecipePrototype(arg)
    return string.format("<LuaRecipePrototype>{name=%s}",
            arg.name
    )
end

function Stringify.Formatters.LuaSurface(arg)
    return string.format("<LuaSurface>{name=%s, index=%s}",
            arg.name,
            arg.index
    )
end

function Stringify.Formatters.LuaTechnology(arg)
    return string.format("<LuaTechnology>{name=%s}",
            arg.name
    )
end

function Stringify.Formatters.LuaTechnologyPrototype(arg)
    return string.format("<LuaTechnologyPrototype>{name=%s}",
            arg.name
    )
end

function Stringify.Formatters.LuaTile(arg)
    local pos = arg.position
    return string.format("<LuaTile>{name=%s, position={%s,%s}}",
            arg.name,
            tostring(pos.x),
            tostring(pos.y)
    )
end

function Stringify.Formatters.LuaTilePrototype(arg)
    return string.format("<LuaTilePrototype>{name=%s}",
            arg.name
    )
end


-- Start of actual functions
function Stringify.is_lua_object(object)
    return object ~= nil and type(rawget(object, "__self")) == "userdata" and getmetatable(object) == "private"
end

function Stringify.to_string(arg, block, notFirst)
    local argType = type(arg)
    if argType == "string" then
        return arg

    elseif argType == "table" then
        if Stringify.is_lua_object(arg) then
            local oName = arg.object_name
            if Stringify._ALWAYS_VALID[oName] or arg.valid then
                local formatter = Stringify.Formatters[oName]
                if formatter then
                    local success, result = pcall(formatter, arg)
                    if success then
                        return result
                    else
                        log("DedLib Internal Error: Unexpected failure on stringify formatter for " .. oName)
                    end
                end
                return string.format("<%s>", oName) -- Either no formatter or formatter failed
            else
                return string.format("<%s>{Invalid}", oName)
            end
        end

        -- Normal tables are checked recursively for lua objects, though we need to deepcopy while we do it
        local t = {}
        for k, v in pairs(arg) do
            t[k] = Stringify.to_string(v, block, true)
        end
        if notFirst then
            return t
        else
            if block then
                return Stringify._SERPENT_BLOCK(t)
            else
                return Stringify._SERPENT_LINE(t)
            end
        end

    else
        return tostring(arg)
    end
end


return Stringify