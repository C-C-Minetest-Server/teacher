-- teacher/teacher_core/src/api.lua
-- API to interact with the data
-- depends: storage, register
-- runtime: gui_simple_show
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = teacher.internal
local S = _int.S
-- local logger = _int.logger:sublogger("api")

---Callbacks called when an entry is unlocked
---@type { func: fun(player: ObjectRef, entry_name: string), origin: string }[]
teacher.registered_on_unlock = {}

---Register callbacks to be called when an entry is unlocked
---@param func fun(player: ObjectRef, entry_name: string)
function teacher.register_on_unlock(func)
    local mod = minetest.get_current_modname() or "??"
    teacher.registered_on_unlock[#teacher.registered_on_unlock + 1] = {
        func = func,
        origin = mod
    }
end

---Run callbacks for an entry unlock event
---@param player ObjectRef
---@param entry_name string
function teacher.run_unlock_callbacks(player, entry_name)
    local last_run_mod = minetest.get_last_run_mod()
    for _, def in ipairs(teacher.registered_on_unlock) do
        minetest.set_last_run_mod(def.origin)
        def.func(player, entry_name)
        minetest.set_last_run_mod(last_run_mod)
    end
end

---Notify players about unlocked tutorial
teacher.register_on_unlock(function(player, entry_name)
    local entry = teacher.registered_tutorials[entry_name]

    if entry.show_on_unlock then
        teacher.simple_show(player, entry_name, entry.show_disallow_close)
    else
        local name = player:get_player_name()
        local display_name = entry.title or entry_name

        local msg = S("New tutorial unlocked: @1", display_name) .. "\n"
        if minetest.global_exists("unified_inventory") then
            msg = msg .. S("Type in /tutorials to check it out, or by the icon in your inventory.")
        else
            msg = msg .. S("Type in /tutorials to check it out.")
        end

        minetest.chat_send_player(name, minetest.colorize("orange", msg))
    end
end)

---Unlock an entry or entries for a player
---This function does not check whether the entry exists.
---@param player ObjectRef
---@param entry_name string|string[]
---@param time? integer default: `os.time()`
---@param override? boolean Whether to override existing records. default: `false`
---@return boolean success `false` if any failed.
---@see teacher.get_player_data
---@see teacher.set_player_data
function teacher.unlock_entry_for_player(player, entry_name, time, override)
    local data = teacher.get_player_data(player)

    local entries = entry_name
    if type(entry_name) == "string" then
        entries = { entry_name }
    end

    local success = true
    for _, entry in ipairs(entries) do
        if override or not data[entry] then
            time = time or os.time()
            data[entry] = time
            teacher.run_unlock_callbacks(player, entry)
        else
            success = false
        end
    end

    teacher.set_player_data(player, data)
    return success
end

---Check whether an entry has been unlocked for a player
---This function does not check whether the entry exists.
---Return `false` if not unlocked, otherwise the unlock time.
---@param player ObjectRef
---@param entry_name string
---@return integer|boolean
---@see teacher.get_player_data
function teacher.has_unlocked(player, entry_name)
    local data = teacher.get_player_data(player)
    return data[entry_name] or false
end

---Cleanup unregistered entries from a player's database
---@param player ObjectRef
function teacher.cleanup_player_entries(player)
    local data = teacher.get_player_data(player)
    for name, _ in pairs(data) do
        if not teacher.registered_tutorials[name] then
            data[name] = nil
        end
    end
    teacher.set_player_data(player, data)
end

minetest.register_on_joinplayer(function(player)
    teacher.cleanup_player_entries(player)
end)
