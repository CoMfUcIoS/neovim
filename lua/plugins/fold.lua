return {
	{
		"chrisgrieser/nvim-origami",
		event = "VeryLazy",
		opts = {
			useLspFoldsWithTreesitterFallback = {
				enabled = true,
				foldmethodIfNeitherIsAvailable = "indent", ---@type string|fun(bufnr: number): string
			},
			pauseFoldsOnSearch = true,
			foldtext = {
				enabled = true,
				padding = 3,
				lineCount = {
					template = "%d lines", -- `%d` is replaced with the number of folded lines
					hlgroup = "Comment",
				},
				diagnosticsCount = true, -- uses hlgroups and icons from `vim.diagnostic.config().signs`
				gitsignsCount = true, -- requires `gitsigns.nvim`
				disableOnFt = { "snacks_picker_input" }, ---@type string[]
			},
			autoFold = {
				enabled = true,
				kinds = { "comment", "imports" }, ---@type lsp.FoldingRangeKind[]
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
			vim.keymap.set("n", "<Left>", function()
				require("origami").h()
			end, { desc = "Close fold" })
			vim.keymap.set("n", "<Right>", function()
				require("origami").l()
			end, { desc = "Open fold" })
		end,
	},
}
