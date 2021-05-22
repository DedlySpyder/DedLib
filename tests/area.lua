local Tester = require("modules/tester")

local Area = require("modules/area")

local AreaTests = {}


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

function AreaTests.test_standardize_bounding_box_pos_1_not_position()
    local test = {{1}, {3,4}}
    local actual = Area.standardize_bounding_box(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function AreaTests.test_standardize_bounding_box_pos_2_not_position()
    local test = {{1,2}, {3}}
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


-- Get vertices of a bounding box tests
function AreaTests.test_get_bounding_box_vertices()
    local test = {{1,2}, {3,4}}
    local result = Area.get_bounding_box_vertices(test)
    local expectedLt = {x = 1, y = 2}
    local expectedRb = {x = 3, y = 4}
    local expectedLb = {x = 1, y = 4}
    local expectedRt = {x = 3, y = 2}

    Tester.assert_equals(expectedLt, result.left_top, "Input failed for left_top: " .. serpent.line(test))
    Tester.assert_equals(expectedRb, result.right_bottom, "Input failed for right_bottom: " .. serpent.line(test))
    Tester.assert_equals(expectedLb, result.left_bottom, "Input failed for left_bottom: " .. serpent.line(test))
    Tester.assert_equals(expectedRt, result.right_top, "Input failed for right_top: " .. serpent.line(test))
end

function AreaTests.test_get_bounding_box_vertices_invalid_input()
    local test = {{1,2}}
    local result = Area.get_bounding_box_vertices(test)
    Tester.assert_equals(nil, result, "Input failed for invalid: " .. serpent.line(test))
end


-- Get chunk position from position tests
local chunkPositionFromPositionTests = {
    {test = {0,0}, expected = {x=0, y=0}},
    {test = {0.1,0.1}, expected = {x=0, y=0}},
    {test = {-1,-1}, expected = {x=-1, y=-1}},
    {test = {-0.1,-0.1}, expected = {x=-1, y=-1}},
    {test = {1,-1}, expected = {x=0, y=-1}},
    {test = {0.1,-0.1}, expected = {x=0, y=-1}},
    {test = {-1,1}, expected = {x=-1, y=0}},
    {test = {-0.1,0.1}, expected = {x=-1, y=0}},
    {test = {32,63}, expected = {x=1, y=1}},
    {test = {75,50}, expected = {x=2, y=1}},
}

for _, data in ipairs(chunkPositionFromPositionTests) do
    local test = data["test"]
    local expected = data["expected"]
    local name = "test_get_chunk_position__x_" .. test[1] .. "_y_" .. test[2] .. "__expected_" .. serpent.line(expected)

    AreaTests[name] = Tester.create_basic_test(Area.get_chunk_position_from_position, expected, test)
end


-- Get chunk area from chunk position tests
local chunkAreaFromChunkPositionTests = {
    {test = {0,0}, expected = {left_top={x=0, y=0}, right_bottom={x=32, y=32}}},
    {test = {-1,-1}, expected = {left_top={x=-32, y=-32}, right_bottom={x=0, y=0}}},
    {test = {-1,0}, expected = {left_top={x=-32, y=0}, right_bottom={x=0, y=32}}},
    {test = {0,-1}, expected = {left_top={x=0, y=-32}, right_bottom={x=32, y=0}}},
}

for _, data in ipairs(chunkAreaFromChunkPositionTests) do
    local test = data["test"]
    local expected = data["expected"]
    local name = "test_get_chunk_area_from_chunk_position__x_" .. test[1] .. "_y_" .. test[2] .. "__expected_" .. serpent.line(expected)

    AreaTests[name] = Tester.create_basic_test(Area.get_chunk_area_from_chunk_position, expected, test)
end


return AreaTests
