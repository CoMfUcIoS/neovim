return {
	"vague2k/huez.nvim",
	-- if you want registry related features, uncomment this
	import = "huez-manager.import",
	branch = "stable",
	event = "UIEnter",
	ensure = {},
	config = function()
		require("huez").setup({})
		local pickers = require("huez.pickers")

		vim.keymap.set("n", "<leader>co", pickers.themes, { desc = "Colorscheme" })
		vim.keymap.set("n", "<leader>coi", ":Huez<CR>", { desc = "Installed colorschemes" })
		vim.keymap.set("n", "<leader>cof", pickers.favorites, { desc = "Favorite colorschemes" })
		vim.keymap.set("n", "<leader>col", pickers.live, { desc = "Registry of colorschemes" })
		vim.keymap.set("n", "<leader>coe", pickers.ensured, { desc = "Ensured colorschemes" })
	end,
}
