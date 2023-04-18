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

  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = Utils.get_visual_selection()

  local ns_id = vim.api.nvim_create_namespace("CodeGPT")
  local extmark_opts = {
      sign_text = vim.g['codegpt_processing_sign']
  }
  local mark_id = vim.api.nvim_buf_set_extmark(bufnr, ns_id, start_row, start_col, extmark_opts)
  local new_callback = function(lines)
    vim.api.nvim_buf_del_extmark(bufnr, ns_id, mark_id)
    cmd_opts.callback(lines, bufnr, start_row, start_col, end_row, end_col)
  end
  OpenAiApi.make_call(request, new_callback)
end

function Commands.get_status(...)
	return OpenAiApi.get_status(...)
end

return Commands
