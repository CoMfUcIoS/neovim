return {
	"williamboman/mason.nvim",
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	opts = {
		ui = {
			icons = {
				package_installed = "✓",
				package_pending = "➜",
				package_uninstalled = "✗",
			},
		},
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
		})

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"cmake",
				"docker_compose_language_service",
				"dockerls",
				"golangci_lint_ls",
				"gopls",
				"grammarly",
				"puppet",
				"rubocop",
				"ruby_lsp",
				"rust_analyzer",
				"tsserver",
				"html",
				"cssls",
				"tailwindcss",
				"svelte",
				"lua_ls",
				"graphql",
				"emmet_ls",
				"prismals",
				"pyright",
				"markdown_oxide",
				"intelephense",
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"php-debug-adapter",
				"black", -- python formatter
				"gofumpt", -- go formatter
				"goimports", -- go formatter
				"golines", -- go formatter
				"golangci-lint", -- go linter
				"isort", -- python formatter
				"markdownlint", -- markdown linter
				"php-cs-fixer", -- php formatter
				"phpstan", -- php linter
				"prettier", -- prettier formatter
				"stylua", -- lua formatter
				"isort", -- python formatter
				"black", -- python formatter
				"pylint",
				"eslint_d",
				"rubocop", -- ruby formatter
				"rufo", -- ruby formatter
				"shfmt", -- shell formatter
				"luacheck", -- lua linter
				"shellcheck", -- shell linter
			},
		})
	end,
}
