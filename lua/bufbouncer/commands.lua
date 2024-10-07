local log = require("bufbouncer.internal.log")
local bbouncer_state = require("bufbouncer.internal.state")
local render = require("bufbouncer.internal.render")
local commands = {}

commands.create = function()
	log.capture_error_logs(function()
		local win = vim.api.nvim_get_current_win()
		local buf = vim.api.nvim_get_current_buf()
		local filename = vim.api.nvim_buf_get_name(buf)
		log.info("Creating BufBouncer!: win: " .. win .. " buf: " .. buf .. " file: " .. filename)
		bbouncer_state.add_window(win)
		if filename ~= "" then
			commands.add_buffer_to_window(win, buf, filename)
			bbouncer_state.focus_buffer(win, buf)
			render()
		end
	end)
end

commands.add_buffer_to_window = function(win, buf, filename)
	log.capture_error_logs(function()
		if not vim.api.nvim_win_is_valid(win) then
			vim.notify("Window is not valid, cannot add buffer.", vim.log.levels.WARN)
			return
		end

		if not vim.api.nvim_buf_is_valid(buf) then
			vim.notify("Buffer is not valid, cannot add to window.", vim.log.levels.WARN)
			return
		end

		bbouncer_state.add_buffer_to_window(win, buf, filename)
	end)
end

commands.move_buffer = function(from_win, to_win, buf)
	log.capture_error_logs(function()
		local cursor = vim.api.nvim_win_get_cursor(from_win)
		local b = bbouncer_state.remove_buffer_from_window(from_win, buf)

		if b == nil then
			log.error("Unable to move buffer. Could not find buffer in state.")
			return
		end

		local win_bufs = bbouncer_state.get_window(from_win).bufs

		if b.next_index ~= nil then
			vim.api.nvim_win_set_buf(from_win, win_bufs[b.next_index].buf)
		end

		bbouncer_state.add_buffer_to_window(to_win, buf, b.buf_data.file)
		vim.api.nvim_win_set_buf(to_win, buf)
		vim.api.nvim_win_set_cursor(to_win, cursor)
	end)
end

commands.remove_buf_from_win = function(buf, win, opts)
	log.capture_error_logs(function()
		log.info("Removing buf " .. buf .. " from win " .. win)
		local win_data = bbouncer_state.get_window(win)
		if win_data == nil then
			log.error("Win " .. win .. " is not known to bufbouncer. Will not remove buf " .. buf)
			return
		end

		local bufs = win_data["bufs"]
		if bufs == nil then
			log.error("Win " .. win .. " does not have bufs. State corrupted.")
			return
		end

		local buf_data = nil
		local buf_index = nil
		for i, b in ipairs(bufs) do
			if b.buf == buf then
				buf_data = b
				buf_index = i
			end
		end

		if buf_data == nil or buf_index == nil then
			log.error("Could not find buf " .. buf .. " in win " .. win)
			return
		end

		if vim.bo[buf].modified then
			vim.notify("Could not delete buffer " .. buf .. ", it has unsaved changes", vim.log.levels.ERROR)
			return
		end

		if opts and opts.close_buffer_if_unused then
			local window_buffers = vim.fn.win_findbuf(buf)
			if #window_buffers == 1 then
				if #win_data["bufs"] == 1 then
					local new_buf = vim.api.nvim_create_buf(false, true)
					vim.api.nvim_win_set_buf(win, new_buf)
				end
				local success, err = pcall(require("bufdelete").bufwipeout, buf)
				if not success and err ~= nil then
					log.error(err)
					vim.notify(err, vim.log.levels.ERROR)
					return
				else
					log.info("Successfully deleted buf " .. buf)
				end
			end
		end

		bbouncer_state.remove_buffer_from_window(win, buf)
		if #win_data["bufs"] == 0 then
			local new_buf = vim.api.nvim_create_buf(false, true)
			vim.api.nvim_win_set_buf(win, new_buf)
		elseif buf_index == 1 then
			vim.api.nvim_win_set_buf(win, win_data["bufs"][buf_index].buf)
		else
			vim.api.nvim_win_set_buf(win, win_data["bufs"][buf_index - 1].buf)
		end
		log.info("Successfully removed buf " .. buf .. " from win " .. win)

		render()
	end)
end

commands.close_win = function(win)
	log.capture_error_logs(function()
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
	end)
end

return commands
