local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}

local Debug = require("__DedLib__/modules/debug")
local Stringify = require("__DedLib__/modules/stringify")
local Table = require("__DedLib__/modules/table")
local Util = require("__DedLib__/modules/util")


local Test = {}
Test.__index = Test
Test.__which = "Test"

Test.name = "uninitialized_test"

Test.args = {}
Test.generateArgsFunc = false
Test.generateArgsFuncArgs = {}
Test.func = function() error("TEST FUNC NOT IMPLEMENTED") end
Test.test_location = ""
Test.before = false
Test.beforeArgs = {}
Test.after = false
Test.afterArgs = {}

Test.running = false
Test.done = false
Test.state = "pending"
Test.error = "Unknown error"
Test.stacktrace = nil

--[[
if error from the test has {message = message, stacktrace = debug.traceback()}
then the message will always be printed on an error, but the stacktrace will be saved for debug mode
]]--
function Test.create(args, name)
    local argsType = type(args)
    if argsType == "function" then
        args = {func = args}
        argsType = "table"
    end

    if argsType ~= "table" then
        Logger:fatal("Failed to create test with: %s", args)
        error("Failed to create test of type " .. argsType .. " (expected table or function)")
    elseif args.__which == Test.__which then
        -- No-op
        return args
    end

    Logger:trace("Creating test with args %s", args)

    -- This deepcopy will implicitly add all test properties
    local t = table.deepcopy(args)
    setmetatable(t, Test)

    local testName = Test.generate_name(args.name or name)
    Logger:debug("Creating test named %s", testName)
    t.name = testName

    t.test_location = Debug.get_defined_line_string(t.func)

    t:validate()
    return t
end

function Test.create_multiple(testsArgs)
    local testsArgsType = type(testsArgs)
    if testsArgsType ~= "table" then
        if testsArgsType == "function" then
            testsArgs = {testsArgs}
        else
            Logger:fatal("Failed to create tests with: %s", testsArgs)
            error("Failed to create tests of type " .. testsArgsType .. " (expected table or function)")
        end
    end
    Logger:trace("Creating multiple tests: %s", testsArgs)

    local tests = {}
    for name, args in pairs(testsArgs) do
        if Test.valid_name(name) then
            table.insert(tests, Test.create(args, name))
        else
            Logger:debug("Ignoring function " .. name .. ', does not contain the string "test" in name')
        end
    end
    return tests
end


-- Init functions
function Test.valid_name(name)
    local nameType = type(name)
    return nameType == "number" or (nameType == "string" and string.find(string.lower(name), "test"))
end

function Test.generate_name(name)
    local nameType = type(name)
    if nameType == "string" then
        return name
    elseif nameType == "number" then
        return "Unnamed Test #" .. name
    elseif name == nil then
        return "Unnamed Test #" .. math.random(2147483647) -- Should be random enough if for some reason are being created one at a time
    else
        return "Test: " .. Stringify.to_string(name)
    end
end

function Test:validate_property(prop, expectedType)
    local p = rawget(self, prop)
    if p ~= nil then
        local pType = type(p)
        if pType ~= expectedType then
            Logger:fatal("Validation for test failed: %s", self)
            error("Test " .. self.name .. " failed validation for " .. prop .. ", see logs for more details")
        elseif expectedType == "table" and #p == 0 and table_size(p) > 0 then
            self[prop] = {p}
        end
    end
end

function Test:validate()
    self:validate_property("args", "table")
    self:validate_property("generateArgsFunc", "function")
    self:validate_property("generateArgsFuncArgs", "table")
    self:validate_property("func", "function")
    self:validate_property("before", "function")
    self:validate_property("beforeArgs", "table")
    self:validate_property("after", "function")
    self:validate_property("afterArgs", "table")
end


-- Runtime functions
function Test:run_before()
    if self.before then
        Logger:debug("Running before function for test %s", self.name)
        local s, e = pcall(self.before, table.unpack(self.beforeArgs))
        if not s then
            Logger:error("Test before function failed for %s, with error <%s>, skipping...", self.name, e)
            self:set_skipped(e, "Test skipped, before function failed: ")
            return false, e
        end
        Logger:debug("Successfully completed %s before function%s%s",
                self.name,
                Util.ternary(e == nil, "", ", returned value: "),
                e or ""
        )
        self:set_running()
        return true, e
    end
    self:set_running()
end

function Test:run_after()
    if self.after then
        Logger:debug("Running after function for test %s", self.name)
        local s, e = pcall(self.after, table.unpack(self.afterArgs))
        if not s then
            Logger:error("Test after function failed for %s, with error <%s>", self.name, e)
            return false, e
        end
        Logger:debug("Successfully completed %s after function%s%s",
                self.name,
                Util.ternary(e == nil, "", ", returned value: "),
                e or ""
        )
        return true, e
    end
end

function Test:generate_args()
    if self.generateArgsFunc then
        -- The generate args function can return multiple values, but the first returned value is the pass/fail status
        Logger:debug("Generating arguments for test %s", self.name)
        local values = {pcall(self.generateArgsFunc, table.unpack(self.generateArgsFuncArgs))}
        if values[1] then
            self.args = Table.shift(values, 1)
            Logger:debug("Generated args: %s", self.args)
        else
            Logger:error("Failed to generate args for %s, skipping...", self.name)
            self:set_skipped(values[2], "Test skipped, failed to generate args: ")
            return
        end
    end
end

function Test:run()
    if self.done then return end

    if self.state == "running" then
        Logger:debug("Running test %s", self.name)
        local s, e = pcall(self.func, table.unpack(self.args))
        if s then
            Logger:info("Test %s succeeded", self.name)
            self:set_succeeded()
        else
            Logger:error("Test %s failed, raw error: %s", self.name, e)
            self:set_failed(e)
        end
        self:run_after()

    elseif self.state == "pending" then
        -- After these are done, the state of the test will either be "skipped" or "running"
        self:run_before()
        self:generate_args()

        self:run()
    end
end

function Test.parse_reason(reason)
    local message, stacktrace = reason, nil
    if type(reason) == "table" then
        if reason.message or reason.stacktrace then
            message = reason.message
            stacktrace = reason.stacktrace
        end
    end

    if message ~= nil then
        return Stringify.to_string(message), stacktrace
    else
        return nil, stacktrace
    end
end

function Test:set_reason(reason, reasonPrefix)
    local message, stacktrace = Test.parse_reason(reason)
    if reasonPrefix or message then
        -- Otherwise just bubble up the default unknown
        self.error = (reasonPrefix or "") .. (message or "")
    end
    self.stacktrace = stacktrace
end

function Test:set_running()
    self.state = "running"
    self.running = true
end

function Test:_set_done()
    self.running = false
    self.done = true
end

function Test:set_skipped(reason, reasonPrefix)
    self.state = "skipped"
    self:_set_done()
    self:set_reason(reason, reasonPrefix)
end

function Test:set_failed(reason, reasonPrefix)
    self.state = "failed"
    self:_set_done()
    self:set_reason(reason, reasonPrefix)
end

function Test:set_succeeded()
    self.state = "succeeded"
    self:_set_done()
end


-- Print functions
function Test:print_to_logger()
    local state = self.state
    if state == "succeeded" then
        Logger:info("%s <%s> succeeded", self.name, self.test_location)

    elseif state == "failed" or state == "skipped" then
        Logger:info("%s <%s> %s, due to: %s", self.name, self.test_location, self.state, self.error)
        if self.stacktrace then
            Logger:debug(self.stacktrace)
        end

    elseif state == "running" then
        Logger:info("%s <%s> is still running", self.name, self.test_location)
    end
end


return Test
