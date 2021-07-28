local Table = {}


function Table.get_or_default(tbl, key, default)
    if tbl and tbl[key] then
        return tbl[key]
    end
    return default
end

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

function Table.map(tbl, func)
    local t = {}
    local isArr = #tbl > 0
    for k, v in pairs(tbl) do
        if isArr then
            local newValue = func(v)
            if newValue ~= nil then
                table.insert(t, newValue)
            end
        else
            t[k] = func(v)
        end
    end
    return t
end

function Table.swap_key_values(tbl)
    local t = {}
    if #tbl > 0 then return Table.indexify(tbl) end
    for k, v in pairs(tbl) do
        t[v] = k
    end
    return t
end

function Table.filter(tbl, func)
    local t = {}
    local isArr = #tbl > 0
    for k, v in pairs(tbl) do
        if func(v) then
            if isArr then
                table.insert(t, v)
            else
                t[k] = v
            end
        end
    end
    return t
end

-- Flatten by 1 layer
function Table.flatten(tbl)
    local t = {}
    for _, v in pairs(tbl) do
        if type(v) == "table" then
            for _, subV in pairs(v) do
                table.insert(t, subV)
            end
        else
            table.insert(t, v)
        end
    end
    return t
end

function Table.compact_list(tbl)
    local t = {}
    for _, v in ipairs(tbl) do
        if v ~= nil then
            table.insert(t, v)
        end
    end
    return t
end

function Table.to_list(tbl)
    if not tbl then return {} end
    if #tbl == 0 then return {tbl} end
    return tbl
end


return Table