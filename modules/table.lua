local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib", prefix = "Table"}

local Table = {}


function Table.indexify(tbl)
    local t = {}
    for _, v in pairs(tbl) do
        t[v] = true
    end
    return t
end

-- Shifts a list/table *in place* to the left by n keys
-- ({1,2,3,4}, 2) = {3,4}
function Table.shift(tbl, n)
    if not n then n = 1 end
    local len = #tbl
    if n >= len then return {} end

    local t = {}
    for i = n + 1, len do
        t[i - n] = tbl[i]
    end
    return t
end

return Table