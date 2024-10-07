local log = require("bufbouncer.internal.log")
local commands = require("bufbouncer.commands")
local render = require("bufbouncer.internal.render")
local state = require("bufbouncer.internal.state")

local setup_autocmd = function(cfg)
	vim.api.nvim_create_autocmd("ColorScheme", {
		callback = function()
			log.info("AUTOCMD: ColorScheme - updating highlights...")
			log.capture_error_logs(function()
				for k, v in pairs(cfg.highlights) do
					vim.api.nvim_set_hl(0, k, v)
				end
			end)
			log.info("AUTOCMD: ColorScheme - highlights updated!")
		end,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		pattern = "*",
		callback = function(_)
			log.info("AUTOCMD: VimEnter - creating bouncer...")
			log.capture_error_logs(function()
				log.capture_error_logs(function()
					commands.create()
				end)
			end)
			log.info("AUTOCMD: VimEnter - bouncer created!")
		end,
	})

	vim.api.nvim_create_autocmd("BufEnter", {
		pattern = "*",
		callback = function(evt)
			log.info("AUTOCMD: BufEnter starting...")
			log.capture_error_logs(function()
				local evt_win = vim.api.nvim_get_current_win()
				local is_bouncer = state.is_bouncer_window(evt_win)
				local null_buffer = evt.file == ""
				log.info(string.format("BufEnter: window_id: %s, is_bouncer: %s", evt_win, tostring(is_bouncer)))
				if not is_bouncer or null_buffer then
					return
				end

				log.info(string.format("BufEnterAddFocusUpdate: file: %s", evt.file))
				commands.add_buffer_to_window(evt_win, evt.buf, evt.file)
				state.focus_buffer(evt_win, evt.buf)
				render()
			end)
			log.info("AUTOCMD: BufEnter completed!")
		end,
	})

	vim.api.nvim_create_autocmd("BufModifiedSet", {
		pattern = "*",
		callback = function(_)
			log.info("AUTOCMD: BufModifiedSet starting...")
			log.capture_error_logs(function()
				log.capture_error_logs(function()
					render()
				end)
			end)
			log.info("AUTOCMD: BufModifiedSet completed!")
		end,
	})

	vim.api.nvim_create_autocmd("BufWipeout", {
		pattern = "*",
		callback = function(evt)
			log.info("AUTOCMD: BufWipeout starting...")
			log.capture_error_logs(function()
				log.capture_error_logs(function()
					state.bwipeout(evt.buf)
					render()
				end)
			end)
			log.info("AUTOCMD: BufWipeout completed!")
		end,
	})

	vim.api.nvim_create_autocmd("WinEnter", {
		pattern = "*",
		callback = function(ev)
			log.info("AUTOCMD: WinEnter starting...")
			log.capture_error_logs(function()
				local entering_win = vim.api.nvim_get_current_win()
				local entering_buf = vim.api.nvim_get_current_buf()
				local is_bouncer = state.is_bouncer_window(entering_win)

				log.info(
					"WinEnter: " .. entering_win .. ", is_bufbouncer:" .. tostring(is_bouncer) .. ", file: " .. ev.file
				)

				if is_bouncer then
					state.focus_buffer(entering_win, entering_buf)
					render()
				end
			end)
			log.info("AUTOCMD: WinEnter completed!")
		end,
	})

	vim.api.nvim_create_autocmd("WinLeave", {
		pattern = "*",
		callback = function(_)
			log.info("AUTOCMD: WinLeave starting...")
			log.capture_error_logs(function()
				local leaving_win = vim.api.nvim_get_current_win()
				local TIMEOUT = 50 -- ms

				log.info("Leaving window: " .. leaving_win)

				if not state.is_bouncer_window(leaving_win) then
					return
				end
				local window_created = false
				local new_buf_entered = false

				local win_new_cmd_id = vim.api.nvim_create_autocmd("WinNew", {
					pattern = "*",
					callback = function(_)
						window_created = true
						local new_win = vim.api.nvim_get_current_win()
						local bufname = vim.api.nvim_buf_get_name(0)
						log.info("WinNew after WinLeave: " .. new_win .. " bufname: " .. bufname)
						if not state.is_bouncer_window(new_win) then
							vim.wo[new_win].winbar = nil
						end

						local buf_add_cmd_id = vim.api.nvim_create_autocmd("BufEnter", {
							pattern = "*",
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
								commands.create()
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
			end)
			log.info("AUTOCMD: WinLeave completed!")
		end,
	})
end

return setup_autocmd
