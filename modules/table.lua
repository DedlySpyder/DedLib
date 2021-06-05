local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib", prefix = "Table"}

local Table = {}


function Table.indexify(tbl)
    local t = {}
    for _, v in pairs(tbl) do
        t[v] = true
    end
    return t
end


return Table