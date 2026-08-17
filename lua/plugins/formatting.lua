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
				-- Was commented out, so python had no formatter at all and
				-- format-on-save silently did nothing (pyright doesn't format).
				-- ruff covers both jobs black+isort did and is much faster;
				-- ruff_format is black-compatible. black and isort are still
				-- installed if you'd rather swap back.
				python = { "ruff_organize_imports", "ruff_format" },
				rust = { "rustfmt" },
				ruby = { "rubocop" },
				sh = { "shfmt" },
				puppet = { "puppet-lint" },
				-- phpstan was listed here: it's a static analyser, not a
				-- formatter — the same mistake golangci-lint was making for Go
				-- above. It's wired into nvim-lint instead (see linting.lua).
				php = { "php_cs_fixer" },
				java = { "google-java-format" },
				clojure = { "cljfmt" },
			},
			-- google-java-format defaults to Google style (2-space). Every Java repo in
			-- ~/Apps is 4-space with no formatter in the build, so --aosp keeps saves
			-- from reindenting whole files into review noise.
			formatters = {
				["google-java-format"] = { prepend_args = { "--aosp" } },
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
