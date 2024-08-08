return {
	"m4xshen/hardtime.nvim",
	dependencies = { "MunifTanjim/nui.nvim", "nvim-lua/plenary.nvim" },
	config = function()
		require("hardtime").setup({
			disabled_keys = {
				["<Up>"] = {},
				["<Down>"] = {},
				["<Left>"] = {},
				["<Right>"] = {},
			},
			restricted_keys = {
				["<Up>"] = { "n", "x" },
				["<Down>"] = { "n", "x" },
				["<Left>"] = { "n", "x" },
				["<Right>"] = { "n", "x" },
				["h"] = { "n", "x" },
				["j"] = { "n", "x" },
				["k"] = { "n", "x" },
				["l"] = { "n", "x" },
				["-"] = { "n", "x" },
				["+"] = { "n", "x" },
				["gj"] = { "n", "x" },
				["gk"] = { "n", "x" },
				["<CR>"] = { "n", "x" },
				["<C-M>"] = { "n", "x" },
				["<C-N>"] = { "n", "x" },
				["<C-P>"] = { "n", "x" },
			},
			disable_mouse = false,
		})
	end,
}
