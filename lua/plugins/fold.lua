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
		config = function()
			vim.o.foldcolumn = "1"
			vim.o.foldlevel = 99
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
				-- If you want to exclude filetypes, add this here:
				-- filetype_exclude = { "help", "alpha", "dashboard", "neo-tree", "Trouble", "lazy", "mason" },
			})
		end,
	},
	{
		"chrisgrieser/nvim-origami",
		version = "v1.9",
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
		config = function()
			require("origami").setup({
				setupFoldKeymaps = false,
				signs = { open = "", closed = "" },
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
