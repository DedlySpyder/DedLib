local Logger = require("logger").create{modName = "DedLib", prefix = "Entity"}
local Area = require("area")

local Entity = {}

function Entity.area_of(entity)
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

return Entity