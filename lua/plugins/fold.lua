return {
	{
		"kevinhwang91/nvim-ufo",
		event = "VeryLazy",
		dependencies = { "nvim-treesitter/nvim-treesitter", "kevinhwang91/promise-async" },
		keys = {
			{ "zR", '<Cmd>lua require("ufo").openAllFolds()<CR>', "ufo: open all folds" },
			{ "zM", '<Cmd>lua require("ufo").closeAllFolds()<CR>', "ufo: close all folds" },
			{ "zK", '<Cmd>lua require("ufo").peekFoldedLinesUnderCursor()<CR>', "ufo: preview fold" },
		},
		opts = {
			filetype_exclude = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason" },
		},
		config = function()
			vim.o.foldcolumn = "1" -- '0' is not bad
			vim.o.foldlevel = 99 -- Using ufo provider need a large value, feel free to decrease the value
			vim.o.foldlevelstart = 99
			vim.o.foldenable = true

			require("ufo").setup({
				open_fold_hl_timeout = 150,
				preview = {
					win_config = {
						winhighlight = "NormalFloat:FloatBorder,FloatBorder:FloatBorder",
					},
				},
				enable_get_fold_virt_text = true,
				provider_selector = function(bufnr, filetype, buftype)
					return { "treesitter", "indent" }
				end,
			})
		end,
	},
	{
		"chrisgrieser/nvim-origami",
		event = "VeryLazy",
		keys = {
			{
				"<Left>",
				function()
					require("origami").h()
				end,
				desc = "Close fold",
			},
			{
				"<Right>",
				function()
					require("origami").l()
				end,
				desc = "Open fold",
			},
		},
		opts = { setupFoldKeymaps = false },
	},
	{
		"gh-liu/fold_line.nvim",
		event = "VeryLazy",
		init = function()
			vim.g.fold_line_char_open_start = "╭"
			vim.g.fold_line_char_open_end = "╰"
		end,
	},
}
