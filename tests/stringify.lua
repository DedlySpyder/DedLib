local Logger = require("modules/logger").create{modName = "DedLib", prefix = "Stringify_Test"}
local Stringify = require("modules/stringify")
local Assert = require("modules/testing/assert")
local Util = require("modules/util")

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
    LuaForce = function() return game.forces[1] end,
    LuaGuiElement = function() return game.players[1].gui.screen end,
    LuaItemPrototype = function() return game.item_prototypes["iron-plate"] end,
    LuaItemStack = function() return game.players[1].get_main_inventory()[1] end,
    LuaPlayer = function() return game.players[1] end,
    LuaRecipe = function() return game.players[1].force.recipes["iron-plate"] end,
    LuaRecipePrototype = function() return game.recipe_prototypes["iron-plate"] end,
    LuaSurface = function() return game.surfaces[1] end,
    LuaTechnology = function() return game.players[1].force.technologies["logistics"] end,
    LuaTechnologyPrototype = function() return game.technology_prototypes["logistics"] end,
    LuaTile = function() return game.surfaces["nauvis"].get_tile(0, 0) end,
    LuaTilePrototype = function() return game.tile_prototypes["grass-1"] end
}


-- is_lua_object Tests
for objectName, generateArgsFunc in pairs(LUA_OBJECTS) do
    local name = "test_is_lua_object__true_" .. objectName

    StringifyTests[name] = {
        generateArgsFunc = generateArgsFunc,
        func = function(object)
            Logger.debug("Testing is lua object on %s", objectName)
            local actual = Stringify.is_lua_object(object)
            Assert.assert_true(actual, "Input failed for lua_object <" .. objectName .. ">: " .. serpent.line(object))
        end
    }
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
isLuaObjectFalseTests(4.2)
isLuaObjectFalseTests(nil)
isLuaObjectFalseTests(true)
isLuaObjectFalseTests(false)
isLuaObjectFalseTests(function() end)
isLuaObjectFalseTests({foo = "bar"})


-- to_string Tests
for objectName, generateArgsFunc in pairs(LUA_OBJECTS) do -- Just making sure these all run fine and have the correct main type at least
    local name = "test_to_string__lua_object_" .. objectName

    StringifyTests[name] = {
        generateArgsFunc = generateArgsFunc,
        func = function(object)
            local actual = Stringify.to_string(object)
            Assert.assert_starts_with("<" .. objectName .. ">", actual)
        end
    }
end

local toStringTest = function(testNameSuffix, argOrGenerateArgsFunc, expected, block)
    local test = Util.ternary(
            type(argOrGenerateArgsFunc) == "function",
            function(object)
                local actual = Stringify.to_string(object, block)
                Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(object))
            end,
            function()
                local actual = Stringify.to_string(argOrGenerateArgsFunc, block)
                Assert.assert_equals(expected, actual, "Input failed: " .. serpent.line(object))
            end
    )

    StringifyTests["test_to_string__" .. testNameSuffix] = {
        generateArgsFunc = argOrGenerateArgsFunc,
        func = test
    }
end

toStringTest("string", "foobar", "foobar")
toStringTest("integer", 42, "42")
toStringTest("float", 4.2, "4.2")
toStringTest("nil", nil, "nil")
toStringTest("true", true, "true")
toStringTest("false", false, "false")
-- This is just weird because of the test generator
toStringTest("function", function() return function() end end, "<function>")

toStringTest("basic_table", {foo = "bar"}, serpent.line({foo = "bar"}))
toStringTest("basic_table_block", {foo = "bar"}, serpent.block({foo = "bar"}), true)
toStringTest(
        "nested_table",
        {foo = {bar = "baz"}},
        serpent.line({foo = {bar = "baz"}})
)
toStringTest(
        "nested_table_block",
        {foo = {bar = "baz"}},
        serpent.block({foo = {bar = "baz"}}),
        true
)

toStringTest(
        "basic_table_with_lua_obj",
        function() return {foo = game} end,
        serpent.line({foo = "<LuaGameScript>"})
)
toStringTest(
        "basic_table_block_with_lua_obj",
        function() return {foo = game} end,
        serpent.block({foo = "<LuaGameScript>"}),
        true
)
toStringTest(
        "nested_table_with_lua_obj",
        function() return {foo = {bar = game}} end,
        serpent.line({foo = {bar = "<LuaGameScript>"}})
)
toStringTest(
        "nested_table_block_with_lua_obj",
        function() return {foo = {bar = game}} end,
        serpent.block({foo = {bar = "<LuaGameScript>"}}),
        true
)

toStringTest(
        "invalid_entity",
        function()
            local entity = LUA_OBJECTS.LuaEntity()
            entity.destroy()
            return entity
        end,
        "<LuaEntity>{Invalid}"
)


-- Formatter Tests
for objectName, _ in pairs(Stringify.Formatters) do -- Just making sure these all run fine and have the correct main type at least
    if not Util.String.starts_with(objectName, "_") then
        local name = "test_formatters__" .. objectName
        local genArgsFunc = LUA_OBJECTS[objectName]

        StringifyTests[name] = {
            before = function()
                Assert.assert_not_nil(genArgsFunc, "Missing generator for " .. objectName)
            end,
            generateArgsFunc = genArgsFunc,
            func = function(arg)
                local actual = Stringify.Formatters._run_formatter(objectName, arg)
                Assert.assert_starts_with("<" .. objectName .. ">", actual)
            end
        }
    end
end


return StringifyTests