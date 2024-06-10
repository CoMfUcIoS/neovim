return {
	"numToStr/FTerm.nvim",
	config = function()
		require("FTerm").setup({
			blend = 5,
			dimensions = {
				height = 0.90,
				width = 0.90,
				x = 0.5,
				y = 0.5,
			},
		})
	end,
	keys = {
		{ "<leader>tt", "<cmd>lua require('FTerm').toggle()<cr>", desc = "Toggle Floating Terminal" },
	},
}
