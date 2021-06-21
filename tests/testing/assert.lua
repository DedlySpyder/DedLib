local Logger = require("modules/logger").create("Assert_Testing")
local Assert = require("modules/testing/assert")
local Util = require("modules/util")

local test_assert_counts = {success = 0, failed = 0}
local test_assert_equals = function(x, y, assertMessage, wantSuccess)
    local s, e = pcall(function() Assert.assert_equals(x, y, assertMessage) end)
    if s then
        if wantSuccess then
            Logger.info("Expected success, and successfully compared <" .. tostring(x) .. "> to <" .. tostring(y) .. ">")
            test_assert_counts["success"] = test_assert_counts["success"] + 1
        else
            Logger.error("Did not expect success, but successfully compared <" .. tostring(x) .. "> to <" .. tostring(y) .. ">")
            test_assert_counts["failed"] = test_assert_counts["failed"] + 1
        end
    else
        if wantSuccess then
            Logger.error("Expected success, but did not successfully compared <" .. tostring(x) .. "> to <" .. tostring(y) .. ">")
            Logger.trace(e)
            test_assert_counts["failed"] = test_assert_counts["failed"] + 1
        else
            Logger.info("Did not expect success, and did not successfully compared <" .. tostring(x) .. "> to <" .. tostring(y) .. ">")
            Logger.trace(e)
            test_assert_counts["success"] = test_assert_counts["success"] + 1
        end
    end
end

return function()
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

    -- Other tests in here can depend on assert_equals working properly, so fail early if it is failing
    if test_assert_counts["failed"] > 0 then
        error("Tester.Assert.assert_equals() tests are failing, cannot accurately run other tests at this time. See debug logs for more details.")
    end
end