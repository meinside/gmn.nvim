-- tests/helpers.lua
--
-- Tiny assertion helpers for the spec files. Intentionally minimal:
-- if a check isn't expressible here in a couple of lines, write a
-- one-off assertion in the spec instead of growing this module.

local M = {}

local function fmt(v)
	return vim.inspect(v)
end

-- assert deep equality; raises with a readable diff on failure.
function M.eq(actual, expected, msg)
	if not vim.deep_equal(actual, expected) then
		error((msg and (msg .. "\n") or "") .. "  expected: " .. fmt(expected) .. "\n  actual:   " .. fmt(actual), 2)
	end
end

-- assert that fn raises; if pattern is given, the error string must match it.
function M.throws(fn, pattern)
	local ok, err = pcall(fn)
	if ok then
		error("expected error, got success", 2)
	end
	if pattern and not tostring(err):find(pattern) then
		error("error did not match " .. fmt(pattern) .. ": " .. tostring(err), 2)
	end
end

-- assert truthy / falsy with optional message.
function M.truthy(v, msg)
	if not v then
		error((msg or "expected truthy") .. ", got: " .. fmt(v), 2)
	end
end

function M.falsy(v, msg)
	if v then
		error((msg or "expected falsy") .. ", got: " .. fmt(v), 2)
	end
end

return M
