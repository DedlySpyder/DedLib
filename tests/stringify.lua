local Logger = require("modules/logger").create{modName = "DedLib", prefix = "Stringify_Test"}
local Stringify = require("modules/stringify")
local Assert = require("modules/testing/assert")

local StringifyTests = {}


-- One of each Lua Object from Factorio, mapped by their object_name
-- Missing some, but these are the one's I'm supporting currently
local LUA_OBJECTS = {
    LuaCommandProcessor = function() return commands end,
    LuaGameScript = function() return game end,
    LuaRCON = function() return rcon end,
    LuaRemote = function() return remote end,
    LuaRendering = function() return rendering end,
    LuaBootstrap = function() return script end,
    LuaSettings = function() return settings end,

    LuaCustomTable = function() return game.players end,
    LuaEntity = function() return game.surfaces["nauvis"].find_entities_filtered{limit=1}[1] end,
    LuaEntityPrototype = function() return game.entity_prototypes["stone-furnace"] end,
    LuaForce = function() return game.create_force("testForce") end,
    LuaGuiElement = function() return game.players[1].gui.screen end,
    LuaItemPrototype = function() return game.item_prototypes["iron-plate"] end,
    LuaItemStack = function() return game.players[1].get_main_inventory()[1] end,
    LuaPlayer = function() return game.players[1] end,
    LuaRecipe = function() return game.players[1].force.recipes["iron-plate"] end,
    LuaRecipePrototype = function() return game.recipe_prototypes["iron-plate"] end,
    LuaSurface = function() return game.create_surface("testSurface") end,
    LuaTechnology = function() return game.players[1].force.technologies["logistics"] end,
    LuaTechnologyPrototype = function() return game.technology_prototypes["logistics"] end,
    LuaTile = function() return game.surfaces["nauvis"].get_tile(0, 0) end,
    LuaTilePrototype = function() return game.tile_prototypes["grass-1"] end
}


-- is_lua_object tests
for objectName, generateArgsFunc in pairs(LUA_OBJECTS) do
    local name = "test_is_lua_object__true_" .. objectName

    StringifyTests[name] = {
        generateArgsFunc = generateArgsFunc,
        func = function(object)
            Logger.debug("Testing is lua object on %s", objectName)
            local actual = Stringify.is_lua_object(object)
            Assert.assert_true(actual, "Input failed for lua_object <" .. objectName .. ">: " .. serpent.line(object))
    end}
end

local isLuaObjectFalseTests = function(testValue)
    local testValueType = type(testValue)
    StringifyTests["test_is_lua_object__false_" .. testValueType] = function()
        Logger.debug("Testing is lua object on type %s: %s", testValueType, testValue)
        local actual = Stringify.is_lua_object(testValue)
        Assert.assert_false(actual, "Input failed for lua_object: " .. tostring(testValue))
    end
end

isLuaObjectFalseTests("stringValue")
isLuaObjectFalseTests(42)
isLuaObjectFalseTests(nil)
isLuaObjectFalseTests(false)
isLuaObjectFalseTests(function() end)
isLuaObjectFalseTests({foo = "bar"})



-- to_string tests
--[[
test formatters separately (por que no dos?)
lists of lua_objects
invalid lua_object
]]--


-- TODO - test formatters (make sure they don't fail for valid/invalid/invalid for read & check for <> value


return StringifyTests