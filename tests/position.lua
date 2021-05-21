local Tester = require("modules/tester")

local Position = require("modules/position")

local PositionTests = {}


-- Position standardizing tests
function PositionTests.test_standardize_position_arg_nil()
    local actual = Position.standardize(nil)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: nil")
end

function PositionTests.test_standardize_position_arg_not_table()
    local test = "{1,2}"
    local actual = Position.standardize(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. test)
end

function PositionTests.test_standardize_position_arg_already_standardized()
    local test = {x=1,y=2}
    local actual = Position.standardize(test)
    local expected = {x=1,y=2}

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function PositionTests.test_standardize_position_arg_only_x()
    local test = {x=1,2}
    local actual = Position.standardize(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function PositionTests.test_standardize_position_arg_only_y()
    local test = {1,y=2}
    local actual = Position.standardize(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function PositionTests.test_standardize_position_too_many_coords()
    local test = {1,2,3}
    local actual = Position.standardize(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function PositionTests.test_standardize_position_not_enough_coords()
    local test = {1}
    local actual = Position.standardize(test)
    local expected = nil

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end

function PositionTests.test_standardize_position_good()
    local test = {1,2}
    local actual = Position.standardize(test)
    local expected = {x=1,y=2}

    Tester.assert_equals(expected, actual, "Input failed: " .. serpent.line(test))
end


-- Position compare tests
function PositionTests.test_compare_is_equals()
    local test1 = {1,2}
    local test2 = {1,2}
    local actual = Position.compare(test1, test2)

    assert(actual,
            string.format("Input failed: <%s> - <%s>", serpent.line(test1), serpent.line(test2))
    )
end

function PositionTests.test_compare_x_equal()
    local test1 = {1,2}
    local test2 = {1,3}
    local actual = Position.compare(test1, test2)

    assert(not actual,
            string.format("Input failed: <%s> - <%s>", serpent.line(test1), serpent.line(test2))
    )
end

function PositionTests.test_compare_y_equal()
    local test1 = {1,2}
    local test2 = {3,2}
    local actual = Position.compare(test1, test2)

    assert(not actual,
            string.format("Input failed: <%s> - <%s>", serpent.line(test1), serpent.line(test2))
    )
end

function PositionTests.test_compare_swap_coords()
    local test1 = {1,2}
    local test2 = {2,1}
    local actual = Position.compare(test1, test2)

    assert(not actual,
            string.format("Input failed: <%s> - <%s>", serpent.line(test1), serpent.line(test2))
    )
end

function PositionTests.test_compare_swap_different_numbers()
    local test1 = {1,2}
    local test2 = {3,4}
    local actual = Position.compare(test1, test2)

    assert(not actual,
            string.format("Input failed: <%s> - <%s>", serpent.line(test1), serpent.line(test2))
    )
end


return PositionTests