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
				"dockerls",
				"eslint",
				"jsonls",
				"cmake",
				"docker_compose_language_service",
				"dockerls",
				"gopls",
				"golangci_lint_ls",
				-- "grammarly",
				"harper_ls",
				"puppet",
				"rubocop",
				-- "ruby_lsp",
				"rust_analyzer",
				"ts_ls",
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
				"debugpy",
				"json-lsp",
				"firefox-debug-adapter",
				"php-debug-adapter",
				"ruff",
				"mypy",
				"black", -- python formatter
				"gofumpt", -- go formatter
				"goimports", -- go formatter
				"gomodifytags",
				"golines", -- go formatter
				"isort", -- python formatter
				"markdownlint", -- markdown linter
				"php-cs-fixer", -- php formatter
				"phpcs",
				"phpstan", -- php linter
				"prettierd", -- prettier formatter
				"prettier",
				"yamlfix", -- yaml formatter
				"stylua", -- lua formatter
				"isort", -- python formatter
				"black", -- python formatter
				"pylint",
				"eslint-lsp",
				"rubocop", -- ruby formatter
				"rufo", -- ruby formatter
				"shfmt", -- shell formatter
				"luacheck", -- lua linter
				"shellcheck", -- shell linter
				"clj-kondo", -- clojure linter
				"cljfmt", -- clojure formatter
			},
		})
	end,
}
