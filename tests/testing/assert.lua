local Logger = require("modules/logger").create("Assert_Testing")
local Assert = require("modules/testing/assert")
local Util = require("modules/util")

local test_counts = { succeeded = 0, failed = 0}

local increment_test_failed = function()
    test_counts["failed"] = test_counts["failed"] + 1
end

local increment_test_succeeded = function()
    test_counts["succeeded"] = test_counts["succeeded"] + 1
end

local test_assert_equals = function(x, y, assertMessage, wantSuccess)
    local s, e = pcall(function() Assert.assert_equals(x, y, assertMessage) end)
    if s then
        if wantSuccess then
            Logger.debug("Expected success, and got success <" .. tostring(x) .. "> to <" .. tostring(y) .. ">")
            increment_test_succeeded()
        else
            Logger.fatal("Expected failure, but got success <" .. tostring(x) .. "> to <" .. tostring(y) .. ">")
            increment_test_failed()
        end
    else
        if wantSuccess then
            Logger.fatal("Expected success, but got failure <" .. tostring(x) .. "> to <" .. tostring(y) .. ">")
            Logger.trace(e)
            increment_test_failed()
        else
            Logger.debug("Expected failure, and got failure <" .. tostring(x) .. "> to <" .. tostring(y) .. ">")
            Logger.trace(e)
            increment_test_succeeded()
        end
    end
end

return function()
    local testAssertFailed = function(message, assertType, assertVar1Name, assertVar1Value, assertVar2Name, assertVar2Value, testErrorFunc)
        local s, e = pcall(Assert._fail, message, assertType, assertVar1Name, assertVar1Value, assertVar2Name, assertVar2Value)
        if s then -- This should always fail
            Logger.fatal("Assert._fail test didn't error as expected")
            increment_test_failed()
        elseif e == nil then
            Logger.fatal("Assert._fail missing error")
            increment_test_failed()
        elseif e["message"] == nil then
            Logger.fatal("Assert._fail missing message")
            increment_test_failed()
        elseif e["stacktrace"] == nil then
            Logger.fatal("Assert._fail missing stacktrace")
            increment_test_failed()
        else
            if testErrorFunc and not testErrorFunc(e) then
                Logger.fatal("Failed error check for Assert._fail: %s", e)
                increment_test_failed()
            end
        end
        increment_test_succeeded()
    end
    Logger.debug("Testing Assert._fail()")
    Logger.trace("Testing Assert._fail() with error message")
    testAssertFailed("err_msg", "t_type", "var1", "val1", "var2", "val2", function(e)
        return Util.String.starts_with(e["message"], "err_msg\n")
    end)

    Logger.trace("Testing Assert._fail() without error message")
    testAssertFailed(nil, "t_type", "var1", "val1", "var2", "val2", function(e)
        return Util.String.starts_with(e["message"], "Assertion ")
    end)

    Logger.trace("Testing Assert._fail() with var2 & val2")
    testAssertFailed("err_msg", "t_type", "var1", "val1", "var2", "val2", function(e)
        return string.find(e["message"], "var2")
    end)

    Logger.trace("Testing Assert._fail() without var2 & val2")
    testAssertFailed("err_msg", "t_type", "var1", "val1", nil, nil, function(e)
        return string.find(e["message"], "var2") == nil
    end)


    Logger.trace("Testing assert_equals string, nil message first")
    test_assert_equals(
            "foo",
            "bar",
            nil,
            false
    )
    test_assert_equals(
            "foo",
            "bar",
            "string different",
            false
    )
    test_assert_equals(
            "foo",
            "foo",
            "string same",
            true
    )

    Logger.trace("Testing assert_equals number")
    test_assert_equals(
            42,
            1,
            "number different",
            false
    )
    test_assert_equals(
            42,
            42,
            "number same",
            true
    )

    Logger.trace("Testing assert_equals table")
    test_assert_equals(
            { foo = "bar"},
            { foo = "quz"},
            "table different",
            false
    )
    test_assert_equals(
            { foo = "bar"},
            { foo = "bar"},
            "table same",
            true
    )

    -- Other tests can depend on Assert working properly, so fail early if it is failing
    Logger.info("Assert validation results: %s", test_counts)
    if test_counts["failed"] > 0 then
        error("Assert validations are failing, cannot accurately run other tests at this time. See debug logs for more details.")
    end
    return test_counts
end