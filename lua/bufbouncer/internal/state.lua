local log = require("bufbouncer.internal.log")

local _state = { windows = {} }
-- example:
-- _state = {
-- 	windows = {
-- 		[1000] = {
-- 			bufs = {
-- 				{
-- 					buf = "3",
-- 					file = "path/to/file.lua",
-- 					active = enums.WindowActive,
-- 				},
-- 			},
-- 		},
-- 	},
-- }
_state.for_each = function(callback)
	for win, win_data in pairs(_state["windows"]) do
		callback(win, win_data)
	end
end

_state.add_window = function(win)
	_state["windows"][win] = { bufs = {} }
end

_state.get_window = function(win)
	return _state["windows"][win]
end

_state.remove_window = function(win)
	_state["windows"][win] = nil
end

_state.is_bouncer_window = function(win)
	if _state["windows"][win] == nil then
		return false
	end

	return true
end

_state.bouncers_with_buffer = function(buf)
	local bouncers = {}
	for win, win_data in pairs(_state["windows"]) do
		for _, buf_data in ipairs(win_data["bufs"]) do
			if buf_data.buf == buf then
				table.insert(bouncers, win)
			end
		end
	end

	return bouncers
end

_state.bwipeout = function(buf)
	for _, win_bufs in pairs(_state.windows) do
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

_state.focus_buffer = function(focused_win_id, focused_buf_id)
	for win_id, win_bufs in pairs(_state.windows) do
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

local _state_proxy = {}
local mt = {
	__index = _state,
	__newindex = function(_, _, _)
		error("Attempt to modify read-only table", 2)
	end,
}
setmetatable(_state_proxy, mt)

return _state_proxy
