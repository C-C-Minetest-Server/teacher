-- teacher/teacher_core/src/chat.lua
-- Chat commands
-- depends: register, api, gui_simple_show
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = teacher.internal
local S = _int.S
local logger = _int.logger:sublogger("chat")

minetest.register_chatcommand("teacher_unlock", {
    description = S("Unlock a tutorial for a player"),
    params = "<target> <entry_name>",
    privs = { server = true },
    func = function(name, param)
        local splits = string.split(param, " ", false, 1)
        local target, entry_name = splits[1], splits[2]
        if not entry_name then
            return false, S("Invalid usage, see /help @1", "teacher_unlock")
        end

        local player = minetest.get_player_by_name(target)
        if not player then
            return false, S("Player @1 is not online.", target)
        end

        if not teacher.registered_tutorials[entry_name] then
            return false, S("Invalid entry: @1", entry_name)
        end

        if teacher.unlock_entry_for_player(player, entry_name) then
            logger:action(("%s unlocked entry %s for %s"):format(name, entry_name, target))
            return true, S("Unlocked entry @1 for @2.", entry_name, target)
        else
            return false, S("Failed to unlock entry @1 for @2.", entry_name, target)
        end
    end,
})

minetest.register_chatcommand("teacher_simple_show", {
    description = S("Show a tutorial using the simple GUI"),
    params = "<entry_name>",
    privs = { interact = true },
    func = function(name, param)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, S("You must be online to use this command.")
        end

        if not teacher.registered_tutorials[param] then
            return false, S("Invalid entry: @1", param)
        end

        local data = teacher.get_player_data(player)
        if not data[param] then
            return false, S("Invalid entry: @1", param)
        end

        teacher.simple_show(player, param)
        return true, S("GUI shown.")
    end,
})

local tutorials_def = {
    description = S("Show all unlocked tutorials"),
    func = function(name, _)
        local player = minetest.get_player_by_name(name)
        if not player then
            return false, S("You must be online to use this command.")
        end

        teacher.show_all(player)
        return true, S("GUI shown.")
    end,
}

minetest.register_chatcommand("tutorials", tutorials_def)
minetest.register_chatcommand("tutorial", tutorials_def)
