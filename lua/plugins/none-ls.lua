return {
	"jay-babu/mason-null-ls.nvim",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"williamboman/mason.nvim",
		"nvimtools/none-ls.nvim",
	},

	config = function()
		local null_ls = require("null-ls")
		null_ls.setup({
			-- default_timeout = 20000,
			sources = {
				null_ls.builtins.formatting.stylua,
				null_ls.builtins.formatting.prettier,
				null_ls.builtins.diagnostics.eslint_d,
				null_ls.builtins.diagnostics.rubocop,
				null_ls.builtins.formatting.rubocop,
				null_ls.builtins.formatting.golines,
				null_ls.builtins.formatting.black,
				null_ls.builtins.formatting.gofumpt,
				null_ls.builtins.formatting.goimports,
				null_ls.builtins.formatting.markdownlint,
				null_ls.builtins.diagnostics.markdownlint,
				null_ls.builtins.diagnostics.phpcs,
				null_ls.builtins.formatting.phpcbf,
			},
		})

		require("mason-null-ls").setup({
			automatic_installation = true,
		})

		vim.keymap.set("n", "<leader>gf", function()
			vim.lsp.buf.format({ timeout_ms = 20000 })
		end, {})
	end,
}
