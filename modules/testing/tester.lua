local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}

local TestGroup = require("__DedLib__/modules/testing/test_group")

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
function Tester.add_external_results(results)
    Tester._EXTERNAL_RESULTS = results
end

function Tester.add_test(data, name)
    if not name then name = "Single Test #" .. #Tester._TESTERS end
    if not string.find(string.lower(name), "test") then
        name = name .. " Test"
    end
    Logger:debug("Adding single test %s", name)
    return Tester.add_tests({[name] = data}, name .. " Tester")
end

function Tester.add_tests(tests, testerData) -- TODO - deprecate?
    if type(testerData) ~= "table" then testerData = {name = testerData} end -- Assume non-table is just a name
    testerData.tests = tests
    TestGroup.create(testerData)
end



function Tester.create_basic_test(testingFunc, expectedValue, ...)
    local testArgs = table.pack(...)
    return function()
        local actual = testingFunc(unpack(testArgs))
        Tester.Assert.assert_equals(expectedValue, actual, "Input failed for arg: " .. serpent.line(testArg))
    end
end


function Tester.run()
    TestGroup.run_all()
    Tester._report_failed()
end

function Tester._report_failed()
    Logger:info("")
    Logger:info("Finished running tests:")

    local succeededCount = (Tester._EXTERNAL_RESULTS["succeeded"] or 0) + TestGroup._all_counts["succeeded"]
    local skippedCount = (Tester._EXTERNAL_RESULTS["skipped"] or 0) + TestGroup._all_counts["skipped"]
    local failedCount = (Tester._EXTERNAL_RESULTS["failed"] or 0) + TestGroup._all_counts["failed"]

    Logger:info("    %d succeeded", succeededCount)
    if skippedCount > 0 then
        Logger:info("    %d skipped", skippedCount)
    end
    Logger:info("    %d failed", failedCount)

    if not Logger:will_print_for_level("debug") then
        Logger:info("")
        Logger:info("Enable debug logging for more information.")
    end

    for _, group in ipairs(TestGroup._all_groups["skipped"]) do
        group:print_to_logger()
    end

    for _, group in ipairs(TestGroup._all_groups["completed"]) do
        group:print_to_logger()
    end
end

return Tester