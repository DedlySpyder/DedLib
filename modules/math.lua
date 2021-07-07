local Table = require("__DedLib__/modules/table")

local Math = {}


-- Nil safe min/max
function Math.min(...)
    return math.min(unpack(Table.compact_list({...})))
end

function Math.max(...)
    return math.max(unpack(Table.compact_list({...})))
end


return Math
