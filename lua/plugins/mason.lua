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

		-- Remote profile: the languages actually worked on remotely are
		-- Go, PHP, TS/JS and Java, plus the infra formats (json/yaml/docker/sh)
		-- and lua for editing this config. What's dropped is whole languages that
		-- aren't used there — Ruby, Python, Rust, Puppet, Clojure — which is what
		-- keeps the ruby/python/rust toolchains off the remote.
		--
		-- Framework-specific servers (tailwindcss, svelte, graphql, emmet_ls,
		-- prismals) and cmake/harper/markdown_oxide are also skipped; all are one
		-- `:Mason` away if a remote repo turns out to need them.
		local remote_servers = {
			-- Go
			"gopls",
			"golangci_lint_ls",
			-- TS / JS
			"ts_ls",
			"eslint",
			-- PHP
			"intelephense",
			-- Java (started by nvim-jdtls, not automatic_enable — see java.lua)
			"jdtls",
			-- Python
			"pyright",
			-- web + infra + this config
			"html",
			"cssls",
			"jsonls",
			"dockerls",
			"docker_compose_language_service",
			"lua_ls",
		}
		local remote_tools = {
			-- Go
			"delve",
			"golangci-lint",
			"gofumpt",
			"goimports",
			"gomodifytags",
			"gotests",
			"impl",
			"iferr",
			"golines",
			-- PHP
			"php-debug-adapter",
			"php-cs-fixer",
			"phpcs",
			"phpstan",
			-- TS / JS
			"prettierd",
			"eslint-lsp",
			-- vscode-js-debug, prebuilt (see debugging.lua)
			"js-debug-adapter",
			-- Java
			"java-debug-adapter",
			"java-test",
			"google-java-format",
			-- Python
			"debugpy",
			"ruff",
			"mypy",
			"pylint",
			-- shared
			"stylua",
			"shfmt",
			"shellcheck",
			"yamlfix",
			"markdownlint",
		}

		mason_lspconfig.setup({
			-- jdtls is installed here but started by nvim-jdtls (lua/plugins/java.lua),
			-- which attaches a per-project workspace and the java-debug/java-test
			-- bundles. Letting automatic_enable start it too would give two
			-- competing jdtls clients per buffer.
			automatic_enable = { exclude = { "jdtls" } },
			-- list of servers for mason to install
			ensure_installed = vim.g.nvim_remote and remote_servers or {
				"jdtls",
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
			ensure_installed = vim.g.nvim_remote and remote_tools or {
				-- java: debug + test bundles for jdtls, and the formatter
				"java-debug-adapter",
				"java-test",
				"google-java-format",
				"debugpy",
				"json-lsp",
				"js-debug-adapter", -- vscode-js-debug for node/chrome, prebuilt
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
				-- isort/black were listed twice; the first occurrences are above.
				-- Both are kept installed but conform uses ruff for python now.
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
