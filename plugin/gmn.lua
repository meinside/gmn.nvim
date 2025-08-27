-- plugin/gmn.lua
--
-- Gemini plugin for neovim
--
-- last update: 2025.08.27.

local cmdGenerateText = "GeminiGenerate"
local cmdGenerateTextWithSearch = "GeminiGenerateWithSearch"
local cmdGenerateTextWithURLFetch = "GeminiGenerateWithURLFetch"
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

-- generate texts with given parameters
local function generate(cmd_opts, gen_opts)
	gen_opts = gen_opts or {}

	if cmd_opts.range == 0 then -- if there was no selected range,
		if #cmd_opts.fargs > 0 then
			debug(string.format("using command parameter as a prompt: %s", cmd_opts.fargs[1]))

			-- do the generation
			local parts, err = gmn.generate_text({ cmd_opts.fargs[1] }, gen_opts)
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
		if #cmd_opts.fargs > 0 then
			debug(string.format("using command parameter as a prompt: %s", cmd_opts.fargs[1]))

			table.insert(prompts, cmd_opts.fargs[1])
		end

		-- do the generation
		local parts, err = gmn.generate_text(prompts, gen_opts)
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
end

-- :GeminiGenerate [prompt]
--   generate content from the given `prompt`
--
-- :'<,'>GeminiGenerate
--   replace selected range with the generated content (generated from the selected range as a prompt)
--
-- :'<,'>GeminiGenerate [prompt]
--   replace selected range with the generated content (generated from the given `prompt`)
--
vim.api.nvim_create_user_command(cmdGenerateText, function(opts)
	debug(string.format("opts of `:%s`: %s", cmdGenerateText, vim.inspect(opts)))

	generate(opts, {
		thinking = true,
	})
end, { range = true, nargs = "?" })

-- :GeminiGenerateWithSearch [prompt]
--   generate content from the given `prompt` and google search
--
-- :'<,'>GeminiGenerateWithSearch
--   replace selected range with the generated content (generated from the selected range as a prompt and google search)
--
-- :'<,'>GeminiGenerateWithSearch [prompt]
--   replace selected range with the generated content (generated from the given `prompt` and google search)
--
vim.api.nvim_create_user_command(cmdGenerateTextWithSearch, function(opts)
	debug(string.format("opts of `:%s`: %s", cmdGenerateTextWithSearch, vim.inspect(opts)))

	generate(opts, {
		thinking = true,
		web_search = true,
	})
end, { range = true, nargs = "?" })

-- :GeminiGenerateWithURLFetch [prompt]
--   generate content from the given `prompt` and the contents of URLs in the prompt
--
-- :'<,'>GeminiGenerateWithSearch
--   replace selected range with the generated content (generated from the selected range as a prompt and the contents of URLs in the prompt)
--
-- :'<,'>GeminiGenerateWithSearch [prompt]
--   replace selected range with the generated content (generated from the given `prompt` and the contents of URLs in the prompt)
--
vim.api.nvim_create_user_command(cmdGenerateTextWithURLFetch, function(opts)
	debug(string.format("opts of `:%s`: %s", cmdGenerateTextWithURLFetch, vim.inspect(opts)))

	generate(opts, {
		thinking = true,
		fetch_urls = true,
	})
end, { range = true, nargs = "?" })

-- :GeminiGenerateGitCommitLog
--   generate a git commit log from the result of command: `git diff HEAD`
--
-- :'<,'>GeminiGenerateGitCommitLog
--   replace selected range with the generated git commit log (generated from the selected range as a prompt)
--
vim.api.nvim_create_user_command(cmdGenerateGitCommitLog, function(opts)
	debug(string.format("opts of `:%s`: %s", cmdGenerateGitCommitLog, vim.inspect(opts)))

	-- referenced:
	-- https://www.reddit.com/r/ClaudeAI/comments/1l82cud/a_useful_prompt_for_commit_message_generation/
	local promptPrefix = [====[
Your task is to help the user to generate an excellent git commit message
with the following guidelines, adhering to the conventional commits v1.0.0 specification:

# Guidelines

## Format of Title

```
<type>:<space><message title>
```

## Example of Titles

```
feat(auth): Add JWT login flow
fix(ui): Handle null pointer in sidebar
refactor(api): Split user controller logic
docs(readme): Add usage section
```

## Format of Title & Body

```
<type>:<space><message title>

<bullet points summarizing what was updated>
```

## Example of Title & Body

```
feat(tools): Add support for MCP servers

- Implemented MCP server connection
  - Added support for servers with streamable URLs
	- Added support for stdio servers
- Added documentation for the changes
```

## Rules

* Message title starts with uppercase, no period at the end.
* Message title should be a clear summary, max 50 characters.
* Use the body (optional) to explain *why*, not just *what*.
  * Bullet points should be concise and high-level.
  * Each line of body should be max 80 characters.
* Make sure to insert an empty line between the message title and the following body.

Avoid:

* Vague titles like: "update", "fix stuff"
* Overly long or unfocused titles
* Excessive detail in bullet points
* Wrapping your response with any markdown or markup characters, eg. codeblock

## Allowed Types

| Type     | Description                           |
| -------- | ------------------------------------- |
| feat     | New feature                           |
| fix      | Bug fix                               |
| chore    | Maintenance (e.g., tooling, deps)     |
| docs     | Documentation changes                 |
| refactor | Code restructure (no behavior change) |
| test     | Adding or refactoring tests           |
| style    | Code formatting (no logic change)     |
| perf     | Performance improvements              |

---
Here is the git diff result:


]====]

	-- generate texts with given prompt,
	if opts.range == 0 then -- if there was no selected range,
		local text = util.execute_command("git diff HEAD")
		local prompts = { promptPrefix .. text }

		debug(string.format("using prompt: %s", prompts[1]))

		-- do the generation
		local parts, err = gmn.generate_text(prompts, { thinking = true })
		if err ~= nil then
			error(err)
		else
			-- split lines
			local lines = util.split_lines(parts)

			-- FIXME: it is hard to insert an empty line between the title and the body, only with the prompt
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
		local parts, err = gmn.generate_text(prompts, { thinking = true })
		if err ~= nil then
			error(string.format("Error: %s", err))
		else
			-- split lines
			local lines = util.split_lines(parts)

			-- FIXME: it is hard to insert an empty line between the title and the body, only with the prompt
			lines = util.insert_empty_line_after_first(lines)

			-- merge generated contents and replace the selected range with it
			ui.replace_text(start_row, start_col, end_row, end_col, lines)
		end
	end
end, { range = true })
