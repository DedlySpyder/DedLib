local Logger = require("logger").create{modName = "DedLib", prefix = "Area"}

local Area = {} -- TODO -- tests

function Area.area_of_entity(entity)
    Logger.trace("Finding area of an entity")
    if entity and entity.valid and entity.bounding_box then
        local bb = Area.standardize_bounding_box(entity.bounding_box)
        local area = (math.ceil(bb.right_bottom.x) - math.floor(bb.left_top.x)) * (math.ceil(bb.right_bottom.y) - math.floor(bb.left_top.y))
        Logger.trace("Area of entity is " .. area)
        Logger.trace(bb)
        return area
    else
        Logger.error("Entity is nil, invalid, or missing bounding_box")
    end
end

function Area.standardize_bounding_box(bounding_box)
    Logger.trace("Attempting to standardize bounding_box:")
    Logger.trace(bounding_box)
    if bounding_box == nil or type(bounding_box) ~= "table" then
        Logger.error("Failed to standardize invalid bounding_box: " .. serpent.line(bounding_box))
        return
    end

    if bounding_box.left_top and bounding_box.right_bottom then
        Logger.trace("Bounding_box has left_top and right_bottom")
        local lf = Area.standardize_position(bounding_box.left_top)
        local rb = Area.standardize_position(bounding_box.right_bottom)
        if bounding_box.left_top.x == lf.x and
                bounding_box.left_top.y == lf.y and
                bounding_box.right_bottom.x == rb.x and
                bounding_box.right_bottom.y == rb.y then
            Logger.trace("Bounding_box was already standardized")
            return bounding_box
        else
            local standardized = {left_top = lf, right_bottom = rb}
            Logger.trace("Bounding_box standardized:")
            Logger.trace(standardized)
            return standardized
        end
    end

    if #bounding_box < 2 or type(bounding_box[1]) ~= "table" or type(bounding_box[2]) ~= "table" then
        Logger.error("Failed to standardize bounding_box, invalid table(s) (expected {{x,y},{a,b}}): " .. serpent.line(bounding_box))
        return
    end
    local standardized = {
        left_top = Area.standardize_position(bounding_box[1]),
        right_bottom = Area.standardize_position(bounding_box[2])
    }
    Logger.trace("Bounding_box standardized:")
    Logger.trace(standardized)
    return standardized
end

function Area.standardize_position(position)
    Logger.trace("Attempting to standardize position:")
    Logger.trace(position)
    if position == nil or type(position) ~= "table" then
        Logger.error("Failed to standardize invalid position: " .. serpent.line(position))
        return
    end

    if position.x and position.y then
        Logger.trace("Position was already standardized")
        return position
    end

    if #position < 2 then
        Logger.error("Failed to standardize position missing x and/or y: " .. serpent.line(position))
        return
    end
    local standardized = {x = position[1], y = position[2]}
    Logger.trace("Standardized position:")
    Logger.trace(standardized)
    return standardized
end

function Area.get_chunk_position_from_position(position)
    Logger.trace("Attempting to get chunk position from normal position:")
    Logger.trace(position)
    position = Area.standardize_position(position)
    if position then
        local chunkPosition = { x = math.floor(position.x / 32), y = math.floor(position.y / 32)}
        Logger.trace("Chunk position:")
        Logger.trace(chunkPosition)
        return chunkPosition
    end
end

function Area.get_chunk_area_from_position(position)
    Logger.trace("Attempting to get chunk area from normal position:")
    Logger.trace(position)
    return Area.get_chunk_area_from_chunk_position(Area.get_chunk_position_from_position(position))
end

function Area.get_chunk_area_from_chunk_position(chunkPosition)
    Logger.trace("Attempting to get chunk area from chunk position:")
    Logger.trace(chunkPosition)
    chunkPosition = Area.standardize_position(chunkPosition)
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
        Logger.trace("Chunk area:")
        Logger.trace(area)
        return area
    end
end

return Area
