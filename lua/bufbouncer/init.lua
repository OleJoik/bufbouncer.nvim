local log = require("bufbouncer.internal.log")
local bbouncer_state = require("bufbouncer.internal.state")
local render = require("bufbouncer.internal.render")
local setup_autocmd = require("bufbouncer.internal.autocommands")
local config = require("bufbouncer.internal.config")

local bufbouncer = {}
bufbouncer.focus_buffer = bbouncer_state.focus_buffer
bufbouncer.window_buffer_count = bbouncer_state.window_buffer_count
bufbouncer.is_bouncer_window = bbouncer_state.is_bouncer_window
bufbouncer.get_window_buffer = bbouncer_state.get_window_buffer

bufbouncer.update = render

bufbouncer.setup = function(user_config)
	config.selected = vim.tbl_deep_extend("force", config.default, user_config or {})

	log.info("Setting up plugin with config: " .. vim.inspect(config))

	setup_autocmd(config.selected)
end

return bufbouncer
