return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")

		lint.linters_by_ft = {
			python = { "pylint", "mypy" },
			-- go: handled by golangci_lint_ls (LSP). Running golangci-lint on
			-- every BufReadPost/BufWritePost too meant two slow full-package
			-- runs per save.
			--
			-- php: phpcs only. phpstan is installed and is the more thorough
			-- analyser, but it's slow enough on a real project that putting it on
			-- BufWritePost repeats the golangci-lint mistake above. Run it by hand:
			--   :lua require("lint").try_lint("phpstan")
			-- Type errors still surface live through intelephense.
			php = { "phpcs" },
			sh = { "shellcheck" },
			puppet = { "puppet-lint" },
			ruby = { "rubocop" },

			lua = { "luacheck" },
			clojure = { "clj-kondo" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, {
			group = lint_augroup,
			callback = function()
				lint.try_lint()
			end,
		})

		vim.keymap.set("n", "<leader>ll", function()
			lint.try_lint()
		end, { desc = "Trigger linting for current file" })
	end,
}
