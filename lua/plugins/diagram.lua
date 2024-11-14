return {
	"3rd/diagram.nvim",
	config = function()
		require("diagram").setup({
			renderer_options = {
				mermaid = {
					background = nil,
					theme = nil,
					scale = 3,
				},
				plantuml = {
					charset = "utf-8",
				},
				d2 = {
					theme_id = 1,
				},
			},
		})
	end,
}
