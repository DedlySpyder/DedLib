local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib", prefix = "Tester"}
local Debug = require("__DedLib__/modules/debug")
local Util = require("__DedLib__/modules/util")

local Tester = {}

Tester.Assert = require("assert")
Tester.Mock = require("mock")

--[[
TODO - notes on tester
if error has {message = message, stacktrace = debug.traceback()}
then the message will always be printed on an error, but the stacktrace will be saved for debug mode
]]--

function Tester.reset()
    -- {name = name, tests = {[name] = func}}
    Tester._TESTERS = {}
    Tester._RESULTS = {testers = {}, succeeded = {}, skipped = {}, failed = {}}
end
Tester.reset()

-- Expects: {succeeded = integer, skipped = integer, failed = integer}
function Tester.add_external_results(results)
    Tester._EXTERNAL_RESULTS = results
end

function Tester.add_test(func, name)
    if not name then name = "Single Test #" .. #Tester._TESTERS end
    if not string.find(string.lower(name), "test") then
        name = name .. " Test"
    end
    Logger.debug("Adding single test %s", name)
    return Tester.add_tests({[name] = func}, name .. " Tester")
end

function Tester.add_tests(tests, testerName)
    if type(tests) == "table" then
        local tester = {}
        tester["name"] = testerName or "Unnamed Tester #" .. #Tester._TESTERS

        local testerName = tester["name"]
        Logger.debug("Creating tester for %s", testerName)
        tester["tests"] = {}
        for name, data in pairs(tests) do
            if type(name) == "number" then name = "Test #" .. name end
            if string.find(string.lower(name), "test") then
                if type(data) == "function" then
                    Logger.debug("Adding test " .. name)
                    tester["tests"][name] = {func = data}
                else
                    Logger.debug("Adding test %s with data: %s", name, data)
                    tester["tests"][name] = data -- TODO - fixme - add validation & tests for this
                                                        -- current format: {func, args, generateArgsFunc, generateArgsFuncArgs}
                end
            else
                Logger.debug("Ignoring function " .. name .. ', does not contain the string "test" in name')
            end
        end
        Logger.debug("Done adding tests to %s", testerName)
        if table_size(tester["tests"]) > 0 then
            table.insert(Tester._TESTERS, tester)
        else
            Logger.warn('No tests for %s found. Did the test functions names contain the word "test"?', testerName)
        end
    else
        Logger.error('Failed to add new tests, variable needs to be a table of "test_name" -> test_function')
        if Logger.level_is_less_than("debug") then
            Logger.info("Enable debug logging for more information.")
        else
            Logger.debug(debug.traceback())
            Logger.debug(tests)
        end
    end
end



function Tester.create_basic_test(testingFunc, expectedValue, ...)
    local testArgs = table.pack(...)
    return function()
        local actual = testingFunc(unpack(testArgs))
        Tester.Assert.assert_equals(expectedValue, actual, "Input failed for arg: " .. serpent.line(testArg))
    end
end

function Tester._add_error_to_test_results(testName, error, testResults)
    if error and error["message"] and error["stacktrace"] then
        testResults["error"] = tostring(error["message"])
        testResults["stack"] = error["stacktrace"]
    else
        if type(error) == "table" then
            error = serpent.line(error)
        else
            error = tostring(error)
        end
        testResults["error"] = error
    end
    Logger.error("Test %s failed: %s", testName, testResults["error"])
    return testResults
end

