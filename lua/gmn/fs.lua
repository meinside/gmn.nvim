-- lua/gmn/fs.lua
--
-- File module
--
-- last update: 2025.09.02.

-- external dependencies
local path = require("plenary/path")

local M = {}

-- read and return the `api_key` value from the config file at `filepath`.
function M.read_api_key_file(filepath)
	local api_key = nil
	local err = nil

	-- read from file,
	local f = io.open(path:new(filepath):expand(), "r")
	if f ~= nil then
		local str = f:read("*a")
		io.close(f)
		local parsed = vim.json.decode(str)

		if parsed.api_key then
			api_key = parsed.api_key
		else
			err = "failed to read `api_key` from: " .. filepath
		end
	else
		err = "failed to read: " .. filepath
	end

	return api_key, err
end

return M
