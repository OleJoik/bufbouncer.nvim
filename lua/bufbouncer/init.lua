local bbouncer_state = require("bufbouncer.internal.state")
local render = require("bufbouncer.internal.render")
local setup_autocmd = require("bufbouncer.internal.autocommands")

local bufbouncer = {}
bufbouncer.focus_buffer = bbouncer_state.focus_buffer
bufbouncer.window_buffer_count = bbouncer_state.window_buffer_count
bufbouncer.is_bouncer_window = bbouncer_state.is_bouncer_window
bufbouncer.get_window_buffer = bbouncer_state.get_window_buffer

bufbouncer.update = render

bufbouncer.setup = function(config)
	bufbouncer._config = vim.tbl_deep_extend("force", require("bufbouncer.internal.config"), config or {})

	setup_autocmd(bufbouncer._config)
end

return bufbouncer
