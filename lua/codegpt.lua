local Commands = require("codegpt.commands")
local CommandsList = require("codegpt.commands_list")
local Utils = require("codegpt.utils")
local CodeGptModule = {}

local function has_command_args(opts)
    local pattern = "%{%{command_args%}%}"
    return string.find(opts.user_message_template or "", pattern)
        or string.find(opts.system_message_template or "", pattern)
end

function CodeGptModule.get_status(...)
    return Commands.get_status(...)
end

function CodeGptModule.run_cmd(opts)
    local text_selection = Utils.get_selected_lines()
    local command_args = table.concat(opts.fargs, " ")

    local command = opts.fargs[1]

    if command_args ~= "" then
        local cmd_opts = CommandsList.get_cmd_opts(command)
        if cmd_opts ~= nil and has_command_args(cmd_opts) then
            if cmd_opts.allow_empty_text_selection == false and text_selection == "" then
                command = "chat"
            else
                command_args = table.concat(opts.fargs, " ", 2)
            end
        elseif cmd_opts and 1 == #opts.fargs then
            command_args = ""
        elseif text_selection == "" then
            command = "chat"
        else
            command = "code_edit"
        end
    elseif text_selection ~= "" and command_args == "" then
        command = "completion"
    end

    if command == nil or command == "" then
        vim.notify("No command or text selection provided", vim.log.levels.ERROR, {
            title = "CodeGPT",
        })
        return
    end

    Commands.run_cmd(command, command_args, text_selection)
end

return CodeGptModule
