-- lua/gmn/ui.lua
--
-- UI module
--
-- last update: 2026.03.06.

local M = {}

-- get selected range from visual block
function M.get_selection()
	local start_row, start_col = unpack(vim.api.nvim_buf_get_mark(0, "<"))
	local end_row, end_col = unpack(vim.api.nvim_buf_get_mark(0, ">"))

	-- NOTE: normalize the end column if it's set to v:maxcol
	if end_col == vim.v.maxcol then
		local line = vim.api.nvim_buf_get_lines(0, end_row - 1, end_row, false)[1]
		end_col = #line
	end

	return start_row, start_col, end_row, end_col
end

-- get text from range
function M.get_text(start_row, start_col, end_row, end_col)
	if start_row == end_row then
		return vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)[1]:sub(start_col, end_col)
	else
		local lines = vim.api.nvim_buf_get_lines(0, start_row - 1, end_row, false)
		lines[1] = lines[1]:sub(start_col)
		lines[#lines] = lines[#lines]:sub(1, end_col)
		return table.concat(lines, "\n")
	end
end

-- clear and replace text at given range
function M.replace_text(start_row, start_col, end_row, end_col, lines)
	vim.api.nvim_buf_set_text(0, start_row - 1, start_col, end_row - 1, end_col, lines)
end

-- clear and replace whole text
function M.replace_whole_text(lines)
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

-- replace only the message portion of a buffer that has git-style comment
-- lines (lines beginning with '#'), leaving the comment block intact.
-- if no comment lines exist, falls back to replacing the whole buffer.
function M.replace_message_preserving_comments(lines)
	local existing = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local first_comment = nil
	for i, line in ipairs(existing) do
		if line:sub(1, 1) == "#" then
			first_comment = i
			break
		end
	end
	if first_comment == nil then
		M.replace_whole_text(lines)
		return
	end
	-- replace [0 .. first_comment-1) with the new message; keep the rest.
	vim.api.nvim_buf_set_lines(0, 0, first_comment - 1, false, lines)
end

-- insert given text at current cursor position
function M.insert_text_at_current_cursor(lines)
	local row, col = unpack(vim.api.nvim_win_get_cursor(0))
	vim.api.nvim_buf_set_text(0, row - 1, col, row - 1, col, lines)
end

return M
