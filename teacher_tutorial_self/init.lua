-- teacher/teacher_tutorial_self/init.lua
-- Tutorial about the Teacher mod itself
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local S = minetest.get_translator("teacher_tutorial_self")

teacher.register_turorial("teacher_tutorial_self:teacher", {
    title = S("The Teacher System"),
    {
        texture = "teacher_tutorial_self_teacher_1.png",
        text = S("To view your unlocked tutorials, type @1 in the chatroom.", "/tutorials"),
    },
    {
        texture = "teacher_tutorial_self_teacher_2.png",
        text = S("Select the tutorial you want to see in the left panel.")
    },
    {
        texture = "teacher_tutorial_self_teacher_3.png",
        text = S("Use the buttons at the bottom to navigate between pages.")
    }
})

---Unlock upon joining
minetest.register_on_joinplayer(function(player)
    teacher.unlock_entry_for_player(player, "teacher_tutorial_self:teacher")
end)
