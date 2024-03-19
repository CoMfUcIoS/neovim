return {
	"kdheepak/lazygit.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim", -- required
		"nvim-telescope/telescope.nvim", -- optional
	},
	config = function()
		require("telescope").load_extension("lazygit")
	end,
}
