local Logger = require("modules/logger").create("Area Test")
local Tester = require("modules/tester")

local Area = require("modules/area")

local AreaTests = {}


-- Area.area_of_entity(entity) tests
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

    AreaTests[name] = Tester.create_basic_test({
        valid = true,
        bounding_box = bb
    }, size, Area.area_of_entity)
end


-- Bounding_box standardizing tests
function AreaTests.test_standardize_bounding_box_arg_nil()
    local actual = Area.standardize_bounding_box(nil)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: nil")
end

function AreaTests.test_standardize_bounding_box_arg_not_table()
    local test = "{{1,2}, {3,4}}"
    local actual = Area.standardize_bounding_box(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. test)
end

function AreaTests.test_standardize_bounding_box_outer_standardized_inner_not_standardized()
    local test = {left_top = {1,2}, right_bottom = {3,4}}
    local actual = Area.standardize_bounding_box(test)
    local expected = {left_top = {x=1, y=2}, right_bottom = {x=3, y=4}}

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_outer_standardized_inner_not_valid_pos_1()
    local test = {left_top = "{1,2}", right_bottom = {3,4}}
    local actual = Area.standardize_bounding_box(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_outer_standardized_inner_not_valid_pos_2()
    local test = {left_top = {1,2}, right_bottom = "{3,4}"}
    local actual = Area.standardize_bounding_box(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_already_standardized()
    local test = {left_top = {x=1, y=2}, right_bottom = {x=3, y=4}}
    local actual = Area.standardize_bounding_box(test)
    local expected = {left_top = {x=1, y=2}, right_bottom = {x=3, y=4}}

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_too_many_points()
    local test = {{1,2}, {3,4}, {5,6}}
    local actual = Area.standardize_bounding_box(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_not_enough_points()
    local test = {{1,2}}
    local actual = Area.standardize_bounding_box(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_pos_1_not_table()
    local test = {"{1,2}", {3,4}}
    local actual = Area.standardize_bounding_box(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_pos_2_not_table()
    local test = {{1,2}, "{3,4}"}
    local actual = Area.standardize_bounding_box(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_good()
    local test = {{1,2}, {3,4}}
    local actual = Area.standardize_bounding_box(test)
    local expected = {left_top = {x=1, y=2}, right_bottom = {x=3, y=4}}

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end


-- Position standardizing tests
function AreaTests.test_standardize_position_arg_nil()
    local actual = Area.standardize_position(nil)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: nil")
end

function AreaTests.test_standardize_position_arg_not_table()
    local test = "{1,2}"
    local actual = Area.standardize_position(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. test)
end

function AreaTests.test_standardize_position_arg_already_standardized()
    local test = {x=1,y=2}
    local actual = Area.standardize_position(test)
    local expected = {x=1,y=2}

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_position_arg_only_x()
    local test = {x=1,2}
    local actual = Area.standardize_position(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_position_arg_only_y()
    local test = {1,y=2}
    local actual = Area.standardize_position(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_position_too_many_coords()
    local test = {1,2,3}
    local actual = Area.standardize_position(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_position_not_enough_coords()
    local test = {1}
    local actual = Area.standardize_position(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_position_good()
    local test = {1,2}
    local actual = Area.standardize_position(test)
    local expected = {x=1,y=2}

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end


return AreaTests
