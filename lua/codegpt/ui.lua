local Popup = require("nui.popup")
local Split = require("nui.split")
local event = require("nui.utils.autocmd").event

local Ui = {}

local popup
local split

local function setup_ui_element(lines, filetype, bufnr, start_row, start_col, end_row, end_col, ui_elem)
    -- mount/open the component
    ui_elem:mount()

    -- unmount component when cursor leaves buffer
    ui_elem:on(event.BufLeave, function()
        ui_elem:unmount()
    end)

    -- unmount component when key 'q'
    ui_elem:map("n", vim.g["codegpt_ui_commands"].quit, function()
        ui_elem:unmount()
    end, { noremap = true, silent = true })

    -- set content
    vim.api.nvim_buf_set_option(ui_elem.bufnr, "filetype", filetype)
    vim.api.nvim_buf_set_lines(ui_elem.bufnr, 0, 1, false, lines)

    -- replace lines when ctrl-o pressed
    ui_elem:map("n", vim.g["codegpt_ui_commands"].use_as_output, function()
        vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, lines)
        ui_elem:unmount()
    end)

    -- selecting all the content when ctrl-i is pressed
    -- so the user can proceed with another API request
    ui_elem:map("n", vim.g["codegpt_ui_commands"].use_as_input, function()
        vim.api.nvim_feedkeys("ggVG:Chat ", "n", false)
    end, { noremap = false })

    -- mapping custom commands
    for _, command in ipairs(vim.g.codegpt_ui_custom_commands) do
        ui_elem:map(command[1], command[2], command[3], command[4])
    end
end

local function create_horizontal()
    if not split then
        split = Split({
            relative = "editor",
            position = "bottom",
            size = vim.g["codegpt_horizontal_popup_size"],
        })
    end

    return split
end

local function create_vertical()
    if not split then
        split = Split({
            relative = "editor",
            position = "right",
            size = vim.g["codegpt_vertical_popup_size"],
        })
    end

    return split
end

local function create_popup()
    if not popup then
        local window_options = vim.g["codegpt_popup_window_options"]
        if window_options == nil then
            window_options = {}
        end

        -- check the old wrap config variable and use it if it's not set
        if window_options["wrap"] == nil then
            window_options["wrap"] = vim.g["codegpt_wrap_popup_text"]
        end

        popup = Popup({
            enter = true,
            focusable = true,
            border = vim.g["codegpt_popup_border"],
            position = "50%",
            size = {
                width = "80%",
                height = "60%",
            },
            win_options = window_options,
        })
    end

    popup:update_layout(vim.g["codegpt_popup_options"])

    return popup
end

function Ui.popup(lines, filetype, bufnr, start_row, start_col, end_row, end_col)
    local popup_type = vim.g["codegpt_popup_type"]
    local ui_elem = nil
    if popup_type == "horizontal" then
        ui_elem = create_horizontal()
    elseif popup_type == "vertical" then
        ui_elem = create_vertical()
    else
        ui_elem = create_popup()
    end
    setup_ui_element(lines, filetype, bufnr, start_row, start_col, end_row, end_col, ui_elem)
end

return Ui
