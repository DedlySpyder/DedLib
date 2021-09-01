local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}
local Stringify = require("__DedLib__/modules/stringify")
local Util = require("__DedLib__/modules/util")

local Test = require("__DedLib__/modules/testing/test")

local ALL_TEST_GROUPS, ALL_TEST_GROUP_COUNTS

local Test_Group = {}
Test_Group.__index = Test_Group
Test_Group.__which = "Test_Group"

Test_Group.name = "uninitialized_test_group"

Test_Group.tests = {
    incomplete = {}, -- Both pending and running
    skipped = {},
    failed = {},
    succeeded = {}
}

Test_Group.before = false
Test_Group.beforeArgs = {}
Test_Group.after = false
Test_Group.afterArgs = {}

Test_Group.running = false
Test_Group.done = false
Test_Group.state = "pending"
Test_Group.skipped_reason = "Unknown error"

function Test_Group.create(args)
    local argsType = type(args)
    if argsType == "table" then
        if args.tests == nil and table_size(args) > 0 then
            Logger:debug('Args for test group are missing "tests", but is a table, assuming this is just a single test instead...')
            args = {tests = {args}}
        end
    else
        Logger:fatal("Failed to create test group with: %s", args)
        error("Failed to create test group of type " .. argsType .. " (expected table)")
    end
    Logger:trace("Creating test group with args %s", args)

    -- This deepcopy will implicitly add all test group properties
    local tg = table.deepcopy(args)
    setmetatable(tg, Test_Group)

    local groupName = Test_Group.generate_name(args.name)
    Logger:info("Creating test group named %s", groupName)
    tg.name = groupName

    local tests = Test.create_multiple(tg.tests)
    if #tests == 0 then
        Logger:warn('No tests for %s found. Did the test function names contain the word "test"?', groupName)
    end

    tg.tests = table.deepcopy(Test_Group.tests)
    tg.tests.incomplete = tests

    tg:validate()
    table.insert(ALL_TEST_GROUPS.incomplete, tg)
    return tg
end

function Test_Group.get_all_groups()
    return ALL_TEST_GROUPS
end

function Test_Group.get_all_group_counts()
    return ALL_TEST_GROUP_COUNTS
end

function Test_Group.reset_all_groups()
    ALL_TEST_GROUPS = {
        incomplete = {},
        skipped = {},
        completed = {}
    }

    ALL_TEST_GROUP_COUNTS = {
        skipped = 0,
        failed = 0,
        succeeded = 0
    }
end
Test_Group.reset_all_groups()


-- Init functions
function Test_Group.generate_name(name)
    if name == nil then
        return "Unnamed Test Group #" .. #ALL_TEST_GROUPS.incomplete
    elseif type(name) == "string" then
        return name
    else
        return Stringify.to_string(name)
    end
end

function Test_Group:validate_property(prop, expectedType) -- TODO - abstract - shared code with Test.lua, but I like the logger right now
    local p = rawget(self, prop)
    if p ~= nil then
        local pType = type(p)
        if pType ~= expectedType then
            Logger:fatal("Validation for test group failed: %s", self)
            error("Test group " .. self.name .. " failed validation for " .. prop .. ", see logs for more details")
        elseif expectedType == "table" and #p == 0 and table_size(p) > 0 then
            self[prop] = {p}
        end
    end
end

function Test_Group:validate()
    self:validate_property("before", "function")
    self:validate_property("beforeArgs", "table")
    self:validate_property("after", "function")
    self:validate_property("afterArgs", "table")
end


-- Runtime functions
function Test_Group:run_before()
    if self.before then
        Logger:debug("Running before function for test group %s", self.name)
        local s, e = pcall(self.before, table.unpack(self.beforeArgs))
        if not s then
            Logger:error("Test group before function failed for %s, with error <%s>, skipping...", self.name, e)
            self:set_skipped(e)
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

function Test_Group:run_after()
    if self.after then
        Logger:debug("Running after function for test group %s", self.name)
        local s, e = pcall(self.after, table.unpack(self.afterArgs))
        if not s then
            Logger:error("Test group after function failed for %s, with error <%s>", self.name, e)
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

function Test_Group.run_all()
    Logger:trace("Running all tests")
    local allGroups = ALL_TEST_GROUPS
    for _, group in ipairs(allGroups.incomplete) do
        group:run()
    end
    allGroups.incomplete = {}
end

-- NOTE: Doesn't remove from incomplete at this time
function Test_Group:adjust_globals()
    local allGroups = ALL_TEST_GROUPS
    local allCounts = ALL_TEST_GROUP_COUNTS

    local state = self.state
    if state == "completed" then
        table.insert(allGroups.completed, self)
    elseif state == "skipped" then
        table.insert(allGroups.skipped, self)
    end

    if self.done then
        allCounts.skipped = allCounts.skipped + #self.tests.skipped
        allCounts.failed = allCounts.failed + #self.tests.failed
        allCounts.succeeded = allCounts.succeeded + #self.tests.succeeded
    end
end

function Test_Group:run()
    if self.done then return end

    if self.state == "running" then
        Logger:debug("Running test group %s", self.name)
        local tests = self.tests
        for _, test in ipairs(tests.incomplete) do
            test:run()

            local state = test.state
            if state == "succeeded" then
                table.insert(tests.succeeded, test)
            elseif state == "skipped" then
                table.insert(tests.skipped, test)
            elseif state == "failed" then
                table.insert(tests.failed, test)
            end
        end
        tests.incomplete = {}
        self:run_after()
        self:set_completed()
        self:adjust_globals()

    elseif self.state == "pending" then
        -- After this is done, the state of the test will either be "skipped" or "running"
        self:run_before()

        if self.state == "skipped" then
            self:skip_tests()
        else
            self:run()
        end
    end
end

function Test_Group:skip_tests()
    local tests = self.tests
    local reason = self.skipped_reason
    for _, test in ipairs(tests.incomplete) do
        Logger:info("Test %s skipped", test.name)
        test:set_skipped(reason, "Test group skipped, before function failed: ")
        table.insert(tests.skipped, test)
    end
    tests.incomplete = {}
end

function Test_Group:set_running()
    self.state = "running"
    self.running = true
end

function Test_Group:set_skipped(reason)
    self.state = "skipped"
    self.running = false
    self.done = true
    self.skipped_reason = reason
end

function Test_Group:set_completed()
    self.state = "completed"
    self.running = false
    self.done = true
end


-- Print functions
function Test_Group:print_to_logger()
    if self.state == "skipped" then
        Logger:info("%d skipped tests for test group %s, due to %s", #self.tests.skipped, self.name, self.skipped_reason)

    elseif self.state == "completed" then
        Logger:info("%d successful tests for test group %s", #self.tests.succeeded, self.name)

        local skippedTests = self.tests.skipped
        if #skippedTests > 0 then
            Logger:info("%d skipped tests for test group %s", #skippedTests, self.name)
            for _, test in ipairs(self.tests.skipped) do
                Logger:info("")
                test:print_to_logger()
            end
        end

        local failedTests = self.tests.failed
        if #failedTests > 0 then
            Logger:info("%d failed tests for test group %s", #failedTests, self.name)
            for _, test in ipairs(self.tests.skipped) do
                Logger:info("")
                test:print_to_logger()
            end
        end

    else
        Logger:info("Test group %s is still in %s state", self.name, self.state)
    end
end



return Test_Group
