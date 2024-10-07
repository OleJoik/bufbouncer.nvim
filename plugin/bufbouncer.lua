vim.api.nvim_create_user_command("BufBounceCreate", function()
	require("bufbouncer").create()
end, {})

vim.api.nvim_create_user_command("BufBounceUpdate", function()
	require("bufbouncer").update()
end, {})

require("bufbouncer").setup()

local move = function(dir)
	local windo = require("bufbouncer")
	local old_win = vim.api.nvim_get_current_win()
	local buf = vim.api.nvim_get_current_buf()

	vim.cmd("wincmd " .. dir)
	local new_win = vim.api.nvim_get_current_win()

	windo.move_buffer(old_win, new_win, buf)
	windo.focus_buffer(new_win, buf)
	windo.update()
end

vim.keymap.set("n", "<leader>l", function()
	move("l")
end)

vim.keymap.set("n", "<leader>k", function()
	move("k")
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>j", function()
	move("j")
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>h", function()
	move("h")
end, { noremap = true, silent = true })

vim.keymap.set("n", "<leader>ws", function()
	local log = require("bufbouncer.internal.log")
	local state = require("bufbouncer.internal.state")
	local output = vim.inspect(state.windows)
	log.info(output)
end, { noremap = true, silent = true })
