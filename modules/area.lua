local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib", prefix = "Area"}
local Position = require("__DedLib__/modules/position")

local Area = {} -- TODO -- docs

function Area.area_of_entity(entity)
    Logger.trace("Finding area of an entity")
    if entity and entity.valid and entity.bounding_box then
        local bounding_box = Area.standardize_bounding_box(entity.bounding_box)
        local bb = Area.round_bounding_box_up(bounding_box)
        local area = (bb.right_bottom.x - bb.left_top.x) * (bb.right_bottom.y - bb.left_top.y)
        Logger.trace("Area of entity is %s with bounding box: %s", area, bb)
        return area
    else
        Logger.error("Entity is nil, invalid, or missing bounding_box")
    end
end

function Area.round_bounding_box_up(bounding_box) -- TODO - testing
    Logger.trace("Attempting to round bounding_box up to nearest tiles: %s", bounding_box)
    local bb = Area.standardize_bounding_box(bounding_box)
    if bb then
        local left_top = bb.left_top
        local right_bottom = bb.right_bottom
        local newBoundingBox = {
            left_top = {
                x = math.floor(left_top.x),
                y = math.floor(left_top.y)
            },
            right_bottom = {
                x = math.ceil(right_bottom.x),
                y = math.ceil(right_bottom.y)
            }
        }
        Logger.trace("Rounded up bounding_box: %s", newBoundingBox)
        return newBoundingBox
    end
end

function Area.modify_bounding_box(bounding_box, bounding_box_modify) -- TODO - testing
    local sBoundingBox = Area.standardize_bounding_box(bounding_box)
    local sBoundingBoxMod = Area.standardize_bounding_box(bounding_box_modify)
    if sBoundingBox and sBoundingBoxMod then
        Logger.trace("Attempting to increase bounding_box <%s> by <%s>", bounding_box, bounding_box_modify)
        for point, position in pairs(sBoundingBox) do
            position.x = position.x + sBoundingBoxMod[point].x
            position.y = position.y + sBoundingBoxMod[point].y
        end
        Logger.trace("Modified bounding_box: %s", sBoundingBox)
        return sBoundingBox
    else
        Logger.error("Failed to standardize bounding_box <%s> or modifier <%s>, defaulting to input bounding_box",
                bounding_box,
                bounding_box_modify
        )
        return bounding_box
    end
end

function Area.grow_bounding_box_by_n(bounding_box, n) -- TODO - testing
    local negN = n * -1
    return Area.modify_bounding_box(bounding_box, {
        left_top = {
            x = negN, -- Left
            y = negN  -- Top
        },
        right_bottom = {
            x = n, -- Right
            y = n  -- Bottom
        }
    })
end

function Area.shrink_bounding_box_by_n(bounding_box, n) -- TODO - testing
    local negN = n * -1
    return Area.modify_bounding_box(bounding_box, {
        left_top = {
            x = n,
            y = n
        },
        right_bottom = {
            x = negN,
            y = negN
        }
    })
end

function Area.standardize_bounding_box(bounding_box)
    Logger.trace("Attempting to standardize bounding_box: %s", bounding_box)
    if bounding_box == nil or type(bounding_box) ~= "table" then
        Logger.error("Failed to standardize invalid bounding_box: %s", bounding_box)
        return
    end

    if bounding_box.left_top and bounding_box.right_bottom then
        Logger.trace("Bounding_box has left_top and right_bottom")
        local lf = Position.standardize(bounding_box.left_top)
        local rb = Position.standardize(bounding_box.right_bottom)
        if lf and rb then
            Logger.trace("Bounding_box already had left_top & bottom_right, or was fully standardized. Returning deepcopy...")
            return {left_top = lf, right_bottom = rb} -- Position.standardize always returns a deepcopy as well
        end
    end

    if #bounding_box ~= 2 or type(bounding_box[1]) ~= "table" or type(bounding_box[2]) ~= "table" then
        Logger.error("Failed to standardize bounding_box, invalid table(s) (expected {{x,y},{a,b}}): %s", bounding_box)
        return
    end

    local lt = Position.standardize(bounding_box[1])
    local rb = Position.standardize(bounding_box[2])
    if lt and rb then
        local standardized = {
            left_top = Position.standardize(bounding_box[1]),
            right_bottom = Position.standardize(bounding_box[2])
        }
        Logger.trace("Bounding_box standardized: %s", standardized)
        return standardized
    end
end

function Area.get_bounding_box_vertices(bounding_box)
    Logger.trace("Attempting to get vertices of bounding box: %s", bounding_box)
    bounding_box = Area.standardize_bounding_box(bounding_box)
    if bounding_box then
        local leftTop = bounding_box.left_top
        local rightBottom = bounding_box.right_bottom
        local vertices = {
            left_top = leftTop,
            right_bottom = rightBottom,
            left_bottom = {x = leftTop.x, y = rightBottom.y},
            right_top = {x = rightBottom.x, y = leftTop.y}
        }
        Logger.trace("Vertices calculated: %s", vertices)
        return vertices
    end
end

function Area.get_chunk_position_from_position(position)
    Logger.trace("Attempting to get chunk position from normal position: %s", position)
    position = Position.standardize(position)
    if position then
        local chunkPosition = { x = math.floor(position.x / 32), y = math.floor(position.y / 32)}
        Logger.trace("Chunk position: %s", chunkPosition)
        return chunkPosition
    end
end

function Area.get_chunk_area_from_position(position)
    Logger.trace("Attempting to get chunk area from normal position: %s", position)
    return Area.get_chunk_area_from_chunk_position(Area.get_chunk_position_from_position(position))
end

function Area.get_chunk_area_from_chunk_position(chunkPosition)
    Logger.trace("Attempting to get chunk area from chunk position: %s", chunkPosition)
    chunkPosition = Position.standardize(chunkPosition)
    if chunkPosition then
        local area = {
            left_top = {
                x = chunkPosition.x * 32,
                y = chunkPosition.y * 32
            },
            right_bottom = {
                x = (chunkPosition.x + 1) * 32,
                y = (chunkPosition.y + 1) * 32
            }
        }
        Logger.trace("Chunk area: %s", area)
        return area
    end
end

return Area
