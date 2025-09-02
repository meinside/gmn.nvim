-- lua/gmn/generation.lua
--
-- Generation module
--
-- last update: 2025.09.02.

-- external dependencies
local curl = require("plenary/curl")

-- plugin modules
local fs = require("gmn/fs")
local config = require("gmn/config")

-- constants
local contentType = "application/json"
local baseUrl = "https://generativelanguage.googleapis.com"

-- generate a request url
local function request_url(endpoint)
	return baseUrl .. endpoint
end

local M = {}

-- generate system instruction
local function system_instruction(model)
	return string.format(
		[====[
You are a neovim plugin named `gmn.nvim` developed for generating various kinds of media,
using Google Gemini API(model: %s).

Current datetime is %s.

Respond to user messages according to the following principles:
- Do not repeat the user's request and return only the response to the user's request.
- Unless otherwise specified, respond in the same language as used in the user's request.
- Be as accurate as possible.
- Be as truthful as possible.
- Be as comprehensive and informative as possible.
]====],
		model,
		os.date("%Y-%m-%d %H:%M:%S", os.time())
	)
end

-- generate safety settings with given threshold
--
-- https://ai.google.dev/gemini-api/docs/safety-settings
local function safety_settings(threshold)
	return {
		{ category = "HARM_CATEGORY_HARASSMENT", threshold = threshold },
		{ category = "HARM_CATEGORY_HATE_SPEECH", threshold = threshold },
		{ category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = threshold },
		{ category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = threshold },
		--{ category = "HARM_CATEGORY_CIVIC_INTEGRITY", threshold = threshold }, -- FIXME: http 500 errors occur with this
	}
end

-- Requests text generation with given prompts.
--
-- @params prompts A list of prompt strings.
-- @params opts An optional table of options.
-- @returns A table of response and error message.
--
-- opts is a table with the following keys:
-- - fetch_urls: A boolean indicating whether to fetch contents from URLs or not.
-- - web_search: A boolean indicating whether to use web search or not.
-- - thinking: A boolean indicating whether to use reasoning or not.
--
-- https://ai.google.dev/gemini-api/docs/quickstart?lang=rest#make-first-request
function M.text(prompts, opts)
	opts = opts or {}

	if config.options.verbose then
		vim.notify("Generating with opts: " .. vim.inspect(opts), vim.log.levels.DEBUG)
	end

	-- read `api_key`
	local api_key, err = config.read_api_key_env() -- from env variables
	if err ~= nil then
		api_key, err = fs.read_api_key_file(config.options.configFilepath) -- or from config file
		if err ~= nil then
			return nil, err
		end
	end

	local endpoint = "/v1beta/models/" .. config.options.model .. ":generateContent"
	local params = {
		-- system instruction
		systemInstruction = {
			role = "model",
			parts = {
				{ text = system_instruction(config.options.model) },
			},
		},

		-- contents
		contents = { { role = "user", parts = {} } },

		-- safety settings
		safetySettings = safety_settings(config.options.safetyThreshold),
	}
	-- append prompts to contents
	for i, _ in ipairs(prompts) do
		params.contents[1].parts[i] = { text = prompts[i] }
	end

	-- tools
	local tools = {}
	-- https://ai.google.dev/gemini-api/docs/url-context#rest
	local fetch_urls = opts.fetch_urls or false
	if fetch_urls then
		table.insert(tools, { url_context = vim.empty_dict() })
	end
	-- https://ai.google.dev/gemini-api/docs/google-search#rest
	local web_search = opts.web_search or false
	if web_search then
		table.insert(tools, { google_search = vim.empty_dict() })
	end
	if #tools > 0 then
		params.tools = tools
	end

	-- generation config
	local generation_config = {}
	-- https://ai.google.dev/gemini-api/docs/thinking#rest_1
	local thinking = opts.thinking or false
	if thinking then
		generation_config.thinkingConfig = {
			thinkingBudget = -1, -- dynamic thinking
		}
	end
	if next(generation_config) ~= nil then
		params.generationConfig = generation_config
	end

	if config.options.verbose then
		vim.notify("Sending request to: " .. endpoint, vim.log.levels.DEBUG)
	else
		vim.notify("Generating...", vim.log.levels.INFO)
	end

	-- send request,
	local res = curl.post(request_url(endpoint), {
		headers = {
			["Content-Type"] = contentType,
			["x-goog-api-key"] = api_key,
		},
		raw_body = vim.json.encode(params),
		timeout = config.options.timeout,
	})

	-- check response,
	if res.status == 200 and res.exit == 0 then
		if config.options.verbose then
			vim.notify("Generated " .. string.len(res.body) .. " bytes.", vim.log.levels.DEBUG)
		else
			vim.notify("Generation finished.", vim.log.levels.INFO)
		end

		res = vim.json.decode(res.body)
	else
		if config.options.verbose then
			vim.notify(vim.inspect(res), vim.log.levels.DEBUG)
		else
			vim.notify("Generation failed.", vim.log.levels.ERROR)
		end

		err = string.format("request failed; http %s; curl exit %s;", res.status, res.exit)
	end

	return res, err
end

return M
