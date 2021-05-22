local Tester = require("modules/tester")

local Area = require("modules/area")
local Entity = require("modules/entity")

local EntityTests = {}


-- Entity.area_of_bounding_box tests
local areaOfBoundingBoxTests = {
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

for _, data in ipairs(areaOfBoundingBoxTests) do
    local bb = data["bb"]
    local size = data["size"]
    local name = "test_area_of_entity__lf_x_" .. bb[1][1] .. "_y_" .. bb[1][2] .. "__rb_x_" .. bb[2][1] .. "_y_" .. bb[2][2] .. "__expected_" .. size

    EntityTests[name] = Tester.create_basic_test(Entity.area_of_bounding_box, size, bb)
end


-- Entity.area_of_bounding_box_lt_rb tests
function EntityTests.test_area_of_bounding_box_lt_rb()
    local test1 = {1,1}
    local test2 = {4,4}
    local actual = Entity.area_of_bounding_box_lt_rb(test1, test2)
    local expected = 9

    Tester.assert_equals(expected, actual,
            string.format("Input failed: <%s> - <%s>", serpent.line(test1), serpent.line(test2))
    )
end

function EntityTests.test_area_of_bounding_box_lt_rb_invalid()
    local test1 = {1,2}
    local test2 = nil
    local actual = Entity.area_of_bounding_box_lt_rb(test1, test2)

    Tester.assert_equals(nil, actual,
            string.format("Input failed: <%s> - <%s>", serpent.line(test1), serpent.line(test2))
    )
end


-- Entity._area_of_by_chunks_and_vertices tests
local areaOfByChunksAndVerticesTests = {
    {
        name = "0_chunks",
        chunks = {},
        bb = {},
        expected = {}
    },
    {
        name = "1_chunk",
        chunks = {{x=0, y=0}},
        bb = {{7, 7},{10, 10}},
        expected = {{chunk = {x=0, y=0}, area = 9}}
    },
    {
        name = "2_chunks_vertical",
        chunks = {{x=-1, y=-1},{x=0, y=-1}},
        bb = {{-3,-3}, {1,-1}},
        expected = {{chunk = {x=-1, y=-1}, area = 6}, {chunk = {x=0, y=-1}, area = 2}}
    },
    {
        name = "2_chunks_horizontal",
        chunks = {{x=0, y=-1},{x=0, y=0}},
        bb = {{1,-1}, {3,3}},
        expected = {{chunk = {x=0, y=-1}, area = 2}, {chunk = {x=0, y=0}, area = 6}}
    },
    {
        name = "4_chunks",
        chunks = {{x=-1, y=-1},{x=0, y=0},{x=-1, y=0},{x=0, y=-1}},
        bb = {{-2,-2}, {1,1}},
        expected = {
            {chunk = {x=-1, y=-1}, area = 4},
            {chunk = {x=0, y=0}, area = 1},
            {chunk = {x=-1, y=0}, area = 2},
            {chunk = {x=0, y=-1}, area = 2}
        }
    }
}

for _, data in ipairs(areaOfByChunksAndVerticesTests) do
    local name = "test__area_of_by_chunks_and_vertices__" .. data["name"]
    local chunks = data["chunks"]
    local expected = data["expected"]
    local vertices = Area.get_bounding_box_vertices(data["bb"]) --{{-1,-3}, {1,-1}}

    local entity = Tester.get_mock_valid_entity({bounding_box = vertices, name = name})

    EntityTests[name] = Tester.create_basic_test(Entity._area_of_by_chunks_and_vertices, expected, entity, chunks, vertices)
end


-- Entity.chunks_of
local chunksOfEntityTests = {
    -- Single chunk
    {bb = {{1,1}, {2,2}}, chunks = {{x=0, y=0}}},

    -- 2 Chunks
    {bb = {{-1,-3}, {1,-1}}, chunks = {{x=-1, y=-1},{x=0, y=-1}}}, -- Vertical Split
    {bb = {{1,-1}, {3,1}}, chunks = {{x=0, y=-1},{x=0, y=0}}}, -- Horizontal Split

    -- 4 Chunks
    {bb = {{-1,-1}, {1,1}}, chunks = {{x=-1, y=-1},{x=0, y=0},{x=-1, y=0},{x=0, y=-1}}},
}

for _, data in ipairs(chunksOfEntityTests) do
    local bb = data["bb"]
    local name = "test_chunks_of__lf_x_" .. bb[1][1] .. "_y_" .. bb[1][2] .. "__rb_x_" .. bb[2][1] .. "_y_" .. bb[2][2]
    local entity = Tester.get_mock_valid_entity({bounding_box = Area.standardize_bounding_box(bb), name = name})
    local chunks = data["chunks"]

    EntityTests[name] = Tester.create_basic_test(Entity.chunks_of, chunks, entity)
end


return EntityTests