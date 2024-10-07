local log = require("bufbouncer.internal.log")
local active_value = require("bufbouncer.internal.enums").WindowActive
local bbouncer_state = require("bufbouncer.internal.state")

local function get_buffer_offset()
	local number_width = vim.api.nvim_win_get_option(0, "numberwidth")
	-- local sign_column = vim.wo.signcolumn
	-- local sign_width = 0
	-- if sign_column == 'yes' then
	--   sign_width = 2
	-- elseif sign_column == 'auto' then
	--   sign_width = 2
	-- end

	-- local fold_width = vim.wo.foldcolumn
	--
	-- local total_offset = number_width + fold_width -- + sign_width
	return number_width
end

return function()
	bbouncer_state.for_each(function(win, state)
		local offset = get_buffer_offset()
		local spaces = string.rep(" ", offset)
		local winline = spaces

		for _, buf in ipairs(state["bufs"]) do
			if vim.api.nvim_buf_is_valid(buf.buf) then
				local filename = buf.file:match("^.+[\\/](.+)$")
				local is_modified = vim.api.nvim_buf_get_option(buf.buf, "modified")

				local tab = ""
				if is_modified then
					tab = tab .. "   " .. filename .. " + "
				else
					tab = tab .. "   " .. filename .. "   "
				end

				if buf.active == active_value.INACTIVE then
					winline = winline .. "%#BufBouncerInactive#" .. tab .. " "
				elseif buf.active == active_value.SELECTED then
					winline = winline .. "%#BufBouncerSelected#" .. tab .. "%#BufBouncerInactive# "
				else
					winline = winline .. "%#BufBouncerFocused#" .. tab .. "%#BufBouncerInactive# "
				end
			else
				vim.notify("Bufs state broken: buf " .. buf.buf .. " is not valid", vim.log.levels.WARN)
			end
		end

		winline = winline .. "%#Normal#"

		vim.wo[win].winbar = winline
	end)
end