function Tester.run()
    Logger.trace("Running all tests")
    for _, tester in ipairs(Tester._TESTERS) do
        local testerName = tester["name"]
        Logger.debug("Running tester %s", testerName)

        local i = 1
        while Tester._RESULTS["testers"][testerName] do
            Logger.warn("Tester named %s already exists, incrementing to make unique", testerName)
            testerName = tester["name"] .. "-" .. i
            i = i + 1
        end

        local testerIndividualTestResults = {}
        local succeededTests = {}
        local skippedTests = {}
        local failedTests = {}
        local testerResults = {name = testerName, succeeded = succeededTests, failed = failedTests, skipped = skippedTests, tests = testerIndividualTestResults}
        Tester._RESULTS["testers"][testerName] = testerResults

        for name, testData in pairs(tester["tests"]) do -- TODO - fixme - add before/after? (and on tester too while I'm, at it)
            Logger.debug("Running test %s", name)
            local func = testData["func"]
            local funcLine = Debug.get_defined_string(func)
            local testResults = {
                name = name,
                test_location = funcLine
            }

            local beforeFunc = testData["before"]
            if beforeFunc and type(beforeFunc) == "function" then
                Logger.debug("Running before function for %s", name)
                local s, e = pcall(beforeFunc, table.unpack(testData["beforeArgs"] or {}))
                if s then
                    Logger.debug("Successfully completed before function%s", Util.ternary(e ~= nil, ", returned value: " .. serpent.line(e), ""))
                else
                    Logger.error("Before function failed for %s, with error <%s>, skipping run...", name, e)
                    testResults["result"] = "skipped"
                    Tester._add_error_to_test_results(name, e, testResults)
                end
            end

            testerIndividualTestResults[name] = testResults
            if testResults["result"] == "skipped" then
                Logger.info("Test %s skipped", name)
                table.insert(skippedTests, testResults)
                table.insert(Tester._RESULTS["skipped"], testResults)
            else
                local args = testData["args"] or {}
                local genArgsFunc = testData["generateArgsFunc"]
                if genArgsFunc and type(genArgsFunc) == "function" then
                    if testData["generateArgsFuncArgs"] then
                        args = genArgsFunc(table.unpack(testData["generateArgsFuncArgs"]))
                    else
                        args = genArgsFunc()
                    end
                end

                local status, error = pcall(func, table.unpack(args))
                testResults["result"] = status

                if status then
                    Logger.info("Test %s succeeded", name)
                    table.insert(succeededTests, testResults)
                    table.insert(Tester._RESULTS["succeeded"], testResults)
                else
                    Tester._add_error_to_test_results(name, error, testResults)
                    table.insert(failedTests, testResults)
                    table.insert(Tester._RESULTS["failed"], testResults)
                end
            end
        end
    end

    Tester._report_failed()

    -- Reset the tester, but dump the counts in case the end user wants them first
    local results = Tester._RESULTS
    Logger.debug("Resetting tester values")
    Tester.reset()
    return results
end

function Tester._report_failed()
    Logger.info("")
    Logger.info("Finished running tests:")

    local succeededCount = #Tester._RESULTS["succeeded"]
    local skippedCount = #Tester._RESULTS["skipped"]
    local failedCount = #Tester._RESULTS["failed"]
    if Tester._EXTERNAL_RESULTS and Tester._EXTERNAL_RESULTS["succeeded"] and Tester._EXTERNAL_RESULTS["failed"] then
        succeededCount = succeededCount + (Tester._EXTERNAL_RESULTS["succeeded"] or 0)
        skippedCount = skippedCount + (Tester._EXTERNAL_RESULTS["skipped"] or 0)
        failedCount = failedCount + (Tester._EXTERNAL_RESULTS["failed"] or 0)
    end

    Logger.info("    %d succeeded", succeededCount)
    if skippedCount > 0 then
        Logger.info("    %d skipped", skippedCount)
    end
    Logger.info("    %d failed", failedCount)

    if Logger.level_is_less_than("debug") then
        Logger.info("")
        Logger.info("Enable debug logging for more information.")
    end

    for testerName, testerData in pairs(Tester._RESULTS["testers"]) do
        local failedTests = testerData["failed"]
        if #failedTests > 0 then
            Logger.info("")
            Logger.info("%d failed tests for %s", #failedTests, testerName)
        end
        for _, test in ipairs(failedTests) do
            Logger.info("")
            Logger.info("%s <%s> failed: %s", test["name"], test["test_location"], test["error"])
            if test["stack"] then
                Logger.debug(test["stack"])
            else
                Logger.debug("No stacktrace for test failure")
            end
        end

        local skippedTests = testerData["skipped"]
        if #skippedTests > 0 then
            Logger.info("")
            Logger.info("%d skipped tests for %s", #skippedTests, testerName)
        end
        for _, test in ipairs(skippedTests) do
            Logger.info("")
            Logger.info("%s <%s> skipped because before function failed. Error: %s", test["name"], test["test_location"], test["error"])
            if test["stack"] then
                Logger.debug(test["stack"])
            end
        end
    end
end

return Tester