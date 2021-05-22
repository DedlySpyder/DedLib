local LoggerLib = require("logger")
local Logger = LoggerLib.create{modName = "DedLib", prefix = "Tester"}

local Tester = {}

--[[
TODO - notes on tester
if error has {message = message, stacktrace = debug.traceback()}
then the message will always be printed on an error, but the stacktrace will be saved for debug mode
]]--

function Tester.reset()
    -- {name = name, tests = {[name] = func}}
    Tester._TESTERS = {}
    Tester._FAILED_TESTS = {}
    Tester._COUNTS = {success = 0, failed = 0}
end
Tester.reset()

function Tester.add_test(func, name)
    if type(func) == "function" then
        if not name then name = "Single Test #" .. #Tester._TESTERS end
        Logger.debug("Adding single test %s", name)
        table.insert(Tester._TESTERS, {name = name, tests = {[name] = func}})
        return true
    else
        Logger.error("Failed to add new test function <" .. tostring(name) .. ">, is not a function.")
        if Logger.level_is_less_than("debug") then
            Logger.info("Enable debug logging for stacktrace.")
        else
            Logger.debug(debug.traceback())
        end
        return false
    end

end

function Tester.add_tests(tests, testerName)
    if type(tests) == "table" then
        local tester = {}
        tester["name"] = testerName or "Unnamed Tester #" .. #Tester._TESTERS

        local testerName = tester["name"]
        Logger.debug("Creating tester for %s", testerName)
        tester["tests"] = {}
        for name, func in pairs(tests) do
            if type(name) == "number" then name = "Test #" .. name end
            if string.find(string.lower(name), "test") then
                Logger.debug("Adding test " .. name)
                tester["tests"][name] = func
            else
                Logger.debug("Ignoring function " .. name .. ', does not contain the string "test" in name')
            end
        end
        Logger.debug("Done adding tests to %s", testerName)
        if table_size(tester["tests"]) then
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

function Tester.assert_equals(expected, actual, message)
    if serpent.line(expected) ~= serpent.line(actual) then
        if message then
            message = message .. "\n"
        else
            message = ""
        end
        message = message .. "Assertion failed. Expected <" .. serpent.line(expected) .. "> - Actual <" .. serpent.line(actual) .. ">"
        error({message = message, stacktrace = debug.traceback()})
    end
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

        local i = 0
        while Tester._FAILED_TESTS[testerName] do
            Logger.warn("Tester named %s already exists, incrementing to make unique", testerName)
            testerName = tester["name"] .. "-" .. i
            i = i + 1
        end
        Tester._FAILED_TESTS[testerName] = {}

        for name, func in pairs(tester["tests"]) do
            Logger.debug("Running test %s", name)
            local status, error = pcall(func)
            if status then
                Logger.info("Test %s succeeded", name)
                Tester._COUNTS["success"] = Tester._COUNTS["success"] + 1
            else
                if error and error["message"] and error["stacktrace"] then
                    local message = tostring(error["message"])
                    Logger.error("Test %s failed: %s", name, message)
                    table.insert(Tester._FAILED_TESTS[testerName], {name = name, error = message, stack = error["stacktrace"]})
                else
                    error = tostring(error)
                    Logger.error("Test %s failed: %s", name, error)
                    table.insert(Tester._FAILED_TESTS[testerName], {name = name, error = error, stack = debug.traceback()})
                end
                Tester._COUNTS["failed"] = Tester._COUNTS["failed"] + 1
            end
        end
    end

    Tester._report_failed()

    -- Reset the tester, but dump the counts in case the end user wants them first
    local counts = Tester._COUNTS
    Logger.debug("Resetting tester values")
    Tester.reset()
    return counts
end

function Tester._report_failed()
    Logger.info("")
    Logger.info("Finished running tests:")
    Logger.info("    %d succeeded", Tester._COUNTS["success"])
    Logger.info("    %d failed", Tester._COUNTS["failed"])

    if Logger.level_is_less_than("debug") then
        Logger.info("")
        Logger.info("Enable debug logging for more information.")
    end

    for testerName, failedTests in pairs(Tester._FAILED_TESTS) do
        if #failedTests > 0 then
            Logger.info("")
            Logger.info("%d failed tests for %s", #failedTests, testerName)
        end
        for _, test in ipairs(failedTests) do
            Logger.info("")
            Logger.info("%s failed: %s", test["name"], test["error"])
            Logger.debug(test["stack"])
        end
    end
end

return Tester