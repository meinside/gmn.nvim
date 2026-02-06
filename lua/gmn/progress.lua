-- lua/gmn/progress.lua
--
-- Progress indication module
--
-- last update: 2026.02.06.

local M = {}

-- starts a progress indicator
--
-- @param msg The message to display
-- @return A table with a `stop` function
function M.start(msg, level)
	if not level then
		level = vim.log.levels.INFO
	end

	-- Try to send the first notification
	local noti_id = vim.notify(msg, level, {
		title = "Gemini",
		icon = "✨",
		hide_from_history = true,
	})

	return {
		stop = function(final_msg, level)
			if final_msg then
				if not level then
					level = vim.log.levels.INFO
				end

				vim.notify(final_msg, level, {
					title = "Gemini",
					icon = "✨",
					replace = noti_id,
				})
			end
		end,
	}
end

return M
