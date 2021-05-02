-- TODO - this can all be a new mod?
local Tester = require("modules/tester")

local logger = require("tests/logger")
local area = require("tests/area")

return function()
    Tester.add_tests(area, "Area")
    Tester.add_tests(logger, "Logger")
    Tester.run()
end

--TODO - this test will mess up other tests, so when these are all moved out of the main lib needs to be mutex with other tests
--local tester = require("tester")
--return function()
--    tester()
--end