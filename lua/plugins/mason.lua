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
				"ruff-lsp",
				"pyright",
				"markdown_oxide",
				"intelephense",
				"json_lsp",
			},
		})

		mason_tool_installer.setup({
			ensure_installed = {
				"debugpy",
				"firefox-debug-adapter",
				"php-debug-adapter",
				"mypy",
				"black", -- python formatter
				"gomodifytags",
				"gofumpt", -- go formatter
				"goimports", -- go formatter
				"golines", -- go formatter
				"golangci-lint", -- go linter
				"isort", -- python formatter
				"markdownlint", -- markdown linter
				"php-cs-fixer", -- php formatter
				"phpstan", -- php linter
				"prettierd", -- prettier formatter
				"prettier",
				"yamlfix", -- yaml formatter
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
				"clj-kondo", -- clojure linter
				"cljfmt", -- clojure formatter
			},
		})
	end,
}
