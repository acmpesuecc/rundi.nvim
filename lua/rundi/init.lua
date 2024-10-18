local config = {
	autocompile = {
		python = {
			compiler = "python3",
		},
		cpp = {
			compiler = "g++",
			compiler_args = "",
			output_format = "%:t:r",
		},
		c = {
			compiler = "gcc",
			compiler_args = "",
			output_format = "%:t:r",
		},
		rust = {
			compiler = "rustc",
			compiler_args = "",
			output_format = "%:t:r",
		},
	},
	silent = true,
	keymap = "<C-c>",
	terminal_split = true,
	split_direction = "top",
	persist_viewport = true,
}

local previous_buffer = 0

local function setup_autocompile(filetype, options)
	local ac = config.autocompile[filetype]
	if not ac then
		return
	end

	local silent_option = config.silent and "<silent>" or ""
	local compiler_args = options.compiler_args and (" " .. options.compiler_args) or ""
	local output_flag = options.output_format and (" -o " .. options.output_format) or ""
	local execute_flag = options.output_format and (" && ./" .. options.output_format) or ""
	local input_file = ' "%"'

	local command = options.compiler .. compiler_args .. input_file .. output_flag .. execute_flag

	if config.split_direction == "fullscreen" then
		vim.cmd("term " .. command)
		return
	end

	local split_cmd = "split"
	if config.terminal_split then
		if config.split_direction == "bottom" then
			split_cmd = "splitbelow"
		elseif config.split_direction == "left" then
			split_cmd = "vsplit"
		elseif config.split_direction == "right" then
			split_cmd = "vsplitright"
		end

		local current_buffer = vim.fn.bufnr("%")
		vim.cmd(split_cmd .. " | term " .. command)

		if config.persist_viewport and previous_buffer ~= 0 then
			vim.cmd("execute 'buffer ' .. " .. previous_buffer)
		end

		previous_buffer = current_buffer
	end
end

-- Function to handle autocompiling when :rundi is called
local function Rundi()
	local filetype = vim.bo.filetype
	local options = config.autocompile[filetype]
	if options then
		setup_autocompile(filetype, options)
		print("Autocompile executed for filetype: " .. filetype)
	else
		print("No autocompile configuration found for filetype: " .. filetype)
		vim.cmd("insert")
	end
end

-- Function that overrides config based on user input and updates the config table
local function Rundi_set()
	-- Prompt user for a filetype, compiler, and other options
	local filetype = vim.fn.input("Enter filetype (e.g., cpp, python, go, etc.): ")
	local compiler = vim.fn.input("Enter compiler for " .. filetype .. " (e.g., g++, python3, go build): ")
	local compiler_args = vim.fn.input("Enter compiler args (optional): ", "")
	local output_format = vim.fn.input("Enter output format (default: %:t:r): ", "%:t:r")

	-- Check if the filetype already exists in the config
	if not config.autocompile[filetype] then
		config.autocompile[filetype] = {}
	end

	-- Update the specific filetype with user inputs
	config.autocompile[filetype].compiler = compiler
	config.autocompile[filetype].compiler_args = compiler_args
	config.autocompile[filetype].output_format = output_format

	print("New configuration applied for filetype: " .. filetype)

	-- Autocompile using the new config
	Rundi()
end

-- Register the command :RundiSet to call the Rundi_set function
vim.api.nvim_create_user_command("RundiSet", Rundi_set, {})

-- Function to set key mappings
local function set_keymap()
	vim.api.nvim_set_keymap("n", config.keymap, ":Rundi<CR>", { noremap = true, silent = config.silent })
end

-- Register the :rundi command to trigger the compilation
vim.api.nvim_create_user_command("Rundi", Rundi, {})

-- Register the :Rundi-set command to override config and create a JSON file
vim.api.nvim_create_user_command("RundiSet", Rundi_set, {})

-- Setup function for plugin configuration
local function setup(user_config)
	for key, value in pairs(user_config) do
		if config[key] ~= nil then
			config[key] = value
		end
	end
	set_keymap() -- Set the key mapping during setup
end

return {
	setup = setup,
}
