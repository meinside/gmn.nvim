-- tests/ui_spec.lua

local h = require("tests.helpers")
local ui = require("gmn.ui")

local function set_buf(lines)
	vim.cmd("enew!")
	vim.api.nvim_buf_set_lines(0, 0, -1, false, lines)
end

local function buf_lines()
	return vim.api.nvim_buf_get_lines(0, 0, -1, false)
end

local M = {}

function M.replace_whole_text_replaces_everything()
	set_buf({ "old1", "old2", "old3" })
	ui.replace_whole_text({ "new1", "new2" })
	h.eq(buf_lines(), { "new1", "new2" })
end

-- regression: COMMIT_EDITMSG buffers contain git's helper comments below
-- the message. Generating a commit log used to wipe those out via
-- replace_whole_text. The replacement must keep them intact.
function M.replace_message_keeps_git_comments_below()
	set_buf({
		"old subject",
		"",
		"old body",
		"",
		"# Please enter the commit message for your changes.",
		"# Lines starting with '#' will be ignored.",
		"#",
		"# On branch develop",
	})
	ui.replace_message_preserving_comments({ "new subject", "", "new body" })
	h.eq(buf_lines(), {
		"new subject",
		"",
		"new body",
		"# Please enter the commit message for your changes.",
		"# Lines starting with '#' will be ignored.",
		"#",
		"# On branch develop",
	})
end

function M.replace_message_with_no_comments_replaces_whole()
	set_buf({ "old1", "old2" })
	ui.replace_message_preserving_comments({ "new1" })
	h.eq(buf_lines(), { "new1" })
end

function M.replace_message_with_only_comments_keeps_them()
	set_buf({
		"# comment 1",
		"# comment 2",
	})
	ui.replace_message_preserving_comments({ "subject" })
	h.eq(buf_lines(), { "subject", "# comment 1", "# comment 2" })
end

return M
