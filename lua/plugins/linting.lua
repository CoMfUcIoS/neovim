return {
	"mfussenegger/nvim-lint",
	event = { "BufReadPre", "BufNewFile" },
	config = function()
		local lint = require("lint")
		local pattern = "^(%w+): (.+) on line (%d+) %(.+%)$"

		lint.linters.puppet_lint = {
			name = "puppet_lint",
			cmd = "puppet-lint",
			args = {},
			ignore_exitcode = true,
			parser = function(output, bufnr)
				local diagnostics = {}
				for _, line in ipairs(vim.split(output, "\n")) do
					local severity, message, line_number = line:match(pattern)
					if severity and message and line_number then
						table.insert(diagnostics, {
							bufnr = bufnr,
							lnum = tonumber(line_number) - 1,
							col = 0,
							severity = vim.diagnostic.severity[severity:upper()] or vim.diagnostic.severity.INFO,
							source = "puppet-lint",
							message = message,
						})
					end
				end
				return diagnostics
			end,
		}

		lint.linters_by_ft = {
			javascript = { "eslint_d" },
			typescript = { "eslint_d" },
			javascriptreact = { "eslint_d" },
			typescriptreact = { "eslint_d" },
			svelte = { "eslint_d" },
			python = { "pylint" },
			go = { "golangci-lint" },
			sh = { "shellcheck" },
			puppet = { "puppet_lint" },
			ruby = { "rubocop" },
			rust = { "cargo" },
			lua = { "luacheck" },
		}

		local lint_augroup = vim.api.nvim_create_augroup("lint", { clear = true })

		vim.api.nvim_create_autocmd({ "BufWritePost" }, {
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
