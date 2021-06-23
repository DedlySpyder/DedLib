-- Yes, this is a group of tests for the tester
local Logger = require("modules/logger").create("Tester_Test")
local Tester = require("modules/testing/tester")
local Util = require("modules/util")


local test_validations = {}
local test_results = {results = {}} -- Tester.run() return value will be loaded into ["results"] before validations are run


local addValidationForBasicAddTest = function(validationName, testerName, testName, expectedResult, errorMessage)
    test_validations[validationName] = function()
        local resultsKey = expectedResult -- Keep this value if it's a string, otherwise reassign it
        if expectedResult == true then
            resultsKey = "succeeded"
        elseif expectedResult == false then
            resultsKey = "failed"
        end

        local testerResults = test_results["results"]["testers"][testerName]
        local testResult = testerResults["tests"][testName]

        Tester.Assert.assert_equals(testName, testResult.name, "Test <name> assert, failed")
        Tester.Assert.assert_equals(expectedResult, testResult.result, "Test <result> assert, failed")
        Tester.Assert.assert_starts_with("__DedLib__/tests/testing/tester.lua:", testResult.test_location, "Test <result> assert, failed")
        Tester.Assert.assert_contains_exactly(
                testResult,
                testerResults[resultsKey],
                string.format("Tester %s list contains assert, failed", resultsKey)
        )
        Tester.Assert.assert_contains_exactly(
                testResult,
                test_results["results"][resultsKey],
                string.format("Main %s list contains assert, failed", resultsKey)
        )

        -- Only check for failures & skipped
        if expectedResult ~= true then
            Tester.Assert.assert_ends_with(errorMessage, testResult.error, "Test <error> assert, failed")
        end
    end
end


