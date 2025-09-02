-- lua/gmn/config.lua
--
-- Configuration module
--
-- last update: 2025.09.02.

local M = {
	-- constants
	defaultConfigFilepath = "~/.config/gmn.nvim/config.json",
	defaultTimeoutMsecs = 30 * 1000,
	defaultModel = "gemini-2.5-flash",
	defaultSafetyThreshold = "BLOCK_ONLY_HIGH",
	defaultStripOutermostCodeblock = function()
		-- don't strip codeblock markdowns in markdown files
		return vim.bo.filetype ~= "markdown"
	end,
}

-- default configuration
M.options = {
	configFilepath = M.defaultConfigFilepath,
	timeout = M.defaultTimeoutMsecs,
	model = M.defaultModel,
	safetyThreshold = M.defaultSafetyThreshold,
	stripOutermostCodeblock = M.defaultStripOutermostCodeblock,

	verbose = false,
}

-- override configurations
function M.override(opts)
	opts = opts or {}

	M.options = vim.tbl_deep_extend("force", {}, M.options, opts)
end

local keyGeminiApiKey = "GEMINI_API_KEY"

-- read and return the `api_key` value from environment variable.
function M.read_api_key_env()
	local api_key = nil
	local err = nil

	-- read from environment variable,
	if vim.env.GEMINI_API_KEY ~= nil then
		api_key = vim.env.GEMINI_API_KEY
	else
		api_key = os.getenv(keyGeminiApiKey)
	end
	if api_key ~= nil and #api_key > 0 then
		return api_key, nil
	end

	err = string.format("failed to read `api_key` from environment variable %s", keyGeminiApiKey)

	return api_key, err
end

return M
