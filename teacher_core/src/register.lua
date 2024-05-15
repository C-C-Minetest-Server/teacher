-- teacher/teacher_core/src/register.lua
-- Register tutorial entries
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = teacher.internal
local logger = _int.logger:sublogger("register")

---@class TeacherTutorialPage: table
---@field title? string The title of the page. default: Title of the tutorial set
---@field text string The content text of the page.
---@field texture The screenshot/texture of the page. Must be 16:9 image.

---@class TeacherTutorialSet: TeacherTutorialPage[]
---@field title string The title of the tutorial set
---@field triggers? table[] List of triggers

---Table of registered tutorials
---@type { [string]: TeacherTutorialSet }
teacher.registered_tutorials = {}

---Register tutorial entry
---@param name string
---@param def TeacherTutorialSet
function teacher.register_turorial(name, def)
    teacher.registered_tutorials[name] = def
end

---Table of tables containing tutorials with a specific trigger

---@type { [string]: { name: string, trigger: table }[] }
teacher.registered_tutorials_with_trigger = {}

minetest.register_on_mods_loaded(function()
    for name, def in pairs(teacher.registered_tutorials) do
        local added = false

        if def.trigers then
            for trigger_i, trigger in ipairs(def.trigers) do
                logger:assert(type(trigger.name) == "string",
                    ("In tutorial %s: invalid trigger.name type in trigger #%d: %s"):format(
                        name, trigger_i, type(trigger.name)
                    ))
                local tb = teacher.registered_tutorials_with_trigger[trigger.name] or {}
                tb[#tb+1] = {
                    name = name,
                    trigger = trigger,
                }
                teacher.registered_tutorials_with_trigger[trigger.name] = tb
                added = true
            end
        end

        local none_tb = {}
        if not added then
            none_tb[#none_tb+1] = {
                name = name,
                trigger = {
                    name = "none",
                }
            }
        end
        teacher.registered_tutorials_with_trigger.none = none_tb
    end
end)
