-- teacher/teacher_core/src/trigger.lua
-- handle tutorial trigger
-- depend: register
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = teacher.internal
local logger = _int.logger:sublogger("trigger")

---Table of tables containing tutorials with a specific trigger

---@type { [string]: { name: string, trigger: table }[] }
teacher.registered_tutorials_with_trigger = {}

minetest.register_on_mods_loaded(function()
    for name, def in pairs(teacher.registered_tutorials) do
        local added = false

        if def.triggers then
            for trigger_i, trigger in ipairs(def.triggers) do
                logger:assert(type(trigger.name) == "string",
                    ("In tutorial %s: invalid trigger.name type in trigger #%d: %s"):format(
                        name, trigger_i, type(trigger.name)
                    ))
                local tb = teacher.registered_tutorials_with_trigger[trigger.name] or {}
                tb[#tb + 1] = {
                    name = name,
                    trigger = trigger,
                }
                teacher.registered_tutorials_with_trigger[trigger.name] = tb
                added = true
            end
        end

        local none_tb = {}
        if not added then
            none_tb[#none_tb + 1] = {
                name = name,
                trigger = {
                    name = "none",
                }
            }
        end
        teacher.registered_tutorials_with_trigger.none = none_tb
    end
end)

function teacher.trigger_check_approach_pos(player, trigger)
    local pos = vector.subtract(trigger.pos, player:get_pos())
    if math.sqrt(pos.x ^ 2 + pos.y ^ 2 + pos.z ^ 2) <= (trigger.radius or 3) then
        return true
    end
    return false
end

function teacher.trigger_check_approach_node(player, trigger)
    return minetest.find_node_near(player:get_pos(), trigger.radius or 3, trigger.nodenames, true)
end

local connected_players = modlib.minetest.connected_players
modlib.minetest.register_globalstep(1, function()
    for player in connected_players() do
        if teacher.registered_tutorials_with_trigger.approach_pos then
            for _, value in ipairs(teacher.registered_tutorials_with_trigger.approach_pos) do
                if teacher.trigger_check_approach_pos(player, value.trigger) then
                    teacher.unlock_entry_for_player(player, value.name)
                    break
                end
            end
        end

        if teacher.registered_tutorials_with_trigger.approach_node then
            for _, value in ipairs(teacher.registered_tutorials_with_trigger.approach_node) do
                if teacher.trigger_check_approach_node(player, value.trigger) then
                    teacher.unlock_entry_for_player(player, value.name)
                    break
                end
            end
        end
    end
end)

-- Check obtain_item unlock

function teacher.trigger_check_obtain_item_logic(itemstack, player)
    if teacher.registered_tutorials_with_trigger.obtain_item then
        local itemname = itemstack:get_name()
        for _, value in ipairs(teacher.registered_tutorials_with_trigger.obtain_item) do
            if value.itemname == itemname then
                teacher.unlock_entry_for_player(player, value.name)
                break
            end
        end
    end
end

--> Obtained via crafting
minetest.register_on_craft(function(itemstack, player)
    teacher.trigger_check_obtain_item_logic(itemstack, player)
end)

--> Obtained via picking up
minetest.register_on_item_pickup(function(itemstack, player)
    teacher.trigger_check_obtain_item_logic(itemstack, player)
end)

--> Obtained via putting into inventory
minetest.register_on_player_inventory_action(function(player, action, _, inventory_info)
    if action ~= "put" then return end
    local itemstack = inventory_info.stack
    teacher.trigger_check_obtain_item_logic(itemstack, player)
end)
