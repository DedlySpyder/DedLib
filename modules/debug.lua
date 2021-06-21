-- For common usage of the debug library

local Debug = {}


function Debug.get_defined(f)
    local info = debug.getinfo(f)
    return info.short_src, info.linedefined
end

function Debug.get_defined_string(f)
    local src, line = Debug.get_defined(f)
    return src .. ":" .. line
end


return Debug