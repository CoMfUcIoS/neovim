return {
	"bigfile",
	dir = "~/.config/nvim/lua/bigfile",
	config = function()
		require("bigfile").setup({
			notify = true,
		})
	end,
}
