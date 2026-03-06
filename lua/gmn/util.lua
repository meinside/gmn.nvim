-- lua/gmn/util.lua
--
-- Utility functions module
--
-- last update: 2026.03.06.

local M = {}

-- splits a string with delimiters
--
-- https://stackoverflow.com/questions/19262761/lua-need-to-split-at-comma
function M.split(source, delimiters)
	local elements = {}
	local pattern = "([^" .. delimiters .. "]+)"
	_ = string.gsub(source, pattern, function(value)
		elements[#elements + 1] = value
	end)
	return elements
end

-- joins a string array with given delimiter
function M.join(strs, delim)
	return table.concat(strs, delim)
end

-- checks if str has given prefix
function M.has_prefix(str, prefix)
	return str:sub(1, #prefix) == prefix
end

-- sub-slices given array
function M.subslice(array, start_index, end_index)
	local sub_array = {}
	for i = start_index, end_index do
		sub_array[#sub_array + 1] = array[i]
	end
	return sub_array
end

-- split each line with '\n'
function M.split_lines(original)
	local lines = {}
	for _, text in ipairs(original) do
		for _, line in ipairs(vim.split(text, "\n", { plain = true })) do
			table.insert(lines, line)
		end
	end
	return lines
end

-- if the second line is not empty, insert one
function M.insert_empty_line_after_first(lines)
	if #lines >= 2 and lines[2] ~= "" then
		table.insert(lines, 2, "")
	end
	return lines
end

-- strips outermost codeblock markdown off from given string
function M.strip_outermost_codeblock(str)
	local lines = M.split(str, "\n")
	if #lines >= 2 and M.has_prefix(lines[1], "```") and lines[#lines] == "```" then
		return M.join(M.subslice(lines, 2, #lines - 1), "\n")
	end
	return str
end

-- executes shell command and returns its output
function M.execute_command(command)
	local output = vim.fn.system(command)
	return output
end

return M
