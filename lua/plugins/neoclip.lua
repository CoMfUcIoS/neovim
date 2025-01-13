return {
	"AckslD/nvim-neoclip.lua",
	cmd = "Neoclip",
	requires = {
		{ "kkharji/sqlite.lua", module = "sqlite" },
		{ "nvim-telescope/telescope.nvim" },
	},
	config = function()
		require("neoclip").setup()
	end,
}
