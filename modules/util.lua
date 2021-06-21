require("__core__/lualib/util") -- Core Factorio lib

local Util = {}


function Util.ternary(test, successValue, failValue)
    if test then
        return successValue
    end
    return failValue
end

Util.String = {}
function Util.String.split(str, sep)
    return util.split(str, sep)
end

function Util.String.starts_with(str, start)
    return util.string_starts_with(str, start)
end

function Util.String.ends_with(str, endStr)
    local strLen = string.len(str)
    return str.sub(str, strLen - string.len(endStr) + 1, strLen) == endStr
end


return Util