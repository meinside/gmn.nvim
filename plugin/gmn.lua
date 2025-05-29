-- plugin/gmn.lua
--
-- Gemini plugin for neovim
--
-- last update: 2025.05.29.

local cmdGenerateText = "GeminiGenerate"
local cmdGenerateGitCommitLog = "GeminiGenerateGitCommitLog"

local gmn = require("gmn")
local config = require("gmn/config")
local ui = require("gmn/ui")
local util = require("gmn/util")

local function error(msg)
	vim.notify(msg, vim.log.levels.ERROR)
end

local function warn(msg)
	vim.notify(msg, vim.log.levels.WARN)
end

local function debug(msg)
	if config.options.verbose then
		vim.notify(msg, vim.log.levels.INFO)
	end
end

-- :GeminiGenerate [prompt]
--   generate content from the given prompt
--
-- :'<,'>GeminiGenerate
--   replace selected range with generated content from the selected range as a prompt
--
-- :'<,'>GeminiGenerate [prompt]
--   replace selected range with generated content from the given prompt
--
vim.api.nvim_create_user_command(cmdGenerateText, function(opts)
	debug(string.format("opts of `:%s`: %s", cmdGenerateText, vim.inspect(opts)))

	-- generate texts with given prompt,
	if opts.range == 0 then -- if there was no selected range,
		if #opts.fargs > 0 then
			debug(string.format("using command parameter as a prompt: %s", opts.fargs[1]))

			-- do the generation
			local parts, err = gmn.generate_text({ opts.fargs[1] })
			if err ~= nil then
				error(string.format("Error: %s", err))
			else
				-- strip outermost codeblock
				if config.options.stripOutermostCodeblock() then
					for i, _ in ipairs(parts) do
						parts[i] = util.strip_outermost_codeblock(parts[i])
					end
				end

				-- split lines
				local lines = util.split_lines(parts)

				-- and insert the generated content
				ui.insert_text_at_current_cursor(lines)
			end
		else
			warn("No prompt was given.")
		end
	else -- if there was some selected range,
		local start_row, start_col, end_row, end_col = ui.get_selection()
		local selected = ui.get_text(start_row, start_col, end_row, end_col)

		local prompts = {}
		if selected ~= nil then
			debug(string.format("using selected range as a prompt: %s", selected))

			table.insert(prompts, selected)
		end
		if #opts.fargs > 0 then
			debug(string.format("using command parameter as a prompt: %s", opts.fargs[1]))

			table.insert(prompts, opts.fargs[1])
		end

		-- do the generation
		local parts, err = gmn.generate_text(prompts)
		if err ~= nil then
			error(err)
		else
			-- strip outermost codeblock
			if config.options.stripOutermostCodeblock() then
				for i, _ in ipairs(parts) do
					parts[i] = util.strip_outermost_codeblock(parts[i])
				end
			end

			-- split lines
			local lines = util.split_lines(parts)

			-- and replace the selected range with generated content
			ui.replace_text(start_row, start_col, end_row, end_col, lines)
		end
	end
end, { range = true, nargs = "?" })

-- :GeminiGenerateGitCommitLog
--   generate a git commit log from the result of command: `git diff HEAD`
--
-- :'<,'>GeminiGenerateGitCommitLog
--   replace selected range with generated git commit log from the selected range as a prompt
--
vim.api.nvim_create_user_command(cmdGenerateGitCommitLog, function(opts)
	debug(string.format("opts of `:%s`: %s", cmdGenerateGitCommitLog, vim.inspect(opts)))

	local promptPrefix = [====[
Generate an excellent git commit message using the following code changes,
adhering to the conventional commits v1.0.0 specification.
Ensure that there is no code block surrounding your response,
that there is a blank line between the header and the body,
and that each line of body is no longer than approximately 80 bytes:


]====]

	-- generate texts with given prompt,
	if opts.range == 0 then -- if there was no selected range,
		local text = util.execute_command("git diff HEAD")
		local prompts = { promptPrefix .. text }

		debug(string.format("using prompt: %s", prompts[1]))

		-- do the generation
		local parts, err = gmn.generate_text(prompts)
		if err ~= nil then
			error(err)
		else
			-- split lines
			local lines = util.split_lines(parts)

			-- FIXME: generated lines have no empty line between the first and the next one
			lines = util.insert_empty_line_after_first(lines)

			-- and replace whole file with the generated content
			ui.replace_whole_text(lines)
		end
	else -- if there was some selected range,
		local start_row, start_col, end_row, end_col = ui.get_selection()
		local selected = ui.get_text(start_row, start_col, end_row, end_col)

		local prompts = {}
		if selected ~= nil then
			debug(string.format("using selected range as a prompt: %s", selected))

			table.insert(prompts, promptPrefix .. selected)
		end
		if #opts.fargs > 0 then
			debug(string.format("using command parameter as a prompt: %s", opts.fargs[1]))

			table.insert(prompts, promptPrefix .. opts.fargs[1])
		end

		-- do the generation
		local parts, err = gmn.generate_text(prompts)
		if err ~= nil then
			error(string.format("Error: %s", err))
		else
			-- split lines
			local lines = util.split_lines(parts)

			-- FIXME: generated lines have no empty line between the first and the next one
			lines = util.insert_empty_line_after_first(lines)

			-- merge generated contents and replace the selected range with it
			ui.replace_text(start_row, start_col, end_row, end_col, lines)
		end
	end
end, { range = true })
