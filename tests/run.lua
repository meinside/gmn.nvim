-- tests/run.lua
--
-- Zero-dependency test runner.
--
-- Usage:
--   nvim --headless --clean -u NONE -l tests/run.lua            # run all
--   nvim --headless --clean -u NONE -l tests/run.lua util       # filter by substring
--
-- Each `tests/*_spec.lua` returns a table mapping "test name" -> function().
-- A test fails by raising (e.g. via tests/helpers.lua); otherwise it passes.

-- locate project root from this file's path so cwd doesn't matter
local script = debug.getinfo(1, "S").source:sub(2)
local tests_dir = vim.fn.fnamemodify(script, ":p:h")
local root = vim.fn.fnamemodify(tests_dir, ":h")

-- make `require("gmn.*")` and `require("tests.*")` work
package.path = table.concat({
	root .. "/lua/?.lua",
	root .. "/lua/?/init.lua",
	root .. "/?.lua",
	root .. "/?/init.lua",
	package.path,
}, ";")

-- gmn modules use `require("gmn/util")` style with slashes; package.path
-- handles those too via the `/?.lua` pattern above.

local filter = arg and arg[1]

local function list_specs()
	local glob = tests_dir .. "/*_spec.lua"
	local files = vim.fn.glob(glob, false, true)
	table.sort(files)
	return files
end

local function spec_module_name(path)
	-- "<root>/tests/util_spec.lua" -> "tests.util_spec"
	local rel = path:sub(#root + 2):gsub("%.lua$", ""):gsub("/", ".")
	return rel
end

local total, passed, failed = 0, 0, 0
local failures = {}

for _, path in ipairs(list_specs()) do
	local mod = spec_module_name(path)
	if filter and not mod:find(filter, 1, true) then
		-- skipped by filter
	else
		print("\n" .. mod)
		local ok, spec = pcall(require, mod)
		if not ok then
			print("  [LOAD FAIL] " .. tostring(spec))
			failed = failed + 1
			table.insert(failures, { mod = mod, name = "<load>", err = spec })
		else
			-- iterate in stable order: collect keys, sort
			local names = {}
			for name, _ in pairs(spec) do
				table.insert(names, name)
			end
			table.sort(names)
			for _, name in ipairs(names) do
				local fn = spec[name]
				total = total + 1
				local tok, terr = xpcall(fn, debug.traceback)
				if tok then
					passed = passed + 1
					print("  [OK]   " .. name)
				else
					failed = failed + 1
					print("  [FAIL] " .. name)
					print("         " .. tostring(terr):gsub("\n", "\n         "))
					table.insert(failures, { mod = mod, name = name, err = terr })
				end
			end
		end
	end
end

print("\n" .. string.rep("-", 40))
print(string.format("%d passed, %d failed (of %d)\n", passed, failed, total))

if failed > 0 then
	-- non-zero exit code so CI fails
	vim.cmd("cq")
else
	vim.cmd("qa")
end
