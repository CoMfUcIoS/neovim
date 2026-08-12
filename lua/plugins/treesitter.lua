return {
	"nvim-treesitter/nvim-treesitter",

	lazy = false,
	build = ":TSUpdate",

	dependencies = {
		"windwp/nvim-ts-autotag",
	},

	config = function()
		require("nvim-treesitter").setup({
			install_dir = vim.fn.stdpath("data") .. "/site",
		})

		require("nvim-treesitter").install({
			"json",
			"go",
			"javascript",
			"typescript",
			"tsx",
			"yaml",
			"php",
			"html",
			"css",
			"prisma",
			"markdown",
			"markdown_inline",
			"svelte",
			"graphql",
			"bash",
			"lua",
			"vim",
			"dockerfile",
			"gitignore",
			"query",
			"vimdoc",
			"c",
			"rust",
			"puppet",
			"ruby",
			"diff",
			"regex",
			"http",
			"latex",
			"scss",
			"typst",
			"vue",
		})

		-- Enable Treesitter highlighting
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				pcall(vim.treesitter.start)
			end,
		})

		-- Enable Treesitter indentation
		vim.api.nvim_create_autocmd("FileType", {
			callback = function()
				local ok = pcall(function()
					vim.bo.indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
				end)

				if not ok then
					vim.bo.indentexpr = ""
				end
			end,
		})
	end,
}
