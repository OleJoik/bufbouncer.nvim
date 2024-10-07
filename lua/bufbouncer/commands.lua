local log = require("bufbouncer.internal.log")
local bbouncer_state = require("bufbouncer.internal.state")
local render = require("bufbouncer.internal.render")
local commands = {}

commands.close_win = function(win)
	local win_data = bbouncer_state.get_window(win)
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
		local bouncers = bbouncer_state.bouncers_with_buffer(b.buf)
		if #bouncers == 1 then
			log.info(
				"buf " .. b.buf .. " (" .. b.file .. ") is dangling after closing win " .. win .. ". Closing buf..."
			)

			-- Todo: First check if buffer is used in another window than this one.
			-- If so, do not close.
			local success, err = pcall(require("bufdelete").bufwipeout, b.buf)
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

	bbouncer_state.remove_window(win)
	if vim.api.nvim_win_is_valid(win) then
		log.info("Closing window " .. win)
		local success, err = pcall(vim.api.nvim_win_close, win, false)
		if not success and err ~= nil then
			bbouncer_state.windows[win] = win_data
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
