return {
	"bigfile",
	dir = vim.fn.stdpath("config") .. "/lua",
	config = function()
		require("bigfile").setup({
			notify = true,
		})
	end,
}
