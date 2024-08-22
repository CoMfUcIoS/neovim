return {
	"mistricky/codesnap.nvim",
	build = "make build_generator",
	keys = {
		{ "<leader>ci", "<Esc><cmd>CodeSnap<cr>", mode = "x", desc = "Save selected code snapshot into clipboard" },
		{ "<leader>cs", "<Esc><cmd>CodeSnapSave<cr>", mode = "x", desc = "Save selected code snapshot in ~/Pictures" },
		{
			"<leader>cc",
			"<Esc><cmd>CodeSnapASCII<cr>",
			mode = "x",
			desc = "Save selected code in ASCII fomat into clipboard",
		},
	},
	opts = {
		save_path = "~/Pictures",
		has_breadcrumbs = true,
		bg_theme = "bamboo",
	},
	config = function()
		require("codesnap").setup({
			has_breadcrumbs = true,
			show_workspace = true,
			has_line_number = true,
			bg_color = "#535c68",
			bg_x_padding = 10,
			bg_y_padding = 10,
			watermark = "",
			mac_window_bar = false,
		})
	end,
}
