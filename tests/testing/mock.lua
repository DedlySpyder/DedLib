local Logger = require("modules/logger").create("Testing")
local Mock = require("modules/testing/mock")
local Assert = require("modules/testing/assert")
local Util = require("modules/util")

local test_counts = { succeeded = 0, failed = 0}

local increment_test_failed = function()
    test_counts["failed"] = test_counts["failed"] + 1
end

local increment_test_succeeded = function()
    test_counts["succeeded"] = test_counts["succeeded"] + 1
end

local test_mock_equals = function(expected, actual, shouldMatch)
    local s, e = pcall(Assert.assert_equals, expected, actual)
    if s then
        if shouldMatch then
            Logger:debug("Expected matched, and got matched. Expected: <" .. serpent.line(expected) .. "> - Actual: <" .. serpent.line(actual) .. ">")
            increment_test_succeeded()
        else
            Logger:fatal("Expected not matched, but got matched. Expected: <" .. serpent.line(expected) .. "> - Actual: <" .. serpent.line(actual) .. ">")
            increment_test_failed()
        end
    else
        if shouldMatch then
            Logger:fatal("Expected matched, but got not matched. Expected: <" .. serpent.line(expected) .. "> - Actual: <" .. serpent.line(actual) .. ">")
            Logger:trace(e)
            increment_test_failed()
        else
            Logger:debug("Expected not matched, and got not matched. Expected: <" .. serpent.line(expected) .. "> - Actual: <" .. serpent.line(actual) .. ">")
            Logger:trace(e)
            increment_test_succeeded()
        end
    end
end


return function()
    Logger:debug("Testing mock get valid lua_object")
    test_mock_equals(Mock.get_valid_lua_object(nil), {valid = true}, true)
    test_mock_equals(Mock.get_valid_lua_object({foo = "bar"}), {valid = true, foo = "bar"}, true)

    local mockValidLuaObjectTestError = function()
        local s, err = pcall(Mock.get_valid_lua_object, "foobar")
        err = Util.String.split(err, ":")[3]
        if s or err ~= " Values for mock lua_object is not a table" then
            Logger:fatal(string.format("Fatal mock valid lua_object test failed, status is <%s>, message is <%s>",
                    tostring(s),
                    err
            ))
            increment_test_failed()
        else
            increment_test_succeeded()
        end
    end
    mockValidLuaObjectTestError()



    -- Other tests can depend on Mock working properly, so fail early if it is failing
    Logger:info("Mock validation results: %s", test_counts)
    if test_counts["failed"] > 0 then
        error("Mock validations are failing, cannot accurately run other tests at this time. See debug logs for more details.")
    end
    return test_counts
end