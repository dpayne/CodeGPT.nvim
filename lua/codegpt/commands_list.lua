local Utils = require("codegpt.utils")
local Ui = require("codegpt.ui")

local CommandsList = {}
local cmd_default = {
    model = "gpt-3.5-turbo",
    max_tokens = 4096,
    temperature = 0.8,
    number_of_choices = 1,
    system_message_template = "You are a {{language}} coding assistant.",
    user_message_template = "",
    callback_type = "replace_lines",
    allow_empty_text_selection = false,
    extra_params = {}, -- extra parameters sent to the API

    -- Newer models have longer limit for input tokens and shorter limit for output tokens
    -- Use this value for output tokens limit, and `max_tokens` for input tokens limit
    max_output_tokens = nil,
}

CommandsList.CallbackTypes = {
    ["text_popup"] = function(lines, bufnr, start_row, start_col, end_row, end_col)
        local popup_filetype = vim.g["codegpt_text_popup_filetype"]
        Ui.popup(lines, popup_filetype, bufnr, start_row, start_col, end_row, end_col)
    end,
    ["code_popup"] = function(lines, bufnr, start_row, start_col, end_row, end_col)
        lines = Utils.trim_to_code_block(lines)
        Utils.fix_indentation(bufnr, start_row, end_row, lines)
        Ui.popup(lines, Utils.get_filetype(), bufnr, start_row, start_col, end_row, end_col)
    end,
    ["replace_lines"] = function(lines, bufnr, start_row, start_col, end_row, end_col)
        lines = Utils.trim_to_code_block(lines)
        lines = Utils.remove_trailing_whitespace(lines)
        Utils.fix_indentation(bufnr, start_row, end_row, lines)
        if vim.api.nvim_buf_is_valid(bufnr) == true then
            Utils.replace_lines(lines, bufnr, start_row, start_col, end_row, end_col)
        else
            -- if the buffer is not valid, open a popup. This can happen when the user closes the previous popup window before the request is finished.
            Ui.popup(lines, Utils.get_filetype(), bufnr, start_row, start_col, end_row, end_col)
        end
    end,
    ["custom"] = nil,
}

function CommandsList.get_cmd_opts(cmd)
    local opts = vim.g["codegpt_commands_defaults"][cmd]
    local user_set_opts = {}

    if vim.g["codegpt_global_commands_defaults"] ~= nil then
        cmd_default = vim.tbl_extend("force", cmd_default, vim.g["codegpt_global_commands_defaults"])
    end

    if vim.g["codegpt_commands"] ~= nil then
        user_set_opts = vim.g["codegpt_commands"][cmd]
    end

    if opts == nil and user_set_opts == nil then
        return nil
    elseif opts == nil then
        opts = {}
    elseif user_set_opts == nil then
        user_set_opts = {}
    elseif opts ~= nil and user_set_opts ~= nil then
        -- merge language_instructions
        if opts.language_instructions ~= nil and user_set_opts.language_instructions ~= nil then
            user_set_opts.language_instructions =
                vim.tbl_extend("force", opts.language_instructions, user_set_opts.language_instructions)
        end
    end

    opts = vim.tbl_extend("force", opts, user_set_opts)
    opts = vim.tbl_extend("force", cmd_default, opts)

    if opts.callback_type == "custom" then
        opts.callback = user_set_opts.callback
    else
        opts.callback = CommandsList.CallbackTypes[opts.callback_type]
    end

    return opts
end

return CommandsList
