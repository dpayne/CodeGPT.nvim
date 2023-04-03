local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

local Ui = {}

local popup

function Ui.popup(lines, filetype, bufnr, start_row, start_col, end_row, end_col)
	if not popup then
		popup = Popup({
			enter = true,
			focusable = true,
			border = vim.g["codegpt_popup_border"],
			position = "50%",
			size = {
				width = "80%",
				height = "60%",
			},
			win_options = {
				wrap = vim.g["codegpt_wrap_popup_text"],
			},
		})
	end

	popup:update_layout(vim.g["codegpt_popup_options"])

	-- mount/open the component
	popup:mount()

	-- unmount component when cursor leaves buffer
	popup:on(event.BufLeave, function()
		popup:unmount()
	end)

	-- unmount component when key 'q'
	popup:map("n", vim.g["codegpt_ui_commands"].quit, function()
		popup:unmount()
	end, { noremap = true, silent = true })

	-- set content
	vim.api.nvim_buf_set_option(popup.bufnr, "filetype", filetype)
	vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, lines)

	-- replace lines when ctrl-o pressed
	popup:map("n", vim.g["codegpt_ui_commands"].use_as_output, function()
		vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, lines)
		popup:unmount()
	end)

	-- selecting all the content when ctrl-i is pressed
	-- so the user can proceed with another API request
	popup:map("n", vim.g["codegpt_ui_commands"].use_as_input, function()
		vim.api.nvim_feedkeys("ggVG:Chat ", "n", false)
	end, { noremap = false })

	-- mapping custom commands
	for _, command in ipairs(vim.g.codegpt_ui_custom_commands) do
		popup:map(command[1], command[2], command[3], command[4])
	end
end

return Ui
