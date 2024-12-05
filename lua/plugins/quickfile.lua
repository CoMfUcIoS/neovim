return {
	"quickfile",
	dir = vim.fn.stdpath("config") .. "/lua",
	config = function()
		require("quickfile").setup()
	end,
}
