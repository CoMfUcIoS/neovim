return {
	"ravitemer/mcphub.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
	},
	cmd = "MCPHub", -- lazy load by default
	build = "bundled_build.lua", -- Bundles mcp-hub locally
	config = function()
		-- Set up the global lualine component for MCPHub (see :help mcphub-lualine)
		vim.g.mcphub_lualine_component = function()
			local ok, mcphub = pcall(require, "mcphub")
			if ok and mcphub.lualine_component then
				return mcphub.lualine_component()
			end
			return ""
		end

		require("mcphub").setup({
			use_bundled_binary = true, -- Use local binary
			-- Server configuration
			port = 37373, -- Port for MCP Hub Express API
			config = vim.fn.expand("~/.config/mcphub/servers.json"), -- Config file path

			native_servers = {}, -- add your native servers here
			-- Extension configurations
			auto_approve = false,
			extensions = {
				avante = {
					make_slash_commands = true, -- Enable slash commands for MCP server prompts
				},
				codecompanion = {
					show_result_in_chat = true, -- Show tool results in chat
					make_vars = true, -- Create chat variables from resources
					make_slash_commands = true, -- make /slash_commands from MCP server prompts
				},
			},

			-- UI configuration
			ui = {
				window = {
					width = 0.8, -- Window width (0-1 ratio)
					height = 0.8, -- Window height (0-1 ratio)
					border = "rounded", -- Window border style
					relative = "editor", -- Window positioning
					zindex = 50, -- Window stack order
				},
			},

			-- Event callbacks
			on_ready = function(hub) end, -- Called when hub is ready
			on_error = function(err) end, -- Called on errors

			-- Logging configuration
			log = {
				level = vim.log.levels.WARN, -- Minimum log level
				to_file = false, -- Enable file logging
				file_path = nil, -- Custom log file path
				prefix = "MCPHub", -- Log message prefix
			},
		})
	end,
}
