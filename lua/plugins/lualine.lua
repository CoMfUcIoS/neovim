return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup({
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch" },
				lualine_c = { "filename" },
				lualine_x = { "encoding", "fileformat", "filetype", { require("mcphub.extensions.lualine") } },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		})
	end,
}
