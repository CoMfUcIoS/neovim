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

		-- Every parser is compiled from C on install, so the remote set covers the
		-- languages actually worked on there — Go, PHP, TS/JS, Java — plus infra
		-- formats and lua for this config. Dropped: ruby, rust, python-adjacent,
		-- puppet, latex, typst, vue, prisma, svelte, scss.
		-- :TSInstall <lang> still works on demand.
		local remote_parsers = {
			-- Go
			"go",
			"gomod",
			"gosum",
			-- PHP
			"php",
			"phpdoc",
			-- TS / JS
			"typescript",
			"javascript",
			"tsx",
			-- Java (kotlin is for the build.gradle.kts Gradle DSL)
			"java",
			"kotlin",
			-- Python
			"python",
			-- web
			"html",
			"css",
			-- infra + this config
			"json",
			"yaml",
			"bash",
			"dockerfile",
			"sql",
			"lua",
			"markdown",
			"markdown_inline",
			"gitignore",
			"diff",
			"query",
			"vim",
			"vimdoc",
			"regex",
		}

		require("nvim-treesitter").install(vim.g.nvim_remote and remote_parsers or {
			-- java/python/gomod/gosum were missing from this list entirely; kotlin is
			-- for build.gradle.kts
			"java",
			"kotlin",
			"python",
			"gomod",
			"gosum",
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
