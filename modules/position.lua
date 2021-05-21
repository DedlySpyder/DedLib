local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib", prefix = "Position"}

local Position = {}


function Position.standardize(position) --TODO this moved from Area.standardize_position
    Logger.trace("Attempting to standardize position: %s", position)
    if position == nil or type(position) ~= "table" then
        Logger.error("Failed to standardize invalid position: %s", position)
        return
    end

    if position.x and position.y then
        Logger.trace("Position was already standardized")
        return position
    end

    if #position ~= 2 then
        Logger.error("Failed to standardize position missing x and/or y: %s", position)
        return
    end
    local standardized = {x = position[1], y = position[2]}
    Logger.trace("Standardized position: %s", standardized)
    return standardized
end

function Position.compare(p1, p2) -- TODO tests
    Logger.trace("Comparing 2 positions: <%s> <%s>", p1, p2)
    p1 = Position.standardize(p1)
    p2 = Position.standardize(p2)
    if p1 and p2 then
        local isEqual = p1.x == p2.x and p1.y == p2.y
        Logger.trace("Position is equal result: %s", isEqual)
        return isEqual
    else
        Logger.error("One or both of the positions are invalid after standardization: <%s> <%s>", p1, p2)
    end
end


return Position