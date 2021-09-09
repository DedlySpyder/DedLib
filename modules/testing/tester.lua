local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}

local Test_Runner = require("__DedLib__/modules/testing/test_runner")

local Tester = {}

Tester.Assert = require("__DedLib__/modules/testing/assert")
Tester.Mock = require("__DedLib__/modules/testing/mock")

Tester._EXTERNAL_RESULTS = {}

--[[
TODO - notes on tester
if error has {message = message, stacktrace = debug.traceback()}
then the message will always be printed on an error, but the stacktrace will be saved for debug mode
]]--

--[[ TODO for now
TODO -- Look at the DedTester mod for the actual latest of this

multi-tick tests? (allow for setting a property on the test (will have to keep the table they provide) that will flag the test as still in progress
test dependencies on other tests?
export to log and external shitty UI?
]]--

--[[ Docs WIP
to run a test that does not resolve right away, set up everything in `before` and run validations in `func`, if the test
couldn't do the validations (like your entity doesn't exist or something), then just return false and it will run again next tick if possible
]]--

-- Expects: {succeeded = integer, skipped = integer, failed = integer}
function Tester.add_external_results(results) -- TODO - move to Test_Runner
    Tester._EXTERNAL_RESULTS = results
end

function Tester.add_test(data, name)
    Test_Runner.add_test(data, name)
end

function Tester.add_tests(tests, testerData) -- TODO - deprecate?
    if type(testerData) ~= "table" then testerData = {name = testerData} end -- Assume non-table is just a name
    testerData.tests = tests
    Test_Runner.add_test_group(testerData)
end



function Tester.create_basic_test(testingFunc, expectedValue, ...) -- TODO - put this under Test? or just don't have it because it complicates the stacktrace? I think that last one
    local testArgs = table.pack(...)
    return function()
        local actual = testingFunc(unpack(testArgs))
        Tester.Assert.assert_equals(expectedValue, actual, "Input failed for arg: " .. serpent.line(testArg))
    end
end


function Tester.run()
    Test_Runner.run()
    Tester._report_failed()
end

function Tester._report_failed() -- TODO - move to Test_Runner
    Logger:info("")
    Logger:info("Finished running tests:")

    local allCounts = Test_Runner.ALL_TEST_GROUPS_COUNTS
    local succeededCount = (Tester._EXTERNAL_RESULTS["succeeded"] or 0) + allCounts["succeeded"]
    local skippedCount = (Tester._EXTERNAL_RESULTS["skipped"] or 0) + allCounts["skipped"]
    local failedCount = (Tester._EXTERNAL_RESULTS["failed"] or 0) + allCounts["failed"]

    Logger:info("    %d succeeded", succeededCount)
    if skippedCount > 0 then
        Logger:info("    %d skipped", skippedCount)
    end
    Logger:info("    %d failed", failedCount)

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

return Tester