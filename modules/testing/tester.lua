local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib", prefix = "Tester"}
local Debug = require("__DedLib__/modules/debug")
local Table = require("__DedLib__/modules/table")
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

function Tester.add_test(data, name)
    if not name then name = "Single Test #" .. #Tester._TESTERS end
    if not string.find(string.lower(name), "test") then
        name = name .. " Test"
    end
    Logger.debug("Adding single test %s", name)
    return Tester.add_tests({[name] = data}, name .. " Tester")
end

function Tester.add_tests(tests, testerData)
    if type(tests) == "table" then
        if type(testerData) ~= "table" then testerData = {name = testerData} end -- Assume non-table is just a name
        local tester = table.deepcopy(testerData)
        if tester["name"] == nil then
            tester["name"] = "Unnamed Tester #" .. #Tester._TESTERS
        elseif type(tester["name"]) ~= "string" then
            tester["name"] = serpent.line(tester["name"])
        end

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

function Tester._add_error_to_test_results(testName, error, testResults, skipLog)
    local errorIsTable = type(error) == "table"
    if error and errorIsTable and error["message"] and error["stacktrace"] then
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
    if not skipLog then
        Logger.error("Test %s failed: %s", testName, testResults["error"])
    end
    return testResults
end

-- Example: {}, "before|after", "tester|test", "testName"
-- Returns error message, or nil if it ran successfully
function Tester._eval_meta_func(data, funcName, layerType, layerName)
    local func = data[funcName]
    if func and type(func) == "function" then
        Logger.debug("Running %s function for %s %s", funcName, layerType, layerName)

        local args = data[funcName .. "Args"] or {}
        if type(args) ~= "table" or #args == 0 then args = {args} end -- Args should be a list of args
        local s, e = pcall(func, table.unpack(args))
        if not s then
            Logger.error("%s %s function failed for %s, with error <%s>",
                    Util.String.capitalize(layerType),
                    funcName,
                    layerName,
                    e,
                    Util.ternary(string.find(funcName, "before") == nil, "", ", skipping...")
            )
            return Tester._add_error_to_test_results(layerName, e, {}, true)["error"]
        end
        Logger.debug("Successfully completed %s before function%s", layerType, Util.ternary(e ~= nil, ", returned value: " .. serpent.line(e), ""))
    end
    return nil
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

        -- Returns true if the test was skipped and processed
        local processSkippedTest = function(testResults, name)
            if testResults["result"] == "skipped" then
                Logger.info("Test %s skipped", name)
                table.insert(skippedTests, testResults)
                table.insert(Tester._RESULTS["skipped"], testResults)
                return true
            end
        end

        local beforeTesterError = Tester._eval_meta_func(tester, "before", "tester", testerName)

        for name, testData in pairs(tester["tests"]) do
            Logger.debug("Running test %s", name)
            local func = testData["func"]
            local funcLine = Debug.get_defined_line_string(func)
            local testResults = {
                name = name,
                test_location = funcLine
            }

            if beforeTesterError == nil then
                local e = Tester._eval_meta_func(testData, "before", "test", name)
                if e ~= nil then
                    testResults["result"] = "skipped"
                    Tester._add_error_to_test_results(name, e, testResults)
                end
            else
                testResults["result"] = "skipped"
                testResults["error"] = "Tester skipped, failed before step: " .. beforeTesterError
            end


            testerIndividualTestResults[name] = testResults
            if not processSkippedTest(testResults, name) then
                local args = testData["args"] or {}
                local genArgsFunc = testData["generateArgsFunc"]
                if genArgsFunc and type(genArgsFunc) == "function" then
                    local pcallVals = {pcall(genArgsFunc, table.unpack(testData["generateArgsFuncArgs"] or {}))}
                    if pcallVals[1] then
                        args = Table.shift(pcallVals)
                    else
                        testResults["result"] = "skipped"
                        Tester._add_error_to_test_results(name, pcallVals[2], testResults)
                        testResults["error"] = "Tester skipped, failed to generate args: " .. testResults["error"]
                    end
                end

                if not processSkippedTest(testResults, name) then
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

                    -- NOTE: After functions are only run after a test is actually run, skipped tests do not run this
                    Tester._eval_meta_func(testData, "after", "test", name) --TODO - maybe - should these warn post run when failing?
                end
            end
        end
        Tester._eval_meta_func(tester, "after", "tester", testerName) --TODO - maybe - should these warn post run when failing?
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
            Logger.info("%s <%s> skipped. Error: %s", test["name"], test["test_location"], test["error"])
            if test["stack"] then
                Logger.debug(test["stack"])
            end
        end
    end
end

return Tester