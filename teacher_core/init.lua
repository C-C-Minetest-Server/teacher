-- teacher/teacher_core/init.lua
-- Minetest Tutoial API
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

teacher = {}
teacher.internal = {}
teacher.internal.S = minetest.get_translator("teacher")
teacher.internal.logger = logging.logger("teacher")

local MP = minetest.get_modpath("teacher_core")
for _, name in ipairs({
    "settings",
    "storage",
    "register",
    "trigger",         -- depend: register
    "api",             -- depends: storage, register
    "gui_simple_show", -- depends: api, register
    "gui_list_all",    -- depends: api, register
    "chat",            -- depends: register, api, gui_simple_show
}) do
    dofile(MP .. "/src/" .. name .. ".lua")
end
