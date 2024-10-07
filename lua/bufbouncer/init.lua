local log = require("bufbouncer.internal.log")
local bbouncer_state = require("bufbouncer.internal.state")

local bufbouncer = {}
bufbouncer._state = bbouncer_state._state

local err_handler = function(fn)
	local success, result = xpcall(fn, function(err)
		local trace = debug.traceback(tostring(err), 2)
		log.error(trace)
		return trace
	end)
	if not success then
		vim.notify(result, vim.log.levels.ERROR)
	end
end

bufbouncer.is_bouncer_window = bbouncer_state.is_bouncer_window
bufbouncer.bwipeout = bbouncer_state.bwipeout
bufbouncer.focus_buffer = bbouncer_state.focus_buffer

bufbouncer.remove_buf_from_win = function(buf, win, opts)
	log.info("Removing buf " .. buf .. " from win " .. win)
	local win_data = bufbouncer._state[win]
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

	table.remove(win_data["bufs"], buf_index)
	if #win_data["bufs"] == 0 then
		local new_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_win_set_buf(win, new_buf)
	elseif buf_index == 1 then
		vim.api.nvim_win_set_buf(win, win_data["bufs"][buf_index].buf)
	else
		vim.api.nvim_win_set_buf(win, win_data["bufs"][buf_index - 1].buf)
	end
	log.info("Successfully removed buf " .. buf .. " from win " .. win)

	bufbouncer.update()
end

bufbouncer.move_buffer = function(from_win, to_win, buf)
	local previous_buffer = nil
	for win_id, state in pairs(bufbouncer._state) do
		local window_bufs = state["bufs"]
		if window_bufs ~= nil then
			local is_from_window = win_id == from_win

			if is_from_window then
				for i, b in ipairs(window_bufs) do
					if b.buf == buf then
						table.remove(window_bufs, i)
						break
					end
					previous_buffer = b.buf
				end
			end
		end
	end

	if not previous_buffer then
		previous_buffer = vim.api.nvim_create_buf(true, false)
		bufbouncer.add_buffer_to_window(from_win, previous_buffer, "dirtyfix/[Empty]")
	end

	local cursor = vim.api.nvim_win_get_cursor(from_win)
	vim.api.nvim_win_set_buf(from_win, previous_buffer)
	vim.api.nvim_win_set_buf(to_win, buf)
	vim.api.nvim_win_set_cursor(to_win, cursor)
end

bufbouncer.add_buffer_to_window = function(win, buf, filename)
	if not vim.api.nvim_win_is_valid(win) then
		vim.notify("Window is not valid, cannot add buffer.", vim.log.levels.WARN)
		return
	end

	if not vim.api.nvim_buf_is_valid(buf) then
		vim.notify("Buffer is not valid, cannot add to window.", vim.log.levels.WARN)
		return
	end

	if not bufbouncer.is_bouncer_window(win) then
		vim.notify("Window is not in bufbouncer, cannot add buffer to it", vim.log.levels.WARN)
		return
	end

	local window_bufs = bufbouncer._state[win]["bufs"]
	if window_bufs == nil then
		vim.notify("Window bufs not found in win bufbouncer state. Cannot add buffer.", vim.log.levels.WARN)
		return
	end

	for _, b in ipairs(window_bufs) do
		if b.buf == buf then
			-- buffer is already in window. Doing nothing
			return
		end
	end

	log.info(string.format("Adding Buffer To Window - win: %s, file: %s", win, filename))

	table.insert(bufbouncer._state[win]["bufs"], { buf = buf, file = filename, active = "inactive" })
end

bufbouncer.create = function()
	local win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_get_current_buf()
	local filename = vim.api.nvim_buf_get_name(buf)
	log.info("Creating BufBouncer!: win: " .. win .. " buf: " .. buf .. " file: " .. filename)
	bufbouncer._state[win] = { bufs = {} }
	if filename ~= "" then
		bufbouncer.add_buffer_to_window(win, buf, filename)
		bufbouncer.focus_buffer(win, buf)
		bufbouncer.update()
	end
end

