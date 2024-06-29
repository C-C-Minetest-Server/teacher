-- teacher/teacher_core/src/trigger.lua
-- handle tutorial trigger
-- depends: register
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = teacher.internal
local logger = _int.logger:sublogger("trigger")

---Table of tables containing tutorials with a specific trigger
---@type { [string]: { name: string, trigger: table }[] }
teacher.registered_tutorials_with_trigger = {}

local obtain_item_to_tutorials = {}
local obtain_item_group_to_tutorials = {}

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

    if teacher.registered_tutorials_with_trigger.obtain_item then
        for _, entry in ipairs(teacher.registered_tutorials_with_trigger.obtain_item) do
            if string.sub(entry.trigger.itemname, 1, 6) == "group:" then
                local groupname = string.sub(entry.trigger.itemname, 6)
                local tb = obtain_item_group_to_tutorials[groupname] or {}
                tb[#tb+1] = entry.name
                if not obtain_item_group_to_tutorials[groupname] then
                    obtain_item_group_to_tutorials[groupname] = tb
                end
            else
                local tb = obtain_item_to_tutorials[entry.trigger.itemname] or {}
                tb[#tb+1] = entry.name
                if not obtain_item_to_tutorials[entry.trigger.itemname] then
                    obtain_item_to_tutorials[entry.trigger.itemname] = tb
                end
            end
        end
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
                end
            end
        end

        if teacher.registered_tutorials_with_trigger.approach_node then
            for _, value in ipairs(teacher.registered_tutorials_with_trigger.approach_node) do
                if teacher.trigger_check_approach_node(player, value.trigger) then
                    teacher.unlock_entry_for_player(player, value.name)
                end
            end
        end

        if teacher.registered_tutorials_with_trigger.obtain_item then
            local inv = player:get_inventory()
            local main = inv:get_list("main")

            for _, stack in ipairs(main) do
                local itemname = stack:get_name()
                local def = stack:get_definition()

                if obtain_item_to_tutorials[itemname] then
                    for _, entry in ipairs(obtain_item_to_tutorials[itemname]) do
                        teacher.unlock_entry_for_player(player, entry)
                    end
                end

                if def.groups then
                    for groupname, _ in pairs(def.groups) do
                        if obtain_item_group_to_tutorials[groupname] then
                            for _, entry in ipairs(obtain_item_group_to_tutorials[groupname]) do
                                teacher.unlock_entry_for_player(player, entry)
                            end
                        end
                    end
                end
            end
        end

        if teacher.registered_tutorials_with_trigger.playstep then
            for _, value in ipairs(teacher.registered_tutorials_with_trigger.approach_node) do
                if value.trigger.func(player) then
                    teacher.unlock_entry_for_player(player, value.name)
                end
            end
        end
    end
end)

minetest.register_on_placenode(function(_, newnode, placer)
    if teacher.registered_tutorials_with_trigger.on_placenode then
        if not placer:is_player() or placer.is_fake_player then return end
        for _, value in ipairs(teacher.registered_tutorials_with_trigger.on_placenode) do
            if value.trigger.nodename == newnode.name then
                teacher.unlock_entry_for_player(placer, value.name)
            end
        end
    end
end)

minetest.register_on_dignode(function(_, oldnode, digger)
    if teacher.registered_tutorials_with_trigger.on_dignode then
        if not digger:is_player() or digger.is_fake_player then return end
        for _, value in ipairs(teacher.registered_tutorials_with_trigger.on_dignode) do
            if value.trigger.nodename == oldnode.name then
                teacher.unlock_entry_for_player(digger, value.name)
            end
        end
    end
end)
