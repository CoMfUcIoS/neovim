return {
	"echasnovski/mini.files",
	version = "*",
	config = function()
		require("mini.files").setup({
			window = {
				width = 40,
				height = 10,
				border = true,
				relative = "editor",
				row = 0,
				col = 0,
				preview = true,
			},
			list = {
				border = true,
			},
			mappings = {
				go_in_plus = "<CR>",
				go_out_plus = "<BACKSPACE>",
				reset = "r",
			},
		})
	end,
	keys = {
		{ "<leader>em", "<cmd>lua require('mini.files').open()<cr>" },
	},
}
