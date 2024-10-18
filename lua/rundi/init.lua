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

-- Utility function to write table to a JSON file
local function Write_to_json_file(filepath, table_data)
	local json = vim.fn.json_encode(table_data)
	local file = io.open(filepath, "w")
	if file then
		file:write(json)
		file:close()
	else
		print("Failed to write to " .. filepath)
	end
end

-- Utility function to read JSON file and decode into Lua table
local function Read_json_file(filepath)
	local file = io.open(filepath, "r")
	if not file then
		print("Could not read JSON file: " .. filepath)
		return nil
	end

	local content = file:read("*a")
	file:close()
	return vim.fn.json_decode(content)
end

local function setup_autocompile(filetype, options)
	local ac = config.autocompile[filetype]
	if ac then
		local silent_option = config.silent and "<silent>" or ""
		local compiler_args = options.compiler_args and (" " .. options.compiler_args) or ""
		local output_flag = options.output_format and (" -o " .. options.output_format) or ""
		local execute_flag = options.output_format and (" && ./" .. options.output_format) or ""
		local input_file = ' "%"'

		if config.split_direction == "fullscreen" then
			vim.cmd([[ term ]] .. options.compiler .. compiler_args .. input_file .. output_flag .. execute_flag)
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

			vim.cmd(
				[[ ]]
					.. split_cmd
					.. [[ | term ]]
					.. options.compiler
					.. compiler_args
					.. input_file
					.. output_flag
					.. execute_flag
			)

			if config.persist_viewport and previous_buffer ~= 0 then
				vim.cmd("execute 'buffer ' .. " .. previous_buffer)
			end

			previous_buffer = current_buffer
		end
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

-- Function that overrides config based on user input and creates/reads JSON
local function Rundi_set()
	-- JSON file path to store custom config
	local json_filepath = vim.fn.stdpath("config") .. "/rundi_custom_config.json"

	-- Prompt user for a filetype, compiler, and other options
	local filetype = vim.fn.input("Enter filetype (e.g., cpp, python, go, etc.): ")
	local compiler = vim.fn.input("Enter compiler for " .. filetype .. " (e.g., g++, python3, go build): ")
	local compiler_args = vim.fn.input("Enter compiler args (optional): ", "")
	local output_format = vim.fn.input("Enter output format (default: %:t:r): ", "%:t:r")

	-- Prepare the new autocompile settings for the given filetype
	local new_config = {
		autocompile = config.autocompile, -- Start with existing autocompile settings
	}

	-- Update the specific filetype with user inputs
	new_config.autocompile[filetype] = {
		compiler = compiler,
		compiler_args = compiler_args,
		output_format = output_format,
	}

	-- Write new config to JSON
	Write_to_json_file(json_filepath, new_config)
	print("Custom config saved to: " .. json_filepath)

	-- Load custom config from JSON
	local loaded_config = Read_json_file(json_filepath)
	if loaded_config then
		-- Apply the new config
		config = loaded_config
		print("New configuration applied for filetype: " .. filetype)
	else
		print("Error: Failed to load custom configuration.")
	end

	-- Autocompile using the new config
	Rundi()
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
end

return {
	setup = setup,
}
