return {
	{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
	{
		"Bekaboo/dropbar.nvim",
		event = { "BufRead", "BufNewFile" },
		keys = {
			{
				"<leader>wo",
				function()
					require("dropbar.api").pick()
				end,
				desc = "winbar: pick",
			},
		},
		config = function()
			local opts = {
				general = {
					update_interval = 0,
					attach_events = {
						"OptionSet",
						"BufWinEnter",
						"BufWritePost",
						"BufEnter",
					},
					icons = {
						kinds = {
							symbols = vim.tbl_map(function(value)
								return value .. " "
							end, require("lspkind").symbol_map),
						},
					},
					menu = {
						win_configs = {
							col = function(menu)
								return menu.prev_menu and menu.prev_menu._win_configs.width + 1 or 0
							end,
						},
					},
				},
			}
			require("dropbar").setup(opts)
		end,
	},
}
