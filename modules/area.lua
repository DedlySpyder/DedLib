local Logger = require("logger").create{ modName = "DedLib", prefix = "Area"}

local Area = {} -- TODO -- tests

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
