local Commands = require("codegpt.commands")
local CommandsList = require("codegpt.commands_list")
local Utils = require("codegpt.utils")
local CodeGptModule = {}

CodeGptModule.loading_state = {}

function CodeGptModule.status()
	if next(CodeGptModule.loading_state) == nil then
		return vim.g["codegpt_state_ready_string"]
	else
		return vim.g["codegpt_state_loading_string"]
	end
end

function CodeGptModule.run_cmd(opts)
	local text_selection = Utils.get_selected_lines()
	local command_args = table.concat(opts.fargs, " ")

	local command = ""

	if text_selection ~= "" and command_args ~= "" then
		if 1 == #opts.fargs and CommandsList.get_cmd_opts(opts.fargs[1]) ~= nil then
			command = opts.fargs[1]
			command_args = ""
		else
			command = "code_edit"
		end
	elseif text_selection ~= "" and command_args == "" then
		command = "completion"
	elseif text_selection == "" and command_args ~= "" then
		command = "chat"
	end

	if command == nil or command == "" then
		error("Command not found")
	end

	local cmd_opts = CommandsList.get_cmd_opts(command)
	if cmd_opts == nil then
		error("Command not found")
	end

	Commands.run_cmd(command, command_args, text_selection)
end

return CodeGptModule
