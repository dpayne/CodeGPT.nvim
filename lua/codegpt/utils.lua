Utils = {}

function Utils.get_filetype()
  local bufnr = vim.api.nvim_get_current_buf()
  return vim.api.nvim_buf_get_option(bufnr, "filetype")
end

function Utils.get_visual_selection()
  local bufnr = vim.api.nvim_get_current_buf()

  local start_pos = vim.api.nvim_buf_get_mark(bufnr, "<")
  local end_pos = vim.api.nvim_buf_get_mark(bufnr, ">")

  if start_pos[1] == end_pos[1] and start_pos[2] == end_pos[2] then
    return 0, 0, 0, 0
  end

  local start_row = start_pos[1] - 1
  local start_col = start_pos[2]

  local end_row = end_pos[1] - 1
  local end_col = end_pos[2] + 1

  if vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, true)[1] == nil then
    return 0, 0, 0, 0
  end

  local start_line_length = vim.api.nvim_buf_get_lines(bufnr, start_row, start_row + 1, true)[1]:len()
  start_col = math.min(start_col, start_line_length)

  local end_line_length = vim.api.nvim_buf_get_lines(bufnr, end_row, end_row + 1, true)[1]:len()
  end_col = math.min(end_col, end_line_length)

  return start_row, start_col, end_row, end_col
end

function Utils.get_selected_lines()
  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = Utils.get_visual_selection()
  local lines = vim.api.nvim_buf_get_text(bufnr, start_row, start_col, end_row, end_col, {})
  return table.concat(lines, "\n")
end

function Utils.insert_lines(lines)
  local bufnr = vim.api.nvim_get_current_buf()
  local line = vim.api.nvim_win_get_cursor(0)[1]
  vim.api.nvim_buf_set_lines(bufnr, line, line, false, lines)
  vim.api.nvim_win_set_cursor(0, { line + #lines, 0 })
end

function Utils.replace_lines(lines)
  local bufnr = vim.api.nvim_get_current_buf()
  local start_row, start_col, end_row, end_col = Utils.get_visual_selection()
  vim.api.nvim_buf_set_text(bufnr, start_row, start_col, end_row, end_col, lines)
end

return Utils
