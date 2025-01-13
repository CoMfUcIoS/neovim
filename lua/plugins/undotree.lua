return {
	"mbbill/undotree",
	lazy = false, -- needs to be explicitly set, because of the keys property
	cmd = "UndotreeToggle",
	keys = {
		{
			"<leader>u",
			vim.cmd.UndotreeToggle,
			desc = "Toggle undotree",
		},
	},
}
