return {
	"alexghergh/nvim-tmux-navigation",
	config = function()
		require("nvim-tmux-navigation").setup({
			disable_when_zoomed = true, -- defaults to false
			keybindings = {
				left = "<M-Left>",
				down = "<M-Down>",
				up = "<M-Up>",
				right = "<M-Right>",
				last_active = "<M-\\>",
				next = "<M-Space>",
			},
		})
	end,
}
