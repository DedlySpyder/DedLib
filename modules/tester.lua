local LoggerLib = require("logger")
local Logger = LoggerLib.create{modName = "DedLib", prefix = "Tester"}

local Tester = {}

-- {name = name, tests = {[name] = func}}
Tester._TESTERS = {}
Tester._FAILED_TESTS = {}
Tester._COUNTS = {success = 0, failed = 0}

function Tester.add_test(func, name)
    if type(func) == "function" then
        if not name then name = "Single Test #" .. #Tester._TESTERS end
        Logger.debug("Adding single test " .. name)
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
        Logger.debug("Creating tester for " .. tester["name"])
        tester["tests"] = {}
        for name, func in pairs(tests) do
            if type(name) == "number" then name = "Test #" .. name end
            if string.find(string.lower(name), "test") then
                Logger.debug("Adding test " .. name)
                tester["tests"][name] = func
            end
        end
        Logger.debug("Done adding tests to " .. tester["name"])
        table.insert(Tester._TESTERS, tester)
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

function Tester.assert_equals(x, y, message)
    if serpent.line(x) ~= serpent.line(y) then
        if message then
            message = message .. "\n"
        else
            message = ""
        end
        message = message .. "Assertion failed. <" .. serpent.line(x) .. "> does not equal <" .. serpent.line(y) .. ">"
        error(message)
    end
end

function Tester.run()
    Logger.trace("Running all tests")
    for _, tester in ipairs(Tester._TESTERS) do
        local testerName = tester["name"]
        Logger.debug("Running tester " .. testerName)

        local i = 0
        while Tester._FAILED_TESTS[testerName] do
            Logger.warn("Tester named " .. testerName .. " already exists, incrementing to make unique")
            testerName = tester["name"] .. "-" .. i
            i = i + 1
        end
        Tester._FAILED_TESTS[testerName] = {}

        for name, func in pairs(tester["tests"]) do
            Logger.debug("Running test " .. name)
            local status, error = pcall(func)
            if status then
                Logger.info("Test " .. name .." succeeded")
                Tester._COUNTS["success"] = Tester._COUNTS["success"] + 1
            else
                error = tostring(error)
                Logger.error("Test " .. name .." failed: " .. error)
                table.insert(Tester._FAILED_TESTS[testerName], {name = name, error = error, stack = debug.traceback()})
                Tester._COUNTS["failed"] = Tester._COUNTS["failed"] + 1
            end
        end
    end

    Tester._report_failed()
end

function Tester._report_failed()
    Logger.info("")
    Logger.info("Finished running tests:")
    Logger.info("    " .. Tester._COUNTS["success"] .. " succeeded")
    Logger.info("    " .. Tester._COUNTS["failed"] .. " failed")

    if Logger.level_is_less_than("debug") then
        Logger.info("")
        Logger.info("Enable debug logging for more information.")
    end

    for testerName, failedTests in pairs(Tester._FAILED_TESTS) do
        if #failedTests > 0 then
            Logger.info("")
            Logger.info(#failedTests .. " failed tests for " .. testerName)
        end
        for _, test in ipairs(failedTests) do
            Logger.info("")
            Logger.info(test["name"] .. " failed: " .. test["error"])
            Logger.debug(test["stack"])
        end
    end
end

return Tester