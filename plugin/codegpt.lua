-- add public vim commands
require("codegpt.config")
vim.api.nvim_create_user_command("Chat", function(opts)
	require("codegpt").run_cmd(opts)
end, {
	range = true,
	nargs = "*",
})
