local LoggerLib = require("__DedLib__/modules/logger")
local Logger = LoggerLib.create("Template")
local Util = require("__DedLib__/modules/util")

local Storage = {}
Storage.__index = Storage

--[[
Quick usage:
- call Storage.new() with on_init and on_load functions to handle those events
- add Storage:on_init() and Storage:on_load() in your on_init/on_load respectively
- - Alternatively, call the on_init_wrapped()/on_load_wrapped() if they are not in a function -- i.e. script.on_init(Storage:on_init_wrapped())
- call Storage:build_loggers() after any sub sections are created
- - Storage.DataTypeName = {} with functions in this table are assumed, they can access their own logger at `Storage.DataTypeName._LOGGER` or `Storage.DataTypeName.get_logger()`

In functions you can access a cached `Storage.global` which is a direct reference to the normal global
(This access is _slightly_ faster for rapid use)
]]--


function Storage.new(args)
    local new = {}
    setmetatable(new, Storage)

    new.on_init_func = Util.ternary(type(args.on_init) == "function", args.on_init, function() end)
    new.on_load_func = Util.ternary(type(args.on_load) == "function", args.on_load, function() end)

    return new
end

function Storage:on_init()
    Logger:trace("Running Storage on_init...")
    Storage._cache_global()
    self:on_init_func()
end

function Storage:on_init_wrapped()
    return function()
        self:on_init()
    end
end

function Storage:on_load()
    Logger:trace("Running Storage on_load...")
    Storage._cache_global()
    self:on_load_func()
end

function Storage:on_load_wrapped()
    return function()
        self:on_load()
    end
end

function Storage:build_loggers()
    for name, subSection in pairs(self) do
        if type(subSection) == "table" then
            Logger:trace("Building Storage logger for %s", name)
            subSection._LOGGER = LoggerLib.create(name)
            function subSection.get_logger()
                return subSection._LOGGER
            end
        end
    end
end


-- Internal Methods
function Storage._cache_global()
    Storage.global = global
    return Storage.global
end

return Storage
