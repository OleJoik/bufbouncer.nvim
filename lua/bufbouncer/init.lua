local log = require("bufbouncer.internal.log")
local bbouncer_state = require("bufbouncer.internal.state")
local commands = require("bufbouncer.commands")
local render = require("bufbouncer.internal.render")
local setup_autocmd = require("bufbouncer.internal.autocommands")

local bufbouncer = {}
bufbouncer._state = bbouncer_state

bufbouncer.window_buffer_count = bbouncer_state.window_buffer_count
bufbouncer.window_count = bbouncer_state.window_count
bufbouncer.is_bouncer_window = bbouncer_state.is_bouncer_window
bufbouncer.bwipeout = bbouncer_state.bwipeout
bufbouncer.focus_buffer = bbouncer_state.focus_buffer
bufbouncer.get_window_buffer = bbouncer_state.get_window_buffer

bufbouncer.remove_buf_from_win = commands.remove_buf_from_win

bufbouncer.move_buffer = commands.move_buffer
bufbouncer.add_buffer_to_window = commands.add_buffer_to_window
bufbouncer.create = commands.create
bufbouncer.update = render

bufbouncer.setup = function(config)
	bufbouncer._config = vim.tbl_deep_extend("force", require("bufbouncer.internal.config"), config or {})

	setup_autocmd(bufbouncer._config)
end

return bufbouncer
