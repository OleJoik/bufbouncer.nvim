local state = {}

state._state = {
	-- example content
	-- [1000] = {
	-- 	bufs = {
	-- 		{
	-- 			buf = 3,
	-- 			file = "path/to/file.lua",
	-- 			active = "active" | "inactive" | "selected"
	-- 		},
	-- 	},
	-- },
}

state.is_bouncer_window = function(win)
	if state._state[win] == nil then
		return false
	end

	return true
end

state.bwipeout = function(buf)
	for _, win_bufs in pairs(state._state) do
		local window_bufs = win_bufs["bufs"]
		if window_bufs ~= nil then
			for _, b in ipairs(window_bufs) do
				if b.buf ~= nil then
					table.remove(window_bufs, buf)
				end
			end
		end
	end
end

state.focus_buffer = function(focused_win_id, focused_buf_id)
	for win_id, win_bufs in pairs(state._state) do
		local window_bufs = win_bufs["bufs"]
		if window_bufs ~= nil then
			local is_focused_window = win_id == focused_win_id

			if is_focused_window then
				for _, b in ipairs(window_bufs) do
					if b.buf == focused_buf_id then
						b["active"] = "focused"
					else
						b["active"] = "inactive"
					end
				end
			else
				for _, b in ipairs(window_bufs) do
					if b["active"] == "focused" then
						b["active"] = "selected"
					end
				end
			end
		end
	end
end

return state
