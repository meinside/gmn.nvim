-- lua/gmn/generation.lua
--
-- Generation module
--
-- last update: 2025.05.29.

-- external dependencies
local curl = require("plenary/curl")

-- plugin modules
local fs = require("gmn/fs")
local config = require("gmn/config")

-- constants
local contentType = "application/json"
local baseurl = "https://generativelanguage.googleapis.com"

-- generate a request url
local function request_url(endpoint, apiKey)
	return baseurl .. endpoint .. "?key=" .. apiKey
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
-- https://ai.google.dev/docs/safety_setting_gemini
local function safety_settings(threshold)
	return {
		{ category = "HARM_CATEGORY_HARASSMENT", threshold = threshold },
		{ category = "HARM_CATEGORY_HATE_SPEECH", threshold = threshold },
		{ category = "HARM_CATEGORY_SEXUALLY_EXPLICIT", threshold = threshold },
		{ category = "HARM_CATEGORY_DANGEROUS_CONTENT", threshold = threshold },
		{ category = "HARM_CATEGORY_CIVIC_INTEGRITY", threshold = threshold },
	}
end

-- request text generation with given prompts
--
-- https://ai.google.dev/tutorials/rest_quickstart#text-only_input
function M.text(prompts)
	local apiKey, err = fs.read_api_key()
	if err ~= nil then
		return nil, err
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

	if config.options.verbose then
		vim.notify("Sending request to: " .. endpoint, vim.log.levels.DEBUG)
	else
		vim.notify("Generating...", vim.log.levels.INFO)
	end

	-- send request,
	local res = curl.post(request_url(endpoint, apiKey), {
		headers = {
			["Content-Type"] = contentType,
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
