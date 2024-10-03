return {
	"folke/noice.nvim",
	event = "VeryLazy",
	config = function()
		require("notify").setup({
			background_colour = "#000000",
			level = "info",
			timeout = 5000,
			max_width = 80,
			max_height = 20,
			stages = "fade_in_slide_out",
			icons = {
				ERROR = "",
				WARN = "",
				INFO = "",
				DEBUG = "",
				TRACE = "✎",
			},
			time_formats = {
				"%H:%M:%S",
				"%H:%M",
			},
			on_open = function() end,
			on_close = function() end,
			render = "default",
			minimum_width = 50,
			fps = 30,
			top_down = true,
		})
		require("noice").setup({
			lsp = {
				-- override markdown rendering so that **cmp** and other plugins use **Treesitter**
				override = {
					["vim.lsp.util.convert_input_to_markdown_lines"] = true,
					["vim.lsp.util.stylize_markdown"] = true,
					["cmp.entry.get_documentation"] = true, -- requires hrsh7th/nvim-cmp
				},
			},
			-- you can enable a preset for easier configuration
			presets = {
				bottom_search = true, -- use a classic bottom cmdline for search
				command_palette = true, -- position the cmdline and popupmenu together
				long_message_to_split = true, -- long messages will be sent to a split
				inc_rename = true, -- enables an input dialog for inc-rename.nvim
				lsp_doc_border = true, -- add a border to hover docs and signature help
			},
			-- add any options here
			routes = {
				{
					filter = {
						event = "msg_show",
						any = {
							{ find = "%d+L, %d+B" },
							{ find = "; after #%d+" },
							{ find = "; before #%d+" },
							{ find = "%d fewer lines" },
							{ find = "%d more lines" },
						},
					},
					opts = { skip = true },
				},
			},
		})
	end,
	dependencies = {
		-- if you lazy-load any plugin below, make sure to add proper `module="..."` entries
		"MunifTanjim/nui.nvim",
		-- OPTIONAL:
		-- "nvim-notify", -- is only needed, if you want to use the notification view.
		--   If not available, we use `mini` as the fallback
		"rcarriga/nvim-notify",
	},
}
