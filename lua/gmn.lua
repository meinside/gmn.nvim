-- lua/gmn.lua
--
-- last update: 2026.02.06.

-- plugin modules
local config = require("gmn/config")
local generation = require("gmn/generation")

local M = {}

-- setup function for configuration
function M.setup(opts)
	config.override(opts)
end

-- Generates and returns text with given prompts.
--
-- opts is a table with the following keys:
-- - fetch_urls: A boolean indicating whether to fetch contents from URLs or not.
-- - web_search: A boolean indicating whether to use web search or not.
-- - thinking: A boolean indicating whether to use reasoning or not.
function M.generate_text(prompts, callback, opts)
	opts = opts or {}

	generation.text(prompts, function(res, err)
		local parts = {}

		if err == nil then
			-- take the first candidate,
			if res ~= nil and res.candidates ~= nil and #res.candidates > 0 then
				local candidate = res.candidates[1]
				if candidate.content ~= nil and candidate.content.parts ~= nil and #candidate.content.parts > 0 then
					for i, _ in ipairs(candidate.content.parts) do
						parts[i] = candidate.content.parts[i].text
					end
				else
					err = "No content parts returned from Gemini API."
				end
			else
				err = "No candidate was returned from Gemini API."
			end
		end

		if callback then
			callback(parts, err)
		end
	end, opts)
end

-- export things
return M
