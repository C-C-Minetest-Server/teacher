-- teacher/teacher_core/src/gui_list_all.lua
-- List all tutorials
-- depends: api, register
-- Copyright (C) 2024  1F616EMO
-- SPDX-License-Identifier: LGPL-3.0-or-later

local _int = teacher.internal
local S = _int.S
local logger = _int.logger:sublogger("gui_list_all")
local gui = flow.widgets

---@alias TeacherGroupCriteriaFunc fun(player: ObjectRef, entries: { [string]: integer }, entry_name: string): boolean

---@class TeacherGroupDefinition: table
---@field description string Display name of the group
---@field criteria TeacherGroupCriteriaFunc Determine whether an entry should be in a group
---@field sort? number Sorting key of the group, the higher the upper

---@type { [string]: TeacherGroupDefinition }
teacher.registered_groups = {
    none = {                                    -- Hard-coded
        description = S("Other Tutorials"),
        criteria = function() return false end, -- Only applied by divide_entry_by_group
        sort = 0,
    },
}

---Register a tutorial group
---@param name string The technical name of the group
---@param def TeacherGroupDefinition The definition of the group
function teacher.register_group(name, def)
    logger:assert(type(name) == "string", "The type of `name` must be a string.")
    logger:assert(name ~= "none", "The group name `none` is reserved for internal use.")
    teacher.registered_groups[name] = def
end

teacher.register_group("recent", {
    description = S("Recently Unlocked"),
    criteria = function(_, entries, entry_name)
        if teacher.settings.recent_threshold == 0 then
            return false
        end

        local now = os.time()
        local entry_time = entries[entry_name] or 0
        if now - entry_time < teacher.settings.recent_threshold then
            return true
        end

        return false
    end,
    sort = 10,
})

---Divide a list of entries into groups
---@param player ObjectRef
---@param entries { [string]: integer }
---@return { [string]: string[] }
function teacher.divide_entry_by_group(player, entries)
    local rtn = {}
    local visited = {}
    for group_name, group_def in pairs(teacher.registered_groups) do
        if group_name ~= "none" then
            local group_tbn = {}
            for entry_name, _ in pairs(entries) do
                if group_def.criteria(player, entries, entry_name) then
                    group_tbn[#group_tbn + 1] = entry_name
                    visited[entry_name] = true
                end
            end
            table.sort(group_tbn, function(a, b)
                return entries[a] > entries[b]
            end)
            rtn[group_name] = #group_tbn >= 1 and group_tbn or nil
        end
    end

    local none_tbn = {}
    for entry_name, _ in pairs(entries) do
        if not visited[entry_name] then
            none_tbn[#none_tbn + 1] = entry_name
        end
    end
    table.sort(none_tbn, function(a, b)
        local a_name = string.upper(teacher.registered_tutorials[a].title)
        local b_name = string.upper(teacher.registered_tutorials[b].title)
        return a_name < b_name
    end)
    rtn.none = #none_tbn >= 1 and none_tbn or nil

    return rtn
end

local function sort_entries_keys(entries)
    local keys = {}
    for key, _ in pairs(entries) do
        keys[#keys + 1] = key
    end
    table.sort(keys, function(a, b)
        return teacher.registered_groups[a].sort > teacher.registered_groups[b].sort
    end)
    return keys
end

teacher.gui_list_all = flow.make_gui(function(player, ctx)
    if not (ctx.list and ctx.textlist) then
        local entries = teacher.divide_entry_by_group(player, teacher.get_player_data(player))
        ctx.list = {}
        ctx.textlist = {}
        for _, group_name in ipairs(sort_entries_keys(entries)) do
            ctx.list[#ctx.list + 1] = false
            ctx.textlist[#ctx.textlist + 1] =
                "#808080" .. teacher.registered_groups[group_name].description or group_name
            for _, entry_name in ipairs(entries[group_name]) do
                if teacher.registered_tutorials[entry_name] then
                    ctx.list[#ctx.list + 1] = entry_name
                    ctx.textlist[#ctx.textlist + 1] =
                        "\t" .. teacher.registered_tutorials[entry_name].title or entry_name
                end
            end
        end
    end

    if #ctx.textlist == 0 then
        return gui.HBox {
            gui.Label {
                label = S("No tutorials to show.")
            },
            gui.ButtonExit {
                label = S("Exit")
            }
        }
    end

    local selected = ctx.form.textlist_select or 1
    if selected > #ctx.textlist then
        selected = 1
    elseif selected <= 0 then
        selected = #ctx.textlist
    end
    while ctx.list[selected] == false do
        selected = selected + 1
    end
    if not ctx.list[selected] then
        return gui.HBox {
            gui.Label {
                label = S("No tutorials to show.")
            },
            gui.ButtonExit {
                label = S("Exit")
            }
        }
    end
    ctx.form.textlist_select = selected

    local entry = teacher.registered_tutorials[ctx.list[selected]]

    if ctx.old_selected ~= selected then
        ctx.page = ctx.page == -1 and #entry or 1
        ctx.old_selected = selected
    else
        ctx.page = ctx.page == -1 and #entry or ctx.page
    end

    local page = entry[ctx.page]

    return gui.VBox {
        max_w = 20, max_h = 10,

        gui.HBox {
            gui.Label {
                w = 10, h = 0.3,
                label = S("All Tutorials"),
                expand = true, align_h = "left",
            },
            ctx.inside_sway and gui.Nil{} or gui.ButtonExit {
                w = 0.3, h = 0.3,
                label = "x",
            },
        },
        gui.Box { w = 0.05, h = 0.05, color = "grey" },

        gui.HBox {
            gui.Textlist {
                w = 5, h = 9,
                name = "textlist_select",
                listelems = ctx.textlist,
                on_event = function() return true end,
            },
            gui.VBox {
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
                    gui.Button {
                        w = 2, h = 1,
                        label = S("Back"),
                        on_event = (ctx.page == 1) and function(_, ctx_e)
                            ctx_e.form.textlist_select = ctx_e.form.textlist_select - 1
                            ctx_e.page = -1
                            return true
                        end or function(_, ctx_e)
                            ctx_e.page = ctx_e.page - 1
                            return true
                        end,
                    },
                    gui.Label {
                        h = 1,
                        label = S("Page @1/@2", ctx.page, #entry),
                        expand = true, align_h = "center",
                    },
                    gui.Button {
                        w = 2, h = 1,
                        label = S("Next"),
                        on_event = (ctx.page == #entry) and function(_, ctx_e)
                            ctx_e.form.textlist_select = ctx_e.form.textlist_select + 1
                            ctx_e.page = 1
                            return true
                        end or function(_, ctx_e)
                            ctx_e.page = ctx_e.page + 1
                            return true
                        end,
                    }
                },
            }
        }
    }
end)

---Show all entries to a player
---@param player ObjectRef
function teacher.show_all(player)
    teacher.gui_list_all:show(player)
end

-- Register unified_inventory button
if minetest.global_exists("unified_inventory") then
    unified_inventory.register_button("teacher_show_all", {
        type = "image",
        image = "teacher_ui_icon.png",
        tooltip = S("Tutorials"),
        action = function(player)
            teacher.show_all(player)
        end,
    })
end
if minetest.global_exists("sway") then
    local pagename = "teacher_core:teacher_show_all"
    sway.register_page(pagename, {
        title = S("Tutorials"),
        get = function(_self, player, ctx)
            if not ctx[pagename] then
                ctx[pagename] = { inside_sway = true }
            end
            return sway.Form {
                teacher.gui_list_all:embed {
                    player = player,
                    name = pagename
                }
            }
        end
    })
end
