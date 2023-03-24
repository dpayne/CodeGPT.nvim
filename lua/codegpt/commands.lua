local OpenAiApi = require("codegpt.openai_api")
local CommandsList = require("codegpt.commands_list")
local Providers = require("codegpt.providers")

local Commands = {}

function Commands.run_cmd(command, command_args, text_selection)
	local cmd_opts = CommandsList.get_cmd_opts(command)
	if cmd_opts == nil then
		vim.notify("Command not found: " .. command, vim.log.levels.ERROR, {
			title = "CodeGPT",
		})
		return
	end

	local request = Providers.get_provider().make_request(command, cmd_opts, command_args, text_selection)

	OpenAiApi.make_call(request, cmd_opts.callback)
end

function Commands.get_status(...)
	return OpenAiApi.get_status(...)
end

return Commands
