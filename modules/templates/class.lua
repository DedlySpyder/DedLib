local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}
local Class = {}

function Class.create(typeName)
    local class = {}
    class.__which = typeName
    setmetatable(class, Class)

    return class
end

function Class:validate_property(prop, expectedType, failOnNil)
    local p = rawget(self, prop)
    if p ~= nil or failOnNil then
        local pType = type(p)
        if pType ~= expectedType then
            Logger:fatal("Validation for %s of %s failed: %s", prop, self.__which, self)
            error(self.__which .. " failed validation for " .. prop .. ", see logs for more details")
        end
    end
end
