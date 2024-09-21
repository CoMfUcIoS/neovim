return {
	{
		"kevinhwang91/nvim-ufo",
		dependencies = { "nvim-treesitter/nvim-treesitter", "kevinhwang91/promise-async" },
		keys = {
			{ "zR", '<Cmd>lua require("ufo").openAllFolds()<CR>', "ufo: open all folds" },
			{ "zM", '<Cmd>lua require("ufo").closeAllFolds()<CR>', "ufo: close all folds" },
			{ "zK", '<Cmd>lua require("ufo").peekFoldedLinesUnderCursor()<CR>', "ufo: preview fold" },
		},
		opts = function()
			require("ufo").setup({
				open_fold_hl_timeout = 0,
				preview = {
					win_config = {
						winhighlight = "NormalFloat:FloatBorder,FloatBorder:FloatBorder",
					},
				},
				enable_get_fold_virt_text = true,
			})
		end,
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
