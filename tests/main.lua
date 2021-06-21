-- TODO - this can all be a new mod?
-- TODO - should probably still have tests on the functions that wrap other ones, just to make sure they don't break (missing return or something dumb happens)
local Tester = require("modules/testing/tester")

local tester = require("tests/testing/tester")

local area = require("tests/area")
local entity = require("tests/entity")
local position = require("tests/position")
local logger = require("tests/logger")

return function()
    -- Test the tester first
    tester()

    -- Run other tests
    -- Modules are tested in dependency order (all depend on logger for example)
    Tester.add_tests(logger, "Logger")

    Tester.add_tests(position, "Position")
    Tester.add_tests(area, "Area")

    Tester.add_tests(entity, "Entity")

    Tester.run()
end
