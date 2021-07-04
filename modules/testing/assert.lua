--[[
The assert library is better for use with the Tester compared to assert or error manually because it will include the
stacktrace in the resulting error output. There are also convenience methods comparisons as well.

Methods ending in `*_exactly` will compare tables to see if they are the same reference to a table, otherwise simply the
value of the table is compared.

This module can be called directly or used from the main `__DedLib__/modules/testing/tester` file as `Tester.Assert...`
]]--
local Util = require("__DedLib__/modules/util")
local Stringify = require("__DedLib__/modules/stringify")

local Assert = {}


function Assert._fail(message, assertType, assertVar1Name, assertVar1Value, assertVar2Name, assertVar2Value)
    if message then
        message = tostring(message) .. "\n"
    else
        message = ""
    end
    if assertVar2Name then
        message = string.format(
                "%sAssertion %s failed. %s <%s> - %s <%s>",
                message,
                assertType,
                assertVar1Name,
                Stringify.to_string(assertVar1Value),
                assertVar2Name,
                Stringify.to_string(assertVar2Value)
        )
    else
        message = string.format(
                "%sAssertion %s failed. %s <%s>",
                message,
                assertType,
                assertVar1Name,
                Stringify.to_string(assertVar1Value)
        )
    end

    error({message = message, stacktrace = debug.traceback()})
end

function Assert.assert_nil(obj, message)
    if obj ~= nil then
        Assert._fail(
                message,
                "nil",
                "Object",
                obj
        )
    end
end

function Assert.assert_not_nil(obj, message)
    if obj == nil then
        Assert._fail(
                message,
                "not nil",
                "Object",
                obj
        )
    end
end

function Assert.assert_true(bool, message)
    if not bool then
        Assert._fail(
                message,
                "true",
                "Bool",
                bool
        )
    end
end

function Assert.assert_false(bool, message)
    if bool then
        Assert._fail(
                message,
                "false",
                "Bool",
                bool
        )
    end
end

function Assert.assert_equals(expected, actual, message)
    if serpent.line(expected) ~= serpent.line(actual) then --TODO - hacky - make better way to compare types generically (other asserts need it as well)
        Assert._fail(
                message,
                "equals",
                "Expected",
                expected,
                "Actual",
                actual
        )
    end
end

function Assert.assert_not_equals(expected, actual, message)
    if serpent.line(expected) == serpent.line(actual) then --TODO - hacky - make better way to compare types generically (other asserts need it as well)
        Assert._fail(
                message,
                "not equals",
                "Expected",
                expected,
                "Actual",
                actual
        )
    end
end

function Assert.assert_equals_exactly(expected, actual, message)
    if expected ~= actual then
        Assert._fail(
                message,
                "equals exactly",
                "Expected",
                expected,
                "Actual",
                actual
        )
    end
end

function Assert.assert_starts_with(startsWith, value, message)
    if not Util.String.starts_with(tostring(value), tostring(startsWith)) then
        Assert._fail(
                message,
                "starts with",
                "Starts with",
                startsWith,
                "Actual string",
                value
        )
    end
end

function Assert.assert_ends_with(endsWith, value, message)
    if not Util.String.ends_with(tostring(value), tostring(endsWith)) then
        Assert._fail(
                message,
                "ends with",
                "Ends with",
                endsWith,
                "Actual string",
                value
        )
    end
end

function Assert.assert_contains(expectedItem, list, message)
    local expectedItemStr = serpent.line(expectedItem)
    for _, listItem in pairs(list) do
        if serpent.line(listItem) == expectedItemStr then
            return
        end
    end

    -- Wasn't found
    Assert._fail(
            message,
            "contains",
            "Expected item",
            expectedItem,
            "List",
            list
    )
end

function Assert.assert_contains_exactly(expectedItem, list, message)
    for _, listItem in pairs(list) do
        if listItem == expectedItem then
            return
        end
    end

    -- Wasn't found
    Assert._fail(
            message,
            "contains exactly",
            "Expected item",
            expectedItem,
            "List",
            list
    )
end

function Assert.assert_contains_key(expectedKey, list, message)
    if list[expectedKey] == nil then
        Assert._fail(
                message,
                "contains key",
                "Expected key",
                expectedKey,
                "List",
                list
        )
    end
end


return Assert