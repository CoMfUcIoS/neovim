return {
	"quickfile",
	dir = "~/.config/nvim/lua/quickfile",
	config = function()
		require("quickfile").setup()
	end,
}
