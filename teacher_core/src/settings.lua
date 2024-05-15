-- teacher/teacher_core/src/settings.lua
-- Read settings from minetest.conf
-- depends: storage, register
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

-- local _int = teacher.internal
-- local logger = _int.logger:sublogger("settings")

teacher.settings = settings_loader.load_settings("teacher.", {
    recent_threshold = {
        stype = "integer",
        default = 172800, -- 2 days
    }
}, true)