return function()
    -- Tester Add Test(s) Tests
    Logger.trace("Loading tests into tester:")
    Tester.add_test(function() Logger.info("Successful single test, unnamed") end)
    addValidationForBasicAddTest(
            "add_test_successful_unnamed",
            "Single Test #0 Tester",
            "Single Test #0",
            true
    )

    Tester.add_test(function() Logger.info("Successful single test, named") end, "success single test")
    addValidationForBasicAddTest(
            "add_test_successful_named",
            "success single test Tester",
            "success single test",
            true
    )

    Tester.add_test(function() Logger.info("Successful single test, named, missing \"test\" in name") end, "success single incomplete name")
    addValidationForBasicAddTest(
            "add_test_unsuccessful_named_missing_test",
            "success single incomplete name Test Tester",
            "success single incomplete name Test",
            true
    )

    Tester.add_test(function()
        Logger.info("Failed single test, unnamed")
        error("Failed single test, unnamed")
    end)
    addValidationForBasicAddTest(
            "add_test_failed_unnamed",
            "Single Test #3 Tester",
            "Single Test #3",
            false,
            "Failed single test, unnamed"
    )

    Tester.add_test(function()
        Logger.info("Failed single test, named")
        error("Failed single test, named")
    end, "fail single test")
    addValidationForBasicAddTest(
            "add_test_failed_named",
            "fail single test Tester",
            "fail single test",
            false,
            "Failed single test, named"
    )

    Tester.add_test(function()
        Logger.info("Failed single test, assert failure")
        assert(false)
    end, "fail assert test")
    addValidationForBasicAddTest(
            "add_test_failed_assert",
            "fail assert test Tester",
            "fail assert test",
            false,
            "assertion failed!"
    )

    Tester.add_tests({
        success_test = function()
            Logger.info("Successful multi test, unnamed")
        end,
        fail_test = function()
            Logger.info("Failed multi test, unnamed")
            error("Failed multi test, unnamed")
        end
    })
    addValidationForBasicAddTest(
            "add_tests_unnamed_multi_tester_success",
            "Unnamed Tester #6",
            "success_test",
            true
    )
    addValidationForBasicAddTest(
            "add_tests_unnamed_multi_tester_fail",
            "Unnamed Tester #6",
            "fail_test",
            false,
            "Failed multi test, unnamed"
    )


    Tester.add_tests({
        success_test = function()
            Logger.info("Successful multi test, named")
        end,
        fail_test = function()
            Logger.info("Failed multi test, named")
            error("Failed multi test, named")
        end
    }, "mixed multi test")
    addValidationForBasicAddTest(
            "add_tests_named_multi_tester_success",
            "mixed multi test",
            "success_test",
            true
    )
    addValidationForBasicAddTest(
            "add_tests_unnamed_multi_tester_fail",
            "mixed multi test",
            "fail_test",
            false,
            "Failed multi test, named"
    )

    Tester.add_tests({
        fail_test = function()
            Logger.info("Failed duplicate tester")
            error("Failed duplicate tester")
        end
    }, "duplicate")
    addValidationForBasicAddTest(
            "add_tests_duplicate_0_tester_fail",
            "duplicate",
            "fail_test",
            false,
            "Failed duplicate tester"
    )

    Tester.add_tests({
        fail_test = function()
            Logger.info("Failed duplicate-1 tester")
            error("Failed duplicate-1 tester")
        end
    }, "duplicate")
    addValidationForBasicAddTest(
            "add_tests_duplicate_1_tester_fail",
            "duplicate-1",
            "fail_test",
            false,
            "Failed duplicate-1 tester"
    )

    Tester.add_tests({
        fail_test = function()
            Logger.info("Failed duplicate-2 tester")
            error("Failed duplicate-2 tester")
        end
    }, "duplicate")
    addValidationForBasicAddTest(
            "add_tests_duplicate_2_tester_fail",
            "duplicate-2",
            "fail_test",
            false,
            "Failed duplicate-2 tester"
    )


    Tester.add_tests({
        SHOULD_NOT_SEE_THIS_FUNC = function()
            Logger.error("NOT A TEST")
        end
    }, "NO TESTS FOR ME")
    test_validations["add_tests_no_tests_tester_missing"] = function()
        local testerName = "NO TESTS FOR ME"
        local testName = "SHOULD_NOT_SEE_THIS_FUNC"

        -- Whole tester is missing when there aren't any tests for it
        Tester.Assert.assert_equals(nil, test_results["results"]["testers"][testerName], "Test missing test, found")
    end

    Tester.add_tests({
        success_test = function()
            Logger.info("Successful test for some ignored tester")
        end,
        SHOULD_NOT_SEE_THIS_FUNC = function()
            Logger.error("NOT A TEST")
        end
    }, "one test for me")
    addValidationForBasicAddTest(
            "add_tests_one_test_tester_success",
            "one test for me",
            "success_test",
            true
    )
    test_validations["add_tests_one_test_tester_missing"] = function()
        local testerName = "one test for me"
        local testName = "SHOULD_NOT_SEE_THIS_FUNC"

        Tester.Assert.assert_equals(nil, test_results["results"]["testers"][testerName][testName], "Test missing test, found")
    end

    --TODO - test add_tests with testerData

    -- Before/After Tests
    -- Note: returned value tests do not validate the value at this point, as they just print it currently
    Tester.add_tests({
        test_successful_before_func = {
            func = function() end,
            before = function() Logger.info("Successful before func run") end
        },
        test_successful_before_return_func = {
            func = function() end,
            before = function() Logger.info("Successful before func run with return"); return "returned_value" end
        },
        test_successful_before_func_args = {
            func = function() end,
            before = function(value1, value2)
                if value1 == nil or value2 == nil then error("Missing arg(s) for before func: <" .. value1 .. "><" .. value2 .. ">") end
                Logger.info("Successful before func run")
            end,
            beforeArgs = {"foo", "bar"}
        },
        test_successful_before_return_func_args = {
            func = function() end,
            before = function(value1, value2)
                if value1 == nil or value2 == nil then error("Missing arg(s) for before func: <" .. value1 .. "><" .. value2 .. ">") end
                Logger.info("Successful before func run")
                return "returned_value"
            end,
            beforeArgs = {"foo", "bar"}
        },
        test_failed_before_func = {
            func = function() end,
            before = function() error("Failed before func run") end
        },
        test_failed_before_func_args = {
            func = function() end,
            before = function(value1, value2)
                if value1 == nil or value2 == nil then error("Missing arg(s) for before func: <" .. value1 .. "><" .. value2 .. ">") end
                error("Failed before func run, with args")
            end,
            beforeArgs = {"foo", "bar"}
        }
    }, "before_func_tester")
    addValidationForBasicAddTest(
            "test_successful_before_func",
            "before_func_tester",
            "test_successful_before_func",
            true
    )
    addValidationForBasicAddTest(
            "test_successful_before_return_func",
            "before_func_tester",
            "test_successful_before_return_func",
            true
    )
    addValidationForBasicAddTest(
            "test_successful_before_func_args",
            "before_func_tester",
            "test_successful_before_func_args",
            true
    )
    addValidationForBasicAddTest(
            "test_successful_before_return_func_args",
            "before_func_tester",
            "test_successful_before_return_func_args",
            true
    )
    addValidationForBasicAddTest(
            "test_failed_before_func",
            "before_func_tester",
            "test_failed_before_func",
            "skipped",
            "Failed before func run"
    )
    addValidationForBasicAddTest(
            "test_failed_before_func_args",
            "before_func_tester",
            "test_failed_before_func_args",
            "skipped",
            "Failed before func run, with args"
    )

    local afterFuncTesterTests = {
        test_successful_after_func = {
            func = function() end,
            after = function() Logger.info("Successful after func run") end
        },
        test_successful_after_return_func = {
            func = function() end,
            after = function() Logger.info("Successful after func run with return"); return "returned_value" end
        },
        test_successful_after_func_args = {
            func = function() end,
            after = function(value1, value2)
                if value1 == nil or value2 == nil then error("Missing arg(s) for after func: <" .. value1 .. "><" .. value2 .. ">") end
                Logger.info("Successful after func run")
            end,
            afterArgs = {"foo", "bar"}
        },
        test_successful_after_return_func_args = {
            func = function() end,
            after = function(value1, value2)
                if value1 == nil or value2 == nil then error("Missing arg(s) for after func: <" .. value1 .. "><" .. value2 .. ">") end
                Logger.info("Successful after func run")
                return "returned_value"
            end,
            afterArgs = {"foo", "bar"}
        },
        test_failed_after_func = {
            func = function() end,
            after = function() error("Failed after func run") end
        },
        test_failed_after_func_args = {
            func = function() end,
            after = function(value1, value2)
                if value1 == nil or value2 == nil then error("Missing arg(s) for after func: <" .. value1 .. "><" .. value2 .. ">") end
                error("Failed after func run, with args")
            end,
            afterArgs = {"foo", "bar"}
        }
    }
    Tester.add_tests(afterFuncTesterTests, "after_func_tester")
    -- After tests don't have an impact on the status of the test
    for name, _ in pairs(afterFuncTesterTests) do
        addValidationForBasicAddTest(
                name,
                "after_func_tester",
                name,
                true
        )
    end


    -- Before Tester Tests
    Tester.add_tests({
        test = function() end
    }, {
        name = "before_tester_func_tester",
        before = function() Logger.info("Successful before tester func run") end
    })
    addValidationForBasicAddTest(
            "before_tester_func_tester",
            "before_tester_func_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "before_tester_return_func_tester",
        before = function() Logger.info("Successful before tester func run"); return "returned_value" end
    })
    addValidationForBasicAddTest(
            "before_tester_return_func_tester",
            "before_tester_return_func_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "before_tester_func_args_tester",
        before = function(value1, value2)
            if value1 == nil or value2 == nil then error("Missing arg(s) for before tester func: <" .. value1 .. "><" .. value2 .. ">") end
            Logger.info("Successful before tester func run")
        end,
        beforeArgs = {"foo", "bar"}
    })
    addValidationForBasicAddTest(
            "before_tester_func_args_tester",
            "before_tester_func_args_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "before_tester_return_func_args_tester",
        before = function(value1, value2)
            if value1 == nil or value2 == nil then error("Missing arg(s) for before tester func: <" .. value1 .. "><" .. value2 .. ">") end
            Logger.info("Successful before tester func run")
            return "returned_value"
        end,
        beforeArgs = {"foo", "bar"}
    })
    addValidationForBasicAddTest(
            "before_tester_return_func_args_tester",
            "before_tester_return_func_args_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "before_tester_func_failed_tester",
        before = function() error("Failed before tester func run") end
    })
    addValidationForBasicAddTest(
            "before_tester_func_failed_tester",
            "before_tester_func_failed_tester",
            "test",
            "skipped",
            "Failed before tester func run"
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "before_tester_func_failed_args_tester",
        before = function(value1, value2)
            if value1 == nil or value2 == nil then error("Missing arg(s) for before tester func: <" .. value1 .. "><" .. value2 .. ">") end
            Logger.info("Successful before tester func run")
            error("Failed before tester func run, with args")
        end,
        beforeArgs = {"foo", "bar"}
    })
    addValidationForBasicAddTest(
            "before_tester_func_failed_args_tester",
            "before_tester_func_failed_args_tester",
            "test",
            "skipped",
            "Failed before tester func run, with args"
    )


    -- After Tester tests
    Tester.add_tests({
        test = function() end
    }, {
        name = "after_tester_func_tester",
        after = function() Logger.info("Successful after tester func run") end
    })
    addValidationForBasicAddTest(
            "after_tester_func_tester",
            "after_tester_func_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "after_tester_return_func_tester",
        after = function() Logger.info("Successful after tester func run"); return "returned_value" end
    })
    addValidationForBasicAddTest(
            "after_tester_return_func_tester",
            "after_tester_return_func_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "after_tester_func_args_tester",
        after = function(value1, value2)
            if value1 == nil or value2 == nil then error("Missing arg(s) for after tester func: <" .. value1 .. "><" .. value2 .. ">") end
            Logger.info("Successful after tester func run")
        end,
        afterArgs = {"foo", "bar"}
    })
    addValidationForBasicAddTest(
            "after_tester_func_args_tester",
            "after_tester_func_args_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "after_tester_return_func_args_tester",
        after = function(value1, value2)
            if value1 == nil or value2 == nil then error("Missing arg(s) for after tester func: <" .. value1 .. "><" .. value2 .. ">") end
            Logger.info("Successful after tester func run")
            return "returned_value"
        end,
        afterArgs = {"foo", "bar"}
    })
    addValidationForBasicAddTest(
            "after_tester_return_func_args_tester",
            "after_tester_return_func_args_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "after_tester_func_failed_tester",
        after = function() error("Failed after tester func run") end
    })
    addValidationForBasicAddTest(
            "after_tester_func_failed_tester",
            "after_tester_func_failed_tester",
            "test",
            true
    )

    Tester.add_tests({
        test = function() end
    }, {
        name = "after_tester_func_failed_args_tester",
        after = function(value1, value2)
            if value1 == nil or value2 == nil then error("Missing arg(s) for after tester func: <" .. value1 .. "><" .. value2 .. ">") end
            Logger.info("Successful after tester func run")
            error("Failed after tester func run, with args")
        end,
        afterArgs = {"foo", "bar"}
    })
    addValidationForBasicAddTest(
            "after_tester_func_failed_args_tester",
            "after_tester_func_failed_args_tester",
            "test",
            true
    )



    Logger.trace("Running tester")
    test_results["results"] = Tester.run()

    -- Validations
    local count = {succeeded = 0, failed = 0}
    local increment_failed = function()
        count["failed"] = count["failed"] + 1
    end
    local increment_succeeded = function()
        count["succeeded"] = count["succeeded"] + 1
    end

    for name, func in pairs(test_validations) do
        Logger.debug("Running validation for: %s", name)
        local s, err = pcall(func)
        if not s then
            Logger.fatal("Failed validation of Tester test %s with error: %s", name, err)
            increment_failed()
        else
            increment_succeeded()
        end
    end

    Logger.info("Tester validation results: %s", count)
    if count["failed"] > 0 then
        error("Tester validations are failing, cannot accurately run other tests at this time. See debug logs for more details.")
    end
    return count
end
