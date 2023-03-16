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
}

CommandsList.CallbackTypes = {
    ["text_popup"] = (function(lines)
        Ui.popup(lines, "text")
    end),
    ["code_popup"] = (function(lines)
        Ui.popup(lines, Utils.get_filetype())
    end),
    ["replace_lines"] = (function(lines)
        Utils.replace_lines(lines)
    end),
    ["custom"] = nil,
}

function CommandsList.get_cmd_opts(cmd)
    local opts = vim.g["codegpt_commands_defaults"][cmd]
    local user_set_opts = {}

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
            user_set_opts.language_instructions = vim.tbl_extend("force", opts.language_instructions, user_set_opts.language_instructions)
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
