-- tests/util_spec.lua

local h = require("tests.helpers")
local util = require("gmn.util")

local M = {}

-- regression: blank lines inside fenced code blocks were lost when stripping
-- the outermost fence (the old util.split used "+" pattern which dropped them).
function M.strip_codeblock_preserves_blank_lines()
	local got = util.strip_outermost_codeblock("```lua\nlocal a = 1\n\nlocal b = 2\n```")
	h.eq(got, "local a = 1\n\nlocal b = 2")
end

function M.strip_codeblock_with_language_tag()
	local got = util.strip_outermost_codeblock("```python\nprint(1)\n```")
	h.eq(got, "print(1)")
end

function M.strip_codeblock_no_fence_returns_input()
	h.eq(util.strip_outermost_codeblock("plain text"), "plain text")
end

function M.strip_codeblock_unmatched_open_returns_input()
	-- starts with ``` but no closing fence → must not strip anything.
	local input = "```\nstill open"
	h.eq(util.strip_outermost_codeblock(input), input)
end

function M.strip_codeblock_empty_body()
	h.eq(util.strip_outermost_codeblock("```\n```"), "")
end

function M.split_lines_flattens_multi_line_strings()
	h.eq(util.split_lines({ "a\nb", "c" }), { "a", "b", "c" })
end

function M.split_lines_preserves_blank_lines()
	h.eq(util.split_lines({ "a\n\nb" }), { "a", "", "b" })
end

function M.split_lines_empty_input()
	h.eq(util.split_lines({}), {})
end

function M.insert_empty_line_when_second_line_nonempty()
	h.eq(util.insert_empty_line_after_first({ "title", "body" }), { "title", "", "body" })
end

function M.insert_empty_line_no_op_when_already_empty()
	h.eq(util.insert_empty_line_after_first({ "title", "", "body" }), { "title", "", "body" })
end

function M.insert_empty_line_no_op_with_single_line()
	h.eq(util.insert_empty_line_after_first({ "only" }), { "only" })
end

function M.current_buffer_dir_uses_buffer_path()
	-- nvim resolves edit paths through realpath on macOS (/tmp -> /private/tmp),
	-- so don't compare with a hardcoded literal — derive the expected value the
	-- same way the function does, from the buffer's reported name.
	vim.cmd("edit /tmp/gmn_test_file.txt")
	local expected = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(0), ":h")
	h.eq(util.current_buffer_dir(), expected)
end

function M.current_buffer_dir_falls_back_to_cwd_for_unnamed()
	vim.cmd("enew") -- unnamed scratch buffer
	h.eq(util.current_buffer_dir(), vim.fn.getcwd())
end

return M
