return {
	"stevearc/conform.nvim",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local conform = require("conform")

		conform.setup({
			formatters_by_ft = {
				javascript = { "prettierd" },
				typescript = { "prettierd" },
				javascriptreact = { "prettierd" },
				typescriptreact = { "prettierd" },
				-- goimports fixes imports, gofumpt is the stricter gofmt.
				-- golangci-lint is a linter (see golangci_lint_ls) and
				-- gomodifytags needs args -- neither is a conform formatter.
				go = { "goimports", "gofumpt" },
				svelte = { "prettierd" },
				css = { "prettierd" },
				html = { "prettierd" },
				json = { "prettierd" },
				yaml = { "yamlfix" },
				markdown = { "prettierd" },
				graphql = { "prettierd" },
				liquid = { "prettierd" },
				lua = { "stylua" },
				-- python = { "isort", "black" },
				rust = { "rustfmt" },
				ruby = { "rubocop" },
				sh = { "shfmt" },
				puppet = { "puppet-lint" },
				php = { "php_cs_fixer", "phpstan" },
				clojure = { "cljfmt" },
			},
			format_on_save = {
				lsp_fallback = true,
				async = false,
				timeout_ms = 3000, -- was 300000: a 5-minute synchronous hang on save
			},
		})

		vim.keymap.set({ "n", "v" }, "<leader>mp", function()
			conform.format({
				lsp_fallback = true,
				async = false,
				timeout_ms = 1000,
			})
		end, { desc = "Format file or range (in visual mode)" })
	end,
}
