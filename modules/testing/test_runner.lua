local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}

local Test_Group = require("__DedLib__/modules/testing/test_group")

local Test_Runner = {}
Test_Runner.__which = "Test_Runner"

Test_Runner.ALL_TEST_GROUPS = {}
Test_Runner.ALL_TEST_GROUPS_COUNTS = {}
Test_Runner.EXTERNAL_RESULT_COUNTS = {}


-- Name first, unless the only arg is the test, then continue with an unnamed test
-- test can be a single test or a list of tests
function Test_Runner.add_test(test, name)
    Test_Runner.add_test_group({name = name, tests = {test}})
end

function Test_Runner.add_test_group(testGroup)
    if not (type(testGroup) == "table" and testGroup.__which == "Test_Group") then
        testGroup = Test_Group.create(testGroup)
    end
    Logger:trace("Adding test group: %s", testGroup)
    table.insert(Test_Runner.ALL_TEST_GROUPS.incomplete, testGroup)
end

function Test_Runner.add_external_results(resultCounts)
    if type(resultCounts) == "table" then
        Logger:trace("Adding external results: %s", resultCounts)
        Test_Runner.EXTERNAL_RESULT_COUNTS.skipped = Test_Runner.EXTERNAL_RESULT_COUNTS.skipped + (resultCounts.skipped or 0)
        Test_Runner.EXTERNAL_RESULT_COUNTS.failed = Test_Runner.EXTERNAL_RESULT_COUNTS.failed + (resultCounts.failed or 0)
        Test_Runner.EXTERNAL_RESULT_COUNTS.succeeded = Test_Runner.EXTERNAL_RESULT_COUNTS.succeeded + (resultCounts.succeeded or 0)
    else
        Logger:warn("Invalid external results: %s", resultCounts)
    end
end

function Test_Runner.reset()
    Logger:trace("Resetting test groups")
    Test_Runner.ALL_TEST_GROUPS = {
        incomplete = {},
        skipped = {},
        completed = {}
    }

    Test_Runner.ALL_TEST_GROUPS_COUNTS = {
        skipped = 0,
        failed = 0,
        succeeded = 0
    }

    Test_Runner.EXTERNAL_RESULT_COUNTS = {
        skipped = 0,
        failed = 0,
        succeeded = 0
    }
end
Test_Runner.reset()

function Test_Runner.run()
    Logger:trace("Running all test groups")
    local allGroups = Test_Runner.ALL_TEST_GROUPS
    for _, group in ipairs(allGroups.incomplete) do
        group:run()
        Test_Runner.adjust_group(group)
    end
    allGroups.incomplete = {}
end

-- Relies on .run() to remove from incomplete
-- This is fine with the current logic
function Test_Runner.adjust_group(group)
    local allGroups = Test_Runner.ALL_TEST_GROUPS
    local allCounts = Test_Runner.ALL_TEST_GROUPS_COUNTS

    if group.state == "completed" then
        table.insert(allGroups.completed, group)
    elseif group.state == "skipped" then
        table.insert(allGroups.skipped, group)
    end
    if group.done then
        local tests = group.tests
        allCounts.skipped = allCounts.skipped + #tests.skipped
        allCounts.failed = allCounts.failed + #tests.failed
        allCounts.succeeded = allCounts.succeeded + #tests.succeeded
    end
end


return Test_Runner
