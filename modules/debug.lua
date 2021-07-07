-- For common usage of the debug library
local Util = require("__DedLib__/modules/util")

local Debug = {}

function Debug.get_current_line(f)
    local info = debug.getinfo(f)
    return info.short_src, info.currentline
end

function Debug.get_defined_line(f)
    local info = debug.getinfo(f)
    return info.short_src, info.linedefined
end


function Debug.parse_code_line_string(src, line)
    return src .. ":" .. line
end

function Debug.get_defined_line_string(f)
    return Debug.parse_code_line_string(Debug.get_defined_line(f))
end

function Debug.get_current_line_string(f)
    return Debug.parse_code_line_string(Debug.get_current_line(f))
end



function Debug.parse_short_code_line_string(src, line)
    local srcParts = Util.String.split(src, "/")
    src = srcParts[#srcParts]
    return src .. ":" .. line
end

function Debug.get_short_defined_line_string(f)
    return Debug.parse_short_code_line_string(Debug.get_defined_line(f))
end

function Debug.get_short_current_line_string(f)
    return Debug.parse_short_code_line_string(Debug.get_current_line(f))
end


return Debug
