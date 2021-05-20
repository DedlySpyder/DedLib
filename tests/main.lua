-- TODO - this can all be a new mod?
local Tester = require("modules/tester")

local tester = require("tests/tester")

local area = require("tests/area")
local entity = require("tests/entity")
local position = require("tests/position")
local logger = require("tests/logger")

return function()
    -- Test the tester first
    tester()

    -- Run other tests
    Tester.add_tests(area, "Area")
    Tester.add_tests(entity, "Entity")
    Tester.add_tests(position, "Position")
    Tester.add_tests(logger, "Logger")
    Tester.run()
end
