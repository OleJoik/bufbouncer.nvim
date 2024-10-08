local log = require("bufbouncer.internal.log")
local enums = require("bufbouncer.internal.enums")

local state = { windows = {} }
-- example:
-- state = {
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

state.for_each = function(callback)
	for win, win_data in pairs(state.windows) do
		callback(win, win_data)
	end
end

state.add_window = function(win)
	state.windows[win] = { bufs = {} }
end

state.add_buffer_to_window = function(win, buf, file)
	log.info("STATE: Adding buffer " .. buf .. " to window " .. win .. "...")

	if not state.is_bouncer_window(win) then
		log.warn("Window is not in bufbouncer, cannot add buffer to it")
		return
	end

	local window_bufs = state.windows[win]["bufs"]
	if window_bufs == nil then
		log.warn("win (" .. win .. ") bufs not found in win bufbouncer state. Cannot add buffer.")
		return
	end

	for _, b in ipairs(window_bufs) do
		if b.buf == buf then
			log.info("buf " .. buf .. "already in win " .. win .. ". Doing nothing.")
			return
		end
	end

	table.insert(state.windows[win]["bufs"], { buf = buf, file = file, active = "inactive" })
	log.info("STATE: Added buffer " .. buf .. " to window " .. win .. "!")
end

function state.remove_buffer_from_window(win, buf)
	for win_id, win_data in pairs(state.windows) do
		local window_bufs = win_data.bufs
		if window_bufs ~= nil then
			if win == win_id then
				for i, b in ipairs(window_bufs) do
					if b.buf == buf then
						local next_index = nil
						if #window_bufs > 1 and b.active ~= enums.WindowActive.INACTIVE then
							if i > 1 then
								next_index = i - 1
							else
								next_index = i
							end

							window_bufs[next_index].active = enums.WindowActive.SELECTED
						end
						return { buf_data = table.remove(window_bufs, i), next_index = next_index }
					end
				end
			end
		end
	end
end

state.get_window = function(win)
	return state.windows[win]
end

state.get_window_buffer = function(win, buf)
	for _, buf_data in ipairs(state.windows[win].bufs) do
		if buf_data.buf == buf then
			return buf_data
		end
	end
	return nil
end

function state.window_buffer_count(win)
	return #state.windows[win].bufs
end

function state.window_count()
	return #state.windows
end

state.remove_window = function(win)
	state.windows[win] = nil
end

state.is_bouncer_window = function(win)
	if state.windows[win] == nil then
		return false
	end

	return true
end

state.bouncers_with_buffer = function(buf)
	local bouncers = {}
	for win, win_data in pairs(state.windows) do
		for _, buf_data in ipairs(win_data["bufs"]) do
			if buf_data.buf == buf then
				table.insert(bouncers, win)
			end
		end
	end

	return bouncers
end

state.bwipeout = function(buf)
	for _, win_bufs in pairs(state.windows) do
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
	for win_id, win_bufs in pairs(state.windows) do
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