bufbouncer.update = require("bufbouncer.internal.render")
bufbouncer.setup = function(config)
	bufbouncer._config = vim.tbl_deep_extend("force", require("bufbouncer.internal.config"), config or {})

	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			for k, v in pairs(bufbouncer._config.highlights) do
				vim.api.nvim_set_hl(0, k, v)
			end
		end,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		pattern = "*",
		group = bufbouncer.augroup,
		callback = function(_)
			err_handler(function()
				log.info("VimEnter")
				bufbouncer.create()
			end)
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		group = bufbouncer.augroup,
		callback = function(evt)
			local evt_win = vim.api.nvim_get_current_win()
			local is_bouncer = bufbouncer.is_bouncer_window(evt_win)
			local null_buffer = evt.file == ""
			log.info(string.format("BufEnter: window_id: %s, is_bouncer: %s", evt_win, tostring(is_bouncer)))
			if not is_bouncer or null_buffer then
				return
			end

			log.info(string.format("BufEnterAddFocusUpdate: file: %s", evt.file))
			bufbouncer.add_buffer_to_window(evt_win, evt.buf, evt.file)
			bufbouncer.focus_buffer(evt_win, evt.buf)
			bufbouncer.update()
		end,
	})

	vim.api.nvim_create_autocmd("BufModifiedSet", {
		pattern = "*",
		group = bufbouncer.augroup,
		callback = function(_)
			err_handler(function()
				bufbouncer.update()
			end)
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		pattern = "*",
		group = bufbouncer.augroup,
		callback = function(evt)
			err_handler(function()
				bufbouncer.bwipeout(evt.buf)
				bufbouncer.update()
			end)
		end,
	})

	vim.api.nvim_create_autocmd("WinEnter", {
		pattern = "*",
		group = bufbouncer.augroup,
		callback = function(ev)
			err_handler(function()
				local entering_win = vim.api.nvim_get_current_win()
				local entering_buf = vim.api.nvim_get_current_buf()
				local is_bouncer = bufbouncer.is_bouncer_window(entering_win)

				log.info(
					"WinEnter: " .. entering_win .. ", is_bufbouncer:" .. tostring(is_bouncer) .. ", file: " .. ev.file
				)

				if is_bouncer then
					bufbouncer.focus_buffer(entering_win, entering_buf)
					bufbouncer.update()
				end
			end)
		end,
	})

	vim.api.nvim_create_autocmd("WinLeave", {
		pattern = "*",
		group = bufbouncer.augroup,
		callback = function(_)
			local leaving_win = vim.api.nvim_get_current_win()
			local TIMEOUT = 50 -- ms

			log.info("Leaving window: " .. leaving_win)

			if bufbouncer.is_bouncer_window(leaving_win) then
				local window_created = false
				local new_buf_entered = false

				local win_new_cmd_id = vim.api.nvim_create_autocmd("WinNew", {
					pattern = "*",
					group = bufbouncer.augroup,
					callback = function(_)
						window_created = true
						local new_win = vim.api.nvim_get_current_win()
						local bufname = vim.api.nvim_buf_get_name(0)
						log.info("WinNew after WinLeave: " .. new_win .. " bufname: " .. bufname)
						if not bufbouncer.is_bouncer_window(new_win) then
							vim.wo[new_win].winbar = nil
						end

						local buf_add_cmd_id = vim.api.nvim_create_autocmd("BufEnter", {
							pattern = "*",
							group = bufbouncer.augroup,
							callback = function(ev)
								new_buf_entered = true
								log.info("BufEnter after WinNew: buf: " .. ev.buf .. ", file: " .. ev.file)
								-- Detected a new buffer opened in a new window.
								-- MAKE DECISION: Should a new WINDO be made???
							end,
							once = true,
						})

						vim.defer_fn(function()
							if not new_buf_entered then
								log.info("BufEnter NOT CALLED after WinNew. Assume same buffer, split command called")
								bufbouncer.create()
								vim.api.nvim_del_autocmd(buf_add_cmd_id)
							end
						end, TIMEOUT)
					end,
					once = true,
				})

				vim.defer_fn(function()
					if not window_created then
						vim.api.nvim_del_autocmd(win_new_cmd_id)
					end
				end, TIMEOUT)
			end
		end,
	})
end

return bufbouncer
