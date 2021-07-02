local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}

local Position = {}


function Position.standardize(position)
    Logger:trace("Attempting to standardize position: %s", position)
    if position == nil or type(position) ~= "table" then
        Logger:error("Failed to standardize invalid position: %s", position)
        return
    end

    if position.x and position.y then
        Logger:trace("Position was already standardized, returning deepcopy...")
        return {x = position.x, y = position.y}
    end

    if #position ~= 2 then
        Logger:error("Failed to standardize position missing x and/or y: %s", position)
        return
    end
    local standardized = {x = position[1], y = position[2]}
    Logger:trace("Standardized position: %s", standardized)
    return standardized
end

function Position.is_equal(p1, p2) -- TODO - tests
    local c = Position.compare(p1, p2)
    if c then
        return c == 0
    else
        return false
    end
end

function Position.is_less_than(p1, p2) -- TODO - tests
    local c = Position.compare(p1, p2)
    if c then
        return c == -1
    else
        return false
    end
end

function Position.is_less_than_or_equal(p1, p2) -- TODO - tests
    local c = Position.compare(p1, p2)
    if c then
        return c <= 0
    else
        return false
    end
end

function Position.is_greater_than(p1, p2) -- TODO - tests
    local c = Position.compare(p1, p2)
    if c then
        return c == 1
    else
        return false
    end
end

function Position.is_greater_than_or_equal(p1, p2) -- TODO - tests
    local c = Position.compare(p1, p2)
    if c then
        return c >= 0
    else
        return false
    end
end

function Position.compare(p1, p2) -- TODO - tests
    Logger:trace("Comparing 2 positions: <%s> <%s>", p1, p2)
    p1 = Position.standardize(p1)
    p2 = Position.standardize(p2)
    if p1 and p2 then
        if p1.x == p2.x and p1.y == p2.y then
            Logger:trace("Positions are equal: <%s> <%s>", p1, p2)
            return 0

        elseif p1.x >= p2.x and p1.y >= p2.y then
            Logger:trace("<%s> is greater than <%s>", p1, p2)
            return 1

        elseif p1.x <= p2.x and p1.y <= p2.y then
            Logger:trace("<%s> is less than <%s>", p1, p2)
            return -1

        else
            Logger:trace("Positions are not comparable (both greater than and equal to): <%s> <%s>", p1, p2)
            return nil

        end
    else
        Logger:error("One or both of the positions are invalid after standardization: <%s> <%s>", p1, p2)
    end
end


return Position