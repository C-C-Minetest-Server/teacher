-- teacher/teacher_core/src/register.lua
-- Register tutorial entries
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

-- local _int = teacher.internal
-- local logger = _int.logger:sublogger("register")

---@class TeacherTutorialPage: table
---@field title? string The title of the page. default: Title of the tutorial set
---@field text string The content text of the page.
---@field texture The screenshot/texture of the page. Must be 16:9 image.

---@class TeacherTutorialSet: TeacherTutorialPage[]
---@field title string The title of the tutorial set
---@field triggers? table[] List of triggers
---@field show_on_unlock? boolean Whether to show the tutorial upon unlocking. default: `false`

---Table of registered tutorials
---@type { [string]: TeacherTutorialSet }
teacher.registered_tutorials = {}

---Register tutorial entry
---@param name string
---@param def TeacherTutorialSet
function teacher.register_turorial(name, def)
    teacher.registered_tutorials[name] = def
end
