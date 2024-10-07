local cfg = require("bufbouncer.internal.config")

local logging = {}
logging._file_path = vim.fn.stdpath("data") .. "/bufbouncer.nvim.log"

local _write_log = function(prefix, message)
	local log_file = io.open(logging._file_path, "a")

	if log_file then
		local time = os.date("%Y-%m-%d %H:%M:%S")
		log_file:write(string.format("[%s] %s %s\n", time, prefix, message))
		log_file:close()
	end
end

logging.error = function(message)
	if not cfg.logging.enabled then
		return
	end

	_write_log("ERROR", message)
end

logging.warn = function(message)
	if not cfg.logging.enabled then
		return
	end

	if cfg.logging.log_level > 3 then
		return
	end

	_write_log("WARN", message)
end

logging.info = function(message)
	if not cfg.logging.enabled then
		return
	end

	if cfg.logging.log_level > 2 then
		return
	end

	_write_log("INFO", message)
end

logging.debug = function(message)
	if not cfg.logging.enabled then
		return
	end

	if cfg.logging.log_level > 1 then
		return
	end

	_write_log("DEBUG", message)
end

function logging.capture_error_logs(fn)
	local success, result = xpcall(fn, function(err)
		local trace = debug.traceback(tostring(err), 2)
		logging.error(trace)
		return trace
	end)
	if not success then
		vim.notify(result, vim.log.levels.ERROR)
	end
end

return logging
