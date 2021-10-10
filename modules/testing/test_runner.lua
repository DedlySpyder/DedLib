local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}

local Test_Group = require("__DedLib__/modules/testing/test_group")

local Test_Runner = {}
Test_Runner.__which = "Test_Runner"

Test_Runner.done = false

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

    local oldGroup = Test_Runner.ALL_TEST_GROUPS.incomplete[testGroup.name]
    if oldGroup then
        Logger:warn(
                "Test Group %s already exists in test runner, overwriting. Old test group: %s",
                testGroup.name,
                oldGroup
        )
    end
    Logger:trace("Adding test group: %s", testGroup)
    Test_Runner.ALL_TEST_GROUPS.incomplete[testGroup.name] = testGroup
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
        -- Map of test name -> Test
        incomplete = {},
        -- Lists
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
    Test_Runner.done = false
end
Test_Runner.reset()

function Test_Runner.on_tick()
    if not Test_Runner.done then
        local runningCount = Test_Runner.run()
        if runningCount > 0 then
            Logger:info("Tick completed, still %s test groups in progress", runningCount)
        else
            Logger:info("Tick completed, no more test groups to run")
            Test_Runner.print_pretty_report()
            Test_Runner.done = true
        end
    end
end

function Test_Runner.run()
    Logger:trace("Running all test groups")
    local allGroups = Test_Runner.ALL_TEST_GROUPS
    local stillRunning = 0
    for _, group in pairs(allGroups.incomplete) do
        group:run()
        Test_Runner.adjust_group(group)

        if not group.done then
            stillRunning = stillRunning + 1
        end
    end
    return stillRunning
end

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
        allGroups.incomplete[group.name] = nil
    end
end

function Test_Runner.print_pretty_report()
    Logger:info("")
    Logger:info("Finished running tests:")

    local allCounts = Test_Runner.ALL_TEST_GROUPS_COUNTS

    local externalSucceededCount = Test_Runner.EXTERNAL_RESULT_COUNTS["succeeded"]
    local externalSkippedCount = Test_Runner.EXTERNAL_RESULT_COUNTS["skipped"]
    local externalFailedCount = Test_Runner.EXTERNAL_RESULT_COUNTS["failed"]

    local succeededCount = externalSucceededCount + allCounts["succeeded"]
    local skippedCount = externalSkippedCount + allCounts["skipped"]
    local failedCount = externalFailedCount + allCounts["failed"]

    Logger:info("    %d succeeded", succeededCount)
    if skippedCount > 0 then
        Logger:info("    %d skipped", skippedCount)
    end
    Logger:info("    %d failed", failedCount)

    if externalSucceededCount > 0 or externalSkippedCount > 0 or externalFailedCount > 0 then
        Logger:info("      External source counts (included in above counts):")
        Logger:info("        %d from external sources", externalSucceededCount)
        Logger:info("        %d from external sources", externalSkippedCount)
        Logger:info("        %d from external sources", externalFailedCount)
    end

    if not Logger:will_print_for_level("debug") then
        Logger:info("")
        Logger:info("Enable debug logging for more information.")
    end

    local allTestGroups = Test_Runner.ALL_TEST_GROUPS
    for _, group in ipairs(allTestGroups["skipped"]) do
        group:print_to_logger()
    end

    for _, group in ipairs(allTestGroups["completed"]) do
        group:print_to_logger()
    end
end


return Test_Runner
