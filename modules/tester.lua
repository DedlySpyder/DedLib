local LoggerLib = require("logger")
local Logger = LoggerLib.create{modName = "DedLib", prefix = "Tester"}

local Debug = require("debug")
local Util = require("util")

local Tester = {}

--[[
TODO - notes on tester
if error has {message = message, stacktrace = debug.traceback()}
then the message will always be printed on an error, but the stacktrace will be saved for debug mode
]]--

function Tester.reset()
    -- {name = name, tests = {[name] = func}}
    Tester._TESTERS = {}
    Tester._RESULTS = {testers = {}, succeeded = {}, failed = {}}
end
Tester.reset()

function Tester.add_test(func, name)
    if not name then name = "Single Test #" .. #Tester._TESTERS end
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
--TODO - break asserts out to their own file when doing the below, & the message part can be extracted out
-- TODO - implement - other methods like this to add the stacktrace to normal assert & error()
-- exact instead of serpent for this for one
function Tester.assert_equals(expected, actual, message)
    if serpent.line(expected) ~= serpent.line(actual) then
        if message then
            message = message .. "\n"
        else
            message = ""
        end
        message = message .. "Assertion equals failed. Expected <" .. serpent.line(expected) .. "> - Actual <" .. serpent.line(actual) .. ">"
        error({message = message, stacktrace = debug.traceback()})
    end
end

function Tester.assert_starts_with(startsWith, value, message)
    if not Util.String.starts_with(tostring(value), tostring(startsWith)) then
        if message then
            message = message .. "\n"
        else
            message = ""
        end
        message = message .. "Assertion starts with failed. Starts with <" .. serpent.line(startsWith) .. "> - Actual string <" .. serpent.line(value) .. ">"
        error({message = message, stacktrace = debug.traceback()})
    end
end

function Tester.assert_ends_with(endsWith, value, message)
    if not Util.String.ends_with(tostring(value), tostring(endsWith)) then
        if message then
            message = message .. "\n"
        else
            message = ""
        end
        message = message .. "Assertion starts with failed. Ends with <" .. serpent.line(endsWith) .. "> - Actual string <" .. serpent.line(value) .. ">"
        error({message = message, stacktrace = debug.traceback()})
    end
end

function Tester.assert_contains_exact(expectedItem, list, message) --TODO make an non-exact version
    for _, listItem in pairs(list) do
        if listItem == expectedItem then
            return
        end
    end

    -- Wasn't found
    if message then
        message = message .. "\n"
    else
        message = ""
    end
    message = message .. "Assertion contains exact failed. Expected <" .. serpent.line(expectedItem) .. "> - List <" .. serpent.line(list) .. ">"
    error({message = message, stacktrace = debug.traceback()})
end

function Tester.get_mock_valid_entity(values)
    if not values then values = {} end
    if type(values) ~= "table" then
        local msg = "Values for mock entity is not a table: " .. tostring(values)
        Logger.fatal(msg)
        error(msg)
    end
    values.valid = true
    return values
end

function Tester.create_basic_test(testingFunc, expectedValue, ...)
    local testArgs = table.pack(...)
    return function()
        local actual = testingFunc(unpack(testArgs))
        Tester.assert_equals(expectedValue, actual, "Input failed for arg: " .. serpent.line(testArg))
    end
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
        local failedTests = {}
        local testerResults = {name = testerName, succeeded = succeededTests, failed = failedTests, tests = testerIndividualTestResults}
        Tester._RESULTS["testers"][testerName] = testerResults

        for name, testData in pairs(tester["tests"]) do -- TODO - fixme - add before/after? (and on tester too while I'm, at it)
            Logger.debug("Running test %s", name)
            local func = testData["func"]
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

            local funcLine = Debug.get_defined_string(func)
            local testResults = {
                name = name,
                result = status,
                test_location = funcLine
            }

            -- Index the results by name and by result
            testerIndividualTestResults[name] = testResults
            if status then
                Logger.info("Test %s succeeded", name)
                table.insert(succeededTests, testResults)
                table.insert(Tester._RESULTS["succeeded"], testResults)
            else
                if error and error["message"] and error["stacktrace"] then
                    local message = tostring(error["message"])

                    Logger.error("Test %s failed: %s", name, message)
                    testResults["error"] = message
                    testResults["stack"] = error["stacktrace"]
                else
                    if type(error) == "table" then
                        error = serpent.line(error)
                    else
                        error = tostring(error)
                    end

                    Logger.error("Test %s failed: %s", name, error)
                    testResults["error"] = error
                end
                table.insert(failedTests, testResults)
                table.insert(Tester._RESULTS["failed"], testResults)
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
    Logger.info("    %d succeeded", #Tester._RESULTS["succeeded"])
    Logger.info("    %d failed", #Tester._RESULTS["failed"])

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
    end
end

return Tester