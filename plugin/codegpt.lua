-- add public vim commands
require("codegpt.config")
local CodeGptModule = require("codegpt")
vim.api.nvim_create_user_command("Chat", function(opts)
	return CodeGptModule.run_cmd(opts)
end, {
	range = true,
	nargs = "*",
})

vim.api.nvim_create_user_command("CodeGPTStatus", function(opts)
	return CodeGptModule.get_status(opts)
end, {
	range = true,
	nargs = "*",
})
