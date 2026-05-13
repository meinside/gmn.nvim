-- lua/gmn/util.lua
--
-- Utility functions module
--
-- last update: 2026.03.06.

local M = {}

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
	local lines = vim.split(str, "\n", { plain = true })
	if #lines >= 2 and vim.startswith(lines[1], "```") and lines[#lines] == "```" then
		return table.concat(vim.list_slice(lines, 2, #lines - 1), "\n")
	end
	return str
end

-- executes shell command and returns its output
function M.execute_command(command)
	local output = vim.fn.system(command)
	return output
end

-- returns the directory of the current buffer (for use as a git working dir).
-- falls back to the current working directory if the buffer has no name.
function M.current_buffer_dir()
	local name = vim.api.nvim_buf_get_name(0)
	if name == nil or name == "" then
		return vim.fn.getcwd()
	end
	return vim.fn.fnamemodify(name, ":h")
end

-- resolves the worktree root for the given starting directory.
-- handles the case where the buffer lives inside the .git directory itself
-- (e.g. COMMIT_EDITMSG): running `git -C .git/...` puts git into a bare-repo
-- mode where output (warnings, diff prefixes) becomes inconsistent.
-- returns nil if `dir` isn't inside any git repository.
function M.git_worktree_root(dir)
	local result = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })
	if vim.v.shell_error == 0 and #result > 0 then
		return result[1]
	end

	-- maybe inside .git/. ask git for the .git dir, then take its parent.
	-- the result may be relative to `dir`; resolve it accordingly.
	result = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--git-common-dir" })
	if vim.v.shell_error ~= 0 or #result == 0 then
		return nil
	end
	local git_dir = result[1]
	if git_dir:sub(1, 1) ~= "/" then
		git_dir = dir .. "/" .. git_dir
	end
	-- normalize and strip the trailing /.git component
	git_dir = vim.fn.fnamemodify(git_dir, ":p"):gsub("/+$", "")
	return vim.fn.fnamemodify(git_dir, ":h")
end

return M
