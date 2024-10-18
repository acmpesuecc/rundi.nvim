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

-- Function that runs the autocompile and generates the executable
local function Rundi()
	-- Get the current file type (based on file extension)
	local filetype = vim.bo.filetype

	-- Check if the file type has autocompile configuration
	local options = config.autocompile[filetype]
	if options then
		-- Run the autocompile for the current filetype
		setup_autocompile(filetype, options)
		print("Autocompile executed for filetype: " .. filetype)
	else
		print("No autocompile configuration found for filetype: " .. filetype)
	end
end

-- Register the :rundi command to trigger the compilation and execution
vim.api.nvim_create_user_command("rundi", Rundi, {})

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
