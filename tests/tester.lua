-- Yes, this is a group of tests for the tester
local Logger = require("modules/logger").create("Tester_Test")
local Tester = require("modules/tester")

require("util") -- Core Factorio lib

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

    local function mockValidEntityTester(testingFor, values, expectedEntity)
        Logger.trace("Testing get_mock_valid_entity for %s with values: %s", testingFor, values)
        local mock = Tester.get_mock_valid_entity(values)
        Tester.assert_equals(expectedEntity, mock, "Mock valid entity for " .. testingFor .. " failed: " .. serpent.line(values))
    end

    mockValidEntityTester("empty arg", nil, {valid = true})
    mockValidEntityTester("other values", {foo = "bar"}, {valid = true, foo = "bar"})

    local mockValidEntityFatalStatus, mockValidEntityFatalMessage =
        pcall(mockValidEntityTester, "non-table fatal error", "foobar", "THIS SHOULDN'T EVEN SEE THE ASSERT")
    mockValidEntityFatalMessage = util.split(mockValidEntityFatalMessage, ":")[3]
    if mockValidEntityFatalStatus or mockValidEntityFatalMessage ~= " Values for mock entity is not a table" then
        error(string.format("Fatal mock valid entity test failed, status is <%s>, message is <%s>",
                tostring(mockValidEntityFatalStatus),
                mockValidEntityFatalMessage
        ))
    end

    -- TODO - better testing for the tester, need to return the list of pass/failed tests (will eventually be a UI anyways)
    --          - So I can actually verify individual failures/successes
    --      - Test for missing "test" in name in add_test

    Logger.trace("Loading tests into tester:")
    Tester.add_test(function() Logger.info("Good single test, unnamed") end) -- Single Test #0 -- pass
    Tester.add_test(function() Logger.info("Good single test, named") end, "good single test") -- good single test -- pass
    Tester.add_test(function() -- Single Test #2 -- fail
        Logger.info("Bad single test, unnamed")
        error("i failed")
    end)
    Tester.add_test(function() -- bad single test -- fail
        Logger.info("Bad single test, named")
        error("i failed")
    end, "bad single test")
    Tester.add_test(function() -- assert failure -- fail
        Logger.info("Bad single test, assert failure")
        assert(false)
    end, "assert failure test")

    Tester.add_tests({
        test_good = function() -- test_good -- pass
            Logger.info("Good multi test, unnamed")
        end,
        test_bad = function() -- test_bad -- fail
            Logger.info("bad multi test, unnamed")
            error("i failed")
        end
    })
    Tester.add_tests({
        test_good = function() -- test_good -- pass
            Logger.info("Good multi test, named")
        end,
        test_bad = function() -- test_bad -- fail
            Logger.info("bad multi test, named")
            error("i failed")
        end
    }, "mixed multi test")

    Tester.add_tests({
        test_bad = function() -- test_bad -- fail
            Logger.info("duplicate tester")
            error("i failed")
        end
    }, "duplicate")
    Tester.add_tests({
        test_bad = function() -- test_bad -- fail
            Logger.info("duplicate tester")
            error("i failed")
        end
    }, "duplicate")
    Tester.add_tests({
        test_bad = function() -- test_bad -- fail
            Logger.info("duplicate tester")
            error("i failed")
        end
    }, "duplicate")

    Tester.add_tests({
        SHOULD_NOT_SEE_THIS_FUNC = function() -- SHOULD_NOT_SEE_THIS_FUNC -- no-op
            Logger.error("NOT A TEST")
        end
    }, "NO TESTS FOR ME")

    Tester.add_tests({
        test_good = function() -- test_good -- pass
            Logger.info("Good test for some ignored tester")
        end,
        SHOULD_NOT_SEE_THIS_FUNC = function() -- SHOULD_NOT_SEE_THIS_FUNC -- no-op
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
