local Logger = require("modules/logger").create("Area Test")
local Tester = require("modules/tester")

local Area = require("modules/area")

local AreaTests = {}

local areaOfEntityTests = {
    -- Both negative
    -- 1x1
    {bb = {{-10, -10}, {-9, -9}}, size = 1},
    {bb = {{-9.9, -10}, {-9.1, -9}}, size = 1},
    {bb = {{-10, -9.9}, {-9, -9.1}}, size = 1},
    {bb = {{-9.9, -9.1}, {-9.5, -9.1}}, size = 1},
    {bb = {{-9.6, -9.6}, {-9.4, -9.4}}, size = 1},

    -- 3x3
    {bb = {{-10, -10}, {-7, -7}}, size = 9},
    {bb = {{-9.9, -10}, {-7.9, -7}}, size = 9},
    {bb = {{-10, -9.9}, {-7, -7.9}}, size = 9},
    {bb = {{-9.9, -9.1}, {-7.5, -7.1}}, size = 9},
    {bb = {{-9.6, -9.6}, {-7.4, -7.4}}, size = 9},

    -- 2x1
    {bb = {{-10, -10}, {-8, -9}}, size = 2},
    {bb = {{-9.9, -10}, {-8.1, -9}}, size = 2},
    {bb = {{-10, -9.9}, {-8, -9.1}}, size = 2},
    {bb = {{-9.9, -9.1}, {-8.5, -9.1}}, size = 2},
    {bb = {{-9.6, -9.6}, {-8.4, -9.4}}, size = 2},

    -- 1x2
    {bb = {{-10, -10}, {-9, -8}}, size = 2},
    {bb = {{-9.9, -10}, {-9.1, -8}}, size = 2},
    {bb = {{-10, -9.9}, {-9, -8.1}}, size = 2},
    {bb = {{-9.9, -9.1}, {-9.5, -8.1}}, size = 2},
    {bb = {{-9.6, -9.6}, {-9.4, -8.4}}, size = 2},

    -- Both positive
    -- 1x1
    {bb = {{9, 9}, {10, 10}}, size = 1},
    {bb = {{9.1, 9}, {9.9, 10}}, size = 1},
    {bb = {{9, 9.1}, {10, 9.9}}, size = 1},
    {bb = {{9.5, 9.1}, {9.9, 9.1}}, size = 1},
    {bb = {{9.4, 9.4}, {9.6, 9.6}}, size = 1},

    -- 3x3
    {bb = {{7, 7}, {10, 10}}, size = 9},
    {bb = {{7.9, 7}, {9.9, 10}}, size = 9},
    {bb = {{7, 7.9}, {10, 9.9}}, size = 9},
    {bb = {{7.5, 7.1}, {9.9, 9.1}}, size = 9},
    {bb = {{7.4, 7.4}, {9.6, 9.6}}, size = 9},

    -- 2x1
    {bb = {{8, 9}, {10, 10}}, size = 2},
    {bb = {{8.1, 9}, {9.9, 10}}, size = 2},
    {bb = {{8, 9.1}, {10, 9.9}}, size = 2},
    {bb = {{8.5, 9.1}, {9.9, 9.1}}, size = 2},
    {bb = {{8.4, 9.4}, {9.6, 9.6}}, size = 2},

    -- 1x2
    {bb = {{9, 8}, {10, 10}}, size = 2},
    {bb = {{9.1, 8}, {9.9, 10}}, size = 2},
    {bb = {{9, 8.1}, {10, 9.9}}, size = 2},
    {bb = {{9.5, 8.1}, {9.9, 9.1}}, size = 2},
    {bb = {{9.4, 8.4}, {9.6, 9.6}}, size = 2},

    -- Axis crossovers
    -- Cross center
    -- 3x3
    {bb = {{-1, -1}, {2, 2}}, size = 9},
    {bb = {{-0.9, -1}, {1.9, 2}}, size = 9},
    {bb = {{-1, -0.9}, {2, 1.9}}, size = 9},
    {bb = {{-0.9, -0.1}, {1.5, 1.1}}, size = 9},
    {bb = {{-0.6, -0.6}, {1.4, 1.4}}, size = 9},

    -- Cross X axis
    -- 2x1
    {bb = {{-1, -1}, {1, 0}}, size = 2},
    {bb = {{-0.9, -1}, {0.9, 0}}, size = 2},
    {bb = {{-1, -0.9}, {1, -0.1}}, size = 2},
    {bb = {{-0.9, -0.2}, {0.5, -0.1}}, size = 2},
    {bb = {{-0.6, -0.6}, {0.4, -0.2}}, size = 2},

    -- Cross Y axis
    -- 1x2
    {bb = {{-1, -1}, {0, 1}}, size = 2},
    {bb = {{-0.9, -1}, {0, 0.9}}, size = 2},
    {bb = {{-1, -0.9}, {-0.1, 1}}, size = 2},
    {bb = {{-0.9, -0.2}, {-0.1, 0.5}}, size = 2},
    {bb = {{-0.6, -0.6}, {-0.2, 0.4}}, size = 2},
}

for _, data in ipairs(areaOfEntityTests) do
    local bb = data["bb"]
    local size = data["size"]
    local name = "test_lf_x_" .. bb[1][1] .. "_y_" .. bb[1][2] .. "__rb_x_" .. bb[2][1] .. "_y_" .. bb[2][2] .. "__expected_" .. size

    AreaTests[name] = function()
        local actual = Area.area_of_entity({
            valid = true,
            bounding_box = bb
        })
        Tester.assert_equals(size, actual)
    end
end

return AreaTests
