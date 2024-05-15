-- teacher/teacher_core/src/storage.lua
-- data storage
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = teacher.internal
local logger = _int.logger:sublogger("storage")

---Get teacher data of a player
---@param player ObjectRef
---@return { [string]: integer }
function teacher.get_player_data(player)
    logger:assert(player:is_player(), "`player` is not a player ObjectRef")
    local meta = player:get_meta()
    local data_str = meta:get_string("teacher_unlocked")

    if data_str == "" then
        return {}
    end

    return minetest.deserialize(data_str)
end

---Set teacher data of a player
---@param player ObjectRef
---@param data { [string]: integer }
function teacher.set_player_data(player, data)
    logger:assert(player:is_player(), "`player` is not a player ObjectRef")
    local meta = player:get_meta()
    local data_str = minetest.serialize(data)
    meta:set_string("teacher_unlocked", data_str)
end
