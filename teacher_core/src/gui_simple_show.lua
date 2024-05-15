-- teacher/teacher_core/src/gui_simple_show.lua
-- Show the tutorial once
-- depends: api, register
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = teacher.internal
local S = _int.S
local logger = _int.logger:sublogger("gui_simple_show")
local gui = flow.widgets

---Simple flow formspec to show a single tutorial
teacher.gui_simple_show = flow.make_gui(function(_, ctx)
    ---@cast ctx table

    logger:assert(ctx.entry_name, "`entry_name` not passed into `teacher.gui_simple_show`")
    local entry = logger:assert(teacher.registered_tutorials[ctx.entry_name],
        "Invalid `entry_name` passed into `teacher.gui_simple_show`")

    ctx.page = ctx.page or 1
    local page = entry[ctx.page]

    return gui.VBox {
        max_w = 15, max_h = 10,

        gui.HBox {
            gui.Label {
                w = 10, h = 0.3,
                label = S("Tutorial: @1", page.title or entry.title or ctx.entry_name),
                expand = true, align_h = "left",
            },
            gui.ButtonExit {
                w = 0.3, h = 0.3,
                label = "x",
            },
        },
        gui.Box { w = 0.05, h = 0.05, color = "grey" },
        gui.Image {
            w = 8, h = 4.5,
            texture_name = page.texture or "teacher_no_texture.png",
            expand = true, align_h = "center",
        },
        gui.Textarea {
            w = 8, h = 3,
            default = page.text or ""
        },
        gui.HBox {
            (ctx.page == 1) and gui.Box { w = 2, h = 1, visible = false } or gui.Button {
                w = 2, h = 1,
                label = S("Back"),
                on_event = function(_, ctx_e)
                    ctx_e.page = ctx_e.page - 1
                    return true
                end,
            },
            gui.Label {
                h = 1,
                label = S("Page @1/@2", ctx.page, #entry),
                expand = true, align_h = "center",
            },
            (ctx.page == #entry) and gui.ButtonExit {
                w = 2, h = 1,
                label = S("Exit"),
            } or gui.Button {
                w = 2, h = 1,
                label = S("Next"),
                on_event = function(_, ctx_e)
                    ctx_e.page = ctx_e.page + 1
                    return true
                end,
            }
        },
    }
end)

---Show the given entry
---@param player ObjectRef
---@param entry_name string
function teacher.simple_show(player, entry_name)
    teacher.gui_simple_show:show(player, { entry_name = entry_name })
end

---Unlock the given entry, and show it to the player.
---This checks for the existance of the entry.
---@param player ObjectRef
---@param entry_name string
---@param time? integer default: `os.time()`
---@param override? bool Whether to override existing records. default: `false`
---@see teacher.unlock_entry_for_player
---@see teacher.gui_simple_show
function teacher.unlock_and_show(player, entry_name, time, override)
    logger:assert(teacher.registered_tutorials[entry_name],
        "Invalid `entry_name` passed into `teacher.unlock_and_show`")

    if teacher.unlock_entry_for_player(player, entry_name, time, override) then
        teacher.simple_show(player, entry_name)
        return true
    end
    return false
end
