local log = require("bufbouncer.internal.log")
vim.api.nvim_create_user_command("BufBounceCreate", function()
	require("bufbouncer.commands").create()
end, {})

require("bufbouncer").setup()
require("nvim-web-devicons").setup()
log.info(vim.inspect(require("nvim-web-devicons").get_icons()))

local split_with_win_cmd = function(dir)
	if dir == "l" then
		vim.cmd("vsplit")
	elseif dir == "h" then
		vim.cmd("vsplit")
		vim.cmd("wincmd H")
	elseif dir == "j" then
		vim.cmd("split")
	elseif dir == "k" then
		vim.cmd("split")
		vim.cmd("wincmd K")
	end
end

-- Todo: Move this function to commands module probably...
-- Also, check why collapsing windows are so slow...?
local move = function(dir)
	local bbouncer = require("bufbouncer")
	local commands = require("bufbouncer.commands")
	local old_win = vim.api.nvim_get_current_win()

	if not bbouncer.is_bouncer_window(old_win) then
		return
	end
	local buf = vim.api.nvim_get_current_buf()

	vim.cmd("wincmd " .. dir)
	local new_win = vim.api.nvim_get_current_win()
	if not bbouncer.is_bouncer_window(new_win) then
		return
	end

	log.info("MOVE: Moving buf " .. buf .. " from win " .. old_win .. " to win " .. new_win .. "...")

	if new_win ~= old_win then
		log.info("MOVE should MOVE")
		commands.move_buffer(old_win, new_win, buf)

		if bbouncer.window_buffer_count(old_win) == 0 then
			log.info("MOVE should CLOSE OLD")
			commands.close_win(old_win)
		end
	elseif bbouncer.window_buffer_count(new_win) ~= 1 then
		log.info("MOVE should SPLIT AND MOVE")
		split_with_win_cmd(dir)
		new_win = vim.api.nvim_get_current_win()
		commands.move_buffer(old_win, new_win, buf)
		-- There is a bug here where the autocommands doesn't pick up the new buffer.
		-- Will manually create for now
		commands.create()
	else
		log.info("MOVE should SPLIT")
		local buf_data = bbouncer.get_window_buffer(old_win, buf)
		if buf_data ~= nil then
			split_with_win_cmd(dir)
			new_win = vim.api.nvim_get_current_win()
			commands.add_buffer_to_window(new_win, buf, buf_data.file)
		end
	end

	bbouncer.focus_buffer(new_win, buf)
	bbouncer.update()

	log.info("MOVE: Success! Moved buf " .. buf .. " from win " .. old_win .. " to win " .. new_win .. "!")
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
	local state = require("bufbouncer.internal.state")
	local output = vim.inspect(state.windows)
	log.info(output)
end, { noremap = true, silent = true })
