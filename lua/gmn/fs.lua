-- lua/gmn/fs.lua
--
-- File module
--
-- last update: 2026.03.06.

local M = {}

-- read and return the `api_key` value from the config file at `filepath`.
function M.read_api_key_file(filepath)
	local api_key = nil
	local err = nil

	-- read from file,
	local f = io.open(vim.fn.expand(filepath), "r")
	if f ~= nil then
		local str = f:read("*a")
		io.close(f)
		local ok, parsed = pcall(vim.json.decode, str)
		if ok and type(parsed) == "table" and parsed.api_key then
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
