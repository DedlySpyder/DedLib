local Table = require("__DedLib__/modules/table")

local Dependent = {}
Dependent.__which = "Dependent"

Dependent._parent_dependency = nil
Dependent._dependent_children = {}


function Dependent.build_dependency_tree(list, parent)
    local children = Table.filter(list, function(item) return item._parent_dependency == parent end)
    -- https://www.naept.com/en/blog/a-simple-tree-building-algorithm/
end

function Dependent.depends_on(dependent)
    error("Dependent.depends_on not implemented")
end


return Dependent