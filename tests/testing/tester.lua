-- Yes, this is a group of tests for the tester
local Logger = require("modules/logger").create("Tester_Test")
local Tester = require("modules/testing/tester")
local Util = require("modules/util")


local test_validations = {}
local test_results = {results = {}} -- Tester.run() return value will be loaded into ["results"] before validations are run

return function()
    -- Tester Add Test(s) Tests
    local addValidationForBasicAddTest = function(validationName, testerName, testName, expectedResult, errorMessage)
        test_validations[validationName] = function()
            local successOrFail = Util.ternary(expectedResult, "succeeded", "failed")
            local testerResults = test_results["results"]["testers"][testerName]
            local testResult = testerResults["tests"][testName]

            Tester.Assert.assert_equals(testName, testResult.name, "Test <name> assert, failed")
            Tester.Assert.assert_equals(expectedResult, testResult.result, "Test <result> assert, failed")
            Tester.Assert.assert_starts_with("__DedLib__/tests/testing/tester.lua:", testResult.test_location, "Test <result> assert, failed")
            Tester.Assert.assert_contains_exactly(
                    testResult,
                    testerResults[successOrFail],
                    string.format("Tester %s list contains assert, failed", successOrFail)
            )
            Tester.Assert.assert_contains_exactly(
                    testResult,
                    test_results["results"][successOrFail],
                    string.format("Main %s list contains assert, failed", successOrFail)
            )

            -- Only check for failures
            if not expectedResult then
                Tester.Assert.assert_ends_with(errorMessage, testResult.error, "Test <error> assert, failed")
            end
        end
    end
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
