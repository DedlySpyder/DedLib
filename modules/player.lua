local Player = {}


-- Ghosts count as empty
function Player.is_cursor_empty(player)
    return player.cursor_stack == nil or not player.cursor_stack.valid_for_read
end


return Player