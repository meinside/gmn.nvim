-- tests/generation_spec.lua
--
-- Tests the cancel/race behavior in generation.lua by stubbing vim.system.
-- The stub returns a fake "job handle" and remembers the on_exit callback
-- so the test can fire it whenever it wants — no real curl, no real timer.

local h = require("tests.helpers")

-- We need GEMINI_API_KEY to be set so generation.text doesn't bail out
-- before reaching the vim.system call.
vim.env.GEMINI_API_KEY = "test-key"

local function reset_modules()
	package.loaded["gmn"] = nil
	package.loaded["gmn/generation"] = nil
	package.loaded["gmn.generation"] = nil
end

local function install_vim_system_stub()
	local jobs = {} -- list of { on_exit, killed, kill_signal }
	local original = vim.system
	vim.system = function(_cmd, _opts, on_exit)
		local job = {
			killed = false,
			kill_signal = nil,
			on_exit = on_exit,
		}
		function job:kill(signal)
			self.killed = true
			self.kill_signal = signal
		end
		table.insert(jobs, job)
		return job
	end
	return jobs, function()
		vim.system = original
	end
end

-- run callbacks scheduled via vim.schedule_wrap.
local function flush()
	vim.wait(50, function()
		return false
	end)
end

local M = {}

function M.cancel_returns_false_when_idle()
	reset_modules()
	local generation = require("gmn/generation")
	h.eq(generation.cancel(), false)
end

function M.cancel_kills_in_flight_job_and_invokes_callback_with_cancelled_err()
	reset_modules()
	local generation = require("gmn/generation")
	local jobs, restore = install_vim_system_stub()

	local cb_parts, cb_err
	generation.text({ "hi" }, function(res, err)
		cb_parts, cb_err = res, err
	end, {})

	h.eq(#jobs, 1, "expected one in-flight job")
	h.eq(generation.cancel(), true)
	h.truthy(jobs[1].killed, "job should have been killed")
	h.eq(jobs[1].kill_signal, "sigterm")

	-- simulate kernel delivering signal: curl exits with code != 0
	jobs[1].on_exit({ code = 143, stdout = "", stderr = "" })
	flush()

	h.eq(cb_parts, nil)
	h.eq(cb_err, "cancelled")

	-- and a subsequent cancel must again be false (state cleared)
	h.eq(generation.cancel(), false)

	restore()
end

-- regression: starting a new request while one is in flight used to clobber
-- the module-level handle so that later :GeminiCancel did nothing. Each
-- request now keeps its own state via a closure.
function M.starting_new_request_cancels_previous_and_keeps_new_handle_cancellable()
	reset_modules()
	local generation = require("gmn/generation")
	local jobs, restore = install_vim_system_stub()

	local cb1_err, cb2_err
	generation.text({ "first" }, function(_, err)
		cb1_err = err
	end, {})
	generation.text({ "second" }, function(_, err)
		cb2_err = err
	end, {})

	h.eq(#jobs, 2, "expected two jobs created")
	h.truthy(jobs[1].killed, "first job should be killed when second starts")
	h.falsy(jobs[2].killed, "second job should still be running")

	-- fire first job's on_exit (the killed one). this MUST NOT clear the
	-- in-flight state, since the second job is now the current one.
	jobs[1].on_exit({ code = 143, stdout = "", stderr = "" })
	flush()
	h.eq(cb1_err, "cancelled")

	-- cancel should still find the second job
	h.eq(generation.cancel(), true)
	h.truthy(jobs[2].killed)

	jobs[2].on_exit({ code = 143, stdout = "", stderr = "" })
	flush()
	h.eq(cb2_err, "cancelled")

	restore()
end

function M.successful_response_clears_in_flight_state()
	reset_modules()
	local generation = require("gmn/generation")
	local jobs, restore = install_vim_system_stub()

	local got_res, got_err
	generation.text({ "hi" }, function(res, err)
		got_res, got_err = res, err
	end, {})

	local body = vim.json.encode({
		candidates = { { content = { parts = { { text = "ok" } } } } },
	})
	jobs[1].on_exit({ code = 0, stdout = body, stderr = "" })
	flush()

	h.eq(got_err, nil)
	h.truthy(got_res and got_res.candidates, "expected candidates in response")
	h.eq(generation.cancel(), false, "no in-flight job should remain")

	restore()
end

return M
