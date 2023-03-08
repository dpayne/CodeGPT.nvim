local Popup = require("nui.popup")
local event = require("nui.utils.autocmd").event

local Ui = {}

local popup = Popup({
  enter = true,
  focusable = true,
  border = {
    style = "rounded",
  },
  position = "50%",
  size = {
    width = "80%",
    height = "60%",
  },
  win_options = {
    wrap = true,
  },
})

function Ui.popup(lines, filetype)
  -- mount/open the component
  popup:mount()

  -- unmount component when cursor leaves buffer
  popup:on(event.BufLeave, function()
    popup:unmount()
  end)

  -- set content
  vim.api.nvim_buf_set_option(popup.bufnr, "filetype", filetype)
  vim.api.nvim_buf_set_lines(popup.bufnr, 0, 1, false, lines)
end

return Ui
