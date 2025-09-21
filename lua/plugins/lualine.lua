return {
	"nvim-lualine/lualine.nvim",
	config = function()
		require("lualine").setup({
			sections = {
				lualine_a = { "mode" },
				lualine_b = { "branch" },
				lualine_c = { "filename" },
				lualine_x = { "encoding", "fileformat", "filetype", function() return vim.g.mcphub_lualine_component and vim.g.mcphub_lualine_component() or "" end },
				lualine_y = { "progress" },
				lualine_z = { "location" },
			},
		})
	end,
}
