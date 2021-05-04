-- Yes, this is a group of tests for the tester
local Logger = require("modules/logger").create("Tester_Test")
local Tester = require("modules/tester")

local test_assert_counts = {success = 0, failed = 0}
local test_assert_equals = function(x, y, assertMessage, wantSuccess)
    local s, e = pcall(function() Tester.assert_equals(x, y, assertMessage) end)
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

    Logger.trace("Loading tests into tester:")
    Tester.add_test(function() Logger.info("Good single test, unnamed") end)
    Tester.add_test(function() Logger.info("Good single test, named") end, "good single test")
    Tester.add_test(function()
        Logger.info("Bad single test, unnamed")
        error("i failed")
    end)
    Tester.add_test(function()
        Logger.info("Bad single test, named")
        error("i failed")
    end, "bad single test")
    Tester.add_test(function()
        Logger.info("Bad single test, assert failure")
        assert(false)
    end, "assert failure")

    Tester.add_tests({
        test_good = function()
            Logger.info("Good multi test, unnamed")
        end,
        test_bad = function()
            Logger.info("bad multi test, unnamed")
            error("i failed")
        end
    })
    Tester.add_tests({
        test_good = function()
            Logger.info("Good multi test, named")
        end,
        test_bad = function()
            Logger.info("bad multi test, named")
            error("i failed")
        end
    }, "mixed multi test")

    Tester.add_tests({
        test_bad = function()
            Logger.info("duplicate tester")
            error("i failed")
        end
    }, "duplicate")
    Tester.add_tests({
        test_bad = function()
            Logger.info("duplicate tester")
            error("i failed")
        end
    }, "duplicate")
    Tester.add_tests({
        test_bad = function()
            Logger.info("duplicate tester")
            error("i failed")
        end
    }, "duplicate")

    Tester.add_tests({
        SHOULD_NOT_SEE_THIS_FUNC = function()
            Logger.error("NOT A TEST")
        end
    }, "NO TESTS FOR ME")

    Tester.add_tests({
        test_good = function()
            Logger.info("Good test for some ignored tester")
        end,
        SHOULD_NOT_SEE_THIS_FUNC = function()
            Logger.error("NOT A TEST")
        end
    }, "one test for me")

    Logger.trace("Running tester")
    local actualCounts = Tester.run()

    -- Reporting
    Logger.debug("Final test assert_equals counts: " .. serpent.line(test_assert_counts))

    local expectedTestCounts = serpent.line({failed = 8, success = 5})
    local actualTestCounts = serpent.line(actualCounts)
    Logger.debug("Expected results of tester run: " .. expectedTestCounts)
    Logger.debug("Actual results of tester run: " .. actualTestCounts)

    if expectedTestCounts ~= actualTestCounts or test_assert_counts["failed"] > 0 then
        error("Tester tests are failing, cannot accurately run other tests at this time. See debug logs for more details.")
    end
end
