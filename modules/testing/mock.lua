local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}

local Mock = {}

function Mock.get_valid_lua_object(values)
    if not values then values = {} end
    if type(values) ~= "table" then
        local msg = "Values for mock lua_object is not a table: " .. tostring(values)
        Logger:fatal(msg)
        error(msg)
    end
    values.valid = true
    return values
end

return Mock