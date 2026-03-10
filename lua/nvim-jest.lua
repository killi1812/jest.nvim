local M = {}

---@class config
---@field watch boolean
---@field jest_cmd string
---@field silent string
---@field remote {host: string, path: string}
local config = {}

local function get_current_file_path()
	if config.remote == nil then
		return vim.fn.expand("%:p")
	end
	return config.remote.path .. "/" .. vim.fn.expand("%:.")
end

local function get_current_folder_path()
	return vim.fn.expand("%:h")
end

local function create_window()
	vim.cmd("botright vnew")
end

local function focus_last_accessed_window()
	vim.cmd("wincmd p")
end

local function get_local_jest()
	local root_dir = vim.fn.finddir("node_modules/..", get_current_folder_path() .. ";")
	return root_dir .. "/node_modules/jest/bin/jest.js"
end

local function get_remote_jest()
	return "ssh "
		.. config.remote.host
		.. " -t '"
		.. config.remote.path
		.. "/node_modules/jest/bin/jest.js"
		.. " --config "
		.. config.remote.path
		.. "/jest.config.js"
		.. "'"
end

local function run_jest(args)
	local t = {}
	table.insert(t, "terminal " .. config.jest_cmd)

	if args ~= nil then
		for _, v in pairs(args) do
			table.insert(t, v)
		end
	end

	local jest_cmd = table.concat(t, "")
	vim.api.nvim_command(jest_cmd)
end

---@param user_data config
function M.setup(user_data)
	if user_data ~= nil then
		config.jest_cmd = user_data.jest_cmd or nil
		config.silent = user_data.silent or nil
		config.remote = user_data.remote or nil
		config.watch = user_data.watch or true
	end

	if config.jest_cmd == nil then
		if config.remote == nil then
			config.jest_cmd = get_local_jest()
		else
			config.jest_cmd = get_remote_jest()
		end
	end

	if config.silent == nil then
		config.silent = true
	end
end

function M.test_project()
	create_window()
	run_jest()
	focus_last_accessed_window()
end

function M.test_file()
	local c_file = get_current_file_path()
	create_window()

	local args = {}
	table.insert(args, " --runTestsByPath " .. c_file)
	if config.watch then
		table.insert(args, " --watch")
	end

	if config.silent then
		table.insert(args, " --silent")
	end

	run_jest(args)

	focus_last_accessed_window()
end

function M.test_single()
	local c_file = get_current_file_path()
	local line = vim.api.nvim_get_current_line()

	local _, _, test_name = string.find(line, "^%s*%a+%(['\"](.+)['\"]")

	if test_name ~= nil then
		create_window()

		local args = {}
		table.insert(args, " --runTestsByPath " .. c_file)
		table.insert(args, " -t='" .. test_name .. "'")
		if config.watch then
			table.insert(args, " --watch")
		end
		run_jest(args)

		focus_last_accessed_window()
	else
		print("ERR: Could not find test name. Place cursor on line with test name.")
	end
end

function M.test_coverage()
	create_window()

	local args = {}
	table.insert(args, " --coverage")

	run_jest(args)
	focus_last_accessed_window()
end

return M
