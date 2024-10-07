local enums = require("bufbouncer.internal.enums")

local hl = enums.Highlights

local config = {}
config.default = {
	highlight_enabled = true,
	logging = { enabled = true, log_level = enums.LogLevel.INFO },
	highlights = {
		[hl.BufBouncerInactive] = { default = true, fg = "#938588", bg = "#282a43", bold = false },
		[hl.BufBouncerSelected] = { default = true, fg = "#1f1f1f", bg = "#5498D2", bold = true },
		[hl.BufBouncerFocused] = { default = true, fg = "#1f1f1f", bg = "#F79961", bold = true },
	},
	debug = {
		show_win_nr = false,
		show_buf_nr = false,
	},
}

config.selected = config.default

return config
