return {
	{
		"chrisgrieser/nvim-origami",
		event = "VeryLazy",
		opts = {
			useLspFoldsWithTreesitterFallback = true,
			pauseFoldsOnSearch = true,
			foldtext = {
				enabled = true,
				padding = 3,
				lineCount = {
					template = "%d lines",
					hlgroup = "Comment",
				},
				diagnosticsCount = true,
				gitsignsCount = true,
			},
			autoFold = {
				enabled = true,
				kinds = { "comment", "imports" },
			},
			foldKeymaps = {
				setup = false, -- we'll set custom keymaps below
				hOnlyOpensOnFirstColumn = false,
			},
			signs = { open = "", closed = "" },
		},
		init = function()
			vim.opt.foldlevel = 99
			vim.opt.foldlevelstart = 99
			vim.keymap.set("n", "<Left>", function() require("origami").h() end, { desc = "Close fold" })
			vim.keymap.set("n", "<Right>", function() require("origami").l() end, { desc = "Open fold" })
		end,
	},
}
