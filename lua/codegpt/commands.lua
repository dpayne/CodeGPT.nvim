local CommandsList = require("codegpt.commands_list")
local Providers = require("codegpt.providers")
local Api = require("codegpt.api")

local Commands = {}

function Commands.run_cmd(command, command_args, text_selection)
	local cmd_opts = CommandsList.get_cmd_opts(command)
	if cmd_opts == nil then
		vim.notify("Command not found: " .. command, vim.log.levels.ERROR, {
			title = "CodeGPT",
		})
		return
	end

  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = Utils.get_visual_selection()
  local new_callback = function(lines)
    cmd_opts.callback(lines, bufnr, start_row, start_col, end_row, end_col)
  end

	local request = Providers.get_provider().make_request(command, cmd_opts, command_args, text_selection)
  Providers.get_provider().make_call(request, new_callback)
end

function Commands.get_status(...)
	return Api.get_status(...)
end

return Commands
