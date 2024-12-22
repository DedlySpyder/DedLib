-- TODO - this was in control to run some stuff for this
--local Gui = require("modules/gui/gui")
--local Help = require("modules/help")
--script.on_event(defines.events.on_tick, function(e)
--    --log(serpent.block(Help.parse_help_string(game.help())))
--    Gui.test()
--    script.on_event(defines.events.on_tick, nil)
--end)



local Logger = require("__DedLib__/modules/logger").create{modName = "DedLib"}
local Help = require("__DedLib__/modules/help")
local Table = require("__DedLib__/modules/table")

local Gui = {}

function Gui.build(parent, data)
    data = Table.to_list(data)
    Logger:trace("Building gui from parent %s with %s elements", parent, #data)

    for _, elementData in ipairs(data) do
        Gui._recursive_build(parent, elementData)
    end
end

function Gui.help(element)
    return Help.get_help("LuaGuiElement", element)
end

function Gui._recursive_build(parent, data)
    Logger:debug("Building gui on parent %s: %s", parent, data)

    local children = Table.to_list(data.children)
    local updates = data.updates
    data.children = nil
    data.updates = nil

    local element = parent.add(data)

    Gui._apply_updates(element, updates)

    for _, child in ipairs(children) do
        Gui._recursive_build(element, child)
    end
end

function Gui._apply_updates(element, updates)
    if updates then
        local updatesType = type(updates)
        if updatesType == "function" then
            updates(element)
            return
        elseif updatesType ~= "table" then
            Logger:error("Invalid updates for %s, expected a function or table of key/values, got: %s", element, updates)
        end

        local help = Gui.help(element)
        for name, args in pairs(updates) do
            local argsType = type(args)
            if help.methods[name] then
                Logger:trace("Applying update to %s through method %s: %s", element, name, args)
                if argsType == "table" then
                    element[name](unpack(args))
                else
                    element[name](args)
                end

            elseif help.values[name] then
                Logger:trace("Applying update to %s through value %s: %s", element, name, args)
                local updateFunc = Gui.Updates[name]
                if updateFunc and argsType ~= "function" then
                    args = Gui.Updates._closure(updateFunc, args, argsType)
                    argsType = "function"
                end

                if argsType == "function" then
                    args(element[name])

                elseif help.values[name].write then
                    element[name] = args

                else
                    Logger:error("Could not apply update to %s, %s is not writeable or a function was not provided", element, name)
                end

            else
                Logger:error("Invalid field to update on %s: %s", element, name)
            end
        end
    end
end

Gui.Updates = {}
function Gui.Updates._closure(func, args, argsType)
    return function(property)
        func(property, args, argsType)
    end
end

function Gui.Updates.style(style, args, argsType)
    if argsType == "table" then
        Logger:trace("Applying style GUI update")
        for property, value in pairs(args) do
            style[property] = value
        end
    else
        Logger:error("Failed to apply style GUI update, table expected, got: %s", args)
    end
end

function Gui.test()
    Gui.build(game.players[1].gui.center, {
        type = "frame",
        caption = "TESTING",
        name = "root",
        children = {
            type = "frame",
            caption = "CHILD",
            name = "child",
            children = {
                {
                    type = "frame",
                    caption = "grandchild1",
                    name = "grandchild1",
                    updates = {
                        destroy = {}
                    }
                },
                {
                    type = "frame",
                    caption = "grandchild2",
                    name = "grandchild2",
                    updates = {
                        add = {{type = "frame", caption = "bastard"}},
                        style = {
                            width = 50
                        }
                    }
                }
            },
            updates = {
                direction = "vertical" -- read only, so no-op
            }
        },
        updates = {
            caption = "OVERRIDEN CAPTION"
        }
    })
end


return Gui