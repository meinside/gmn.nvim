-- tests/gmn_spec.lua
--
-- Tests for gmn.lua's part-extraction logic. We don't hit the network:
-- we replace generation.text with a stub that hands a canned response
-- straight to the callback.

local h = require("tests.helpers")

local function reset_modules()
	package.loaded["gmn"] = nil
	package.loaded["gmn/generation"] = nil
	package.loaded["gmn.generation"] = nil
end

-- run a single generate_text call against a stubbed generation.text
-- and capture (parts, err) synchronously.
local function run_with_stub(stub_response)
	reset_modules()
	local gmn = require("gmn")
	local generation = require("gmn/generation")
	generation.text = function(_, cb, _)
		cb(stub_response.res, stub_response.err)
	end

	local got_parts, got_err
	gmn.generate_text({ "hi" }, function(parts, err)
		got_parts, got_err = parts, err
	end)
	return got_parts, got_err
end

local M = {}

function M.collects_single_text_part()
	local parts, err = run_with_stub({
		res = { candidates = { { content = { parts = { { text = "hello" } } } } } },
	})
	h.eq(err, nil)
	h.eq(parts, { "hello" })
end

function M.collects_multiple_text_parts_in_order()
	local parts, err = run_with_stub({
		res = {
			candidates = {
				{
					content = {
						parts = {
							{ text = "one" },
							{ text = "two" },
							{ text = "three" },
						},
					},
				},
			},
		},
	})
	h.eq(err, nil)
	h.eq(parts, { "one", "two", "three" })
end

-- regression: thought summaries (parts with `thought = true`) used to leak
-- into the output when thinking mode was enabled.
function M.skips_thought_parts()
	local parts, err = run_with_stub({
		res = {
			candidates = {
				{
					content = {
						parts = {
							{ thought = true, text = "internal reasoning" },
							{ text = "final answer" },
						},
					},
				},
			},
		},
	})
	h.eq(err, nil)
	h.eq(parts, { "final answer" })
end

-- regression: non-text parts (functionCall etc.) used to leave nil holes
-- in the parts array, which broke downstream `#parts` and ipairs usage.
function M.skips_non_text_parts_without_creating_gaps()
	local parts, err = run_with_stub({
		res = {
			candidates = {
				{
					content = {
						parts = {
							{ text = "before" },
							{ functionCall = { name = "x" } },
							{ text = "after" },
						},
					},
				},
			},
		},
	})
	h.eq(err, nil)
	h.eq(parts, { "before", "after" })
end

function M.errors_when_only_thought_parts()
	local parts, err = run_with_stub({
		res = {
			candidates = {
				{
					content = {
						parts = {
							{ thought = true, text = "thinking" },
						},
					},
				},
			},
		},
	})
	h.eq(parts, {})
	h.truthy(err and err:find("No text parts"), "expected 'No text parts' error, got: " .. tostring(err))
end

function M.propagates_generation_error()
	local parts, err = run_with_stub({ err = "boom" })
	h.eq(parts, {})
	h.eq(err, "boom")
end

function M.errors_when_no_candidates()
	local parts, err = run_with_stub({ res = { candidates = {} } })
	h.eq(parts, {})
	h.truthy(err and err:find("No candidate"), "expected 'No candidate' error, got: " .. tostring(err))
end

function M.errors_when_no_parts()
	local parts, err = run_with_stub({
		res = { candidates = { { content = { parts = {} } } } },
	})
	h.eq(parts, {})
	h.truthy(err and err:find("No content parts"), "expected 'No content parts' error, got: " .. tostring(err))
end

return M
