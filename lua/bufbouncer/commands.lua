local log = require("bufbouncer.internal.log")
local bbouncer_state = require("bufbouncer.internal.state")
local render = require("bufbouncer.internal.render")
local commands = {}

commands.close_win = function(win)
	local win_data = bbouncer_state._state[win]
	if win_data == nil then
		log.warn("Attempted to close win " .. win .. " but it is not known to bufbouncer.")
		return
	end

	local bufs = win_data["bufs"]
	if bufs == nil then
		log.warn("Attempted to close win " .. win .. " but could not find buffers.")
		return
	end

	local error_closing_buf = false
	for i, b in ipairs(bufs) do
		local window_buffers = vim.fn.win_findbuf(b.buf)
		if #window_buffers == 1 then
			log.info(
				"buf " .. b.buf .. " (" .. b.file .. ") is dangling after closing win " .. win .. ". Closing buf..."
			)

			local success, err = pcall(vim.api.nvim_buf_delete, b.buf, {})
			if not success and err ~= nil then
				log.error(err)
				vim.notify(err, vim.log.levels.ERROR)
				error_closing_buf = true
			else
				table.remove(win_data["bufs"], i)
				log.info("Successfully closed buffer " .. b.buf)
			end
		end
	end

	if error_closing_buf then
		log.info("close_win had an error closing a buffer. Updating UI and returning.")
		render()
		return
	end

	bbouncer_state._state[win] = nil
	if vim.api.nvim_win_is_valid(win) then
		local success, err = pcall(vim.api.nvim_win_close, win, false)
		if not success and err ~= nil then
			bbouncer_state._state[win] = win_data
			vim.notify(err, vim.log.levels.ERROR)

			log.info("close_win had an error the window. Updating UI and returning.")
			render()
			return
		end
	else
		log.warn("Attempted to close win " .. win .. ", but it is not a valid window.")
	end
end

return commands
