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
				"docker_compose_language_service",
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
				-- go toolchain
				"delve", -- go debugger (dap-go had no dlv binary to talk to)
				"golangci-lint", -- the linter itself; golangci_lint_ls only wraps it
				"gofumpt", -- go formatter
				"goimports", -- go imports
				"gomodifytags", -- struct tags
				"gotests", -- table-driven test generation
				"impl", -- interface stub generation
				"iferr", -- if err != nil boilerplate
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
			},
		})
	end,
}
