-- lua/gmn.lua
--
-- last update: 2025.05.29.

-- plugin modules
local config = require("gmn/config")
local generation = require("gmn/generation")

local M = {}

-- setup function for configuration
function M.setup(opts)
	config.override(opts)
end

-- generate and return text with given prompts
function M.generate_text(prompts)
	local parts = {}
	local res, err = generation.text(prompts)

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

	return parts, err
end

-- export things
return M
