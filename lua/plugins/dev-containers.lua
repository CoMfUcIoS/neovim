return {
	"https://codeberg.org/esensar/nvim-dev-container",
	dependencies = "nvim-treesitter/nvim-treesitter",
	config = function()
		require("devcontainer").setup({
			auto_install = true,
			auto_update = true,
		})
	end,
}
