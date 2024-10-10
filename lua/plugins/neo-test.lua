return {
	{
		"nvim-neotest/neotest",
		lazy = true,
		dependencies = {
			"nvim-neotest/nvim-nio",
			"nvim-lua/plenary.nvim",
			"antoinemadec/FixCursorHold.nvim",
			"nvim-treesitter/nvim-treesitter",
			{ "fredrikaverpil/neotest-golang", version = "*" },
			"markemmons/neotest-deno",
			"olimorris/neotest-phpunit",
			{ "thenbe/neotest-playwright", dependencies = { "nvim-telescope/telescope.nvim" } },
			"olimorris/neotest-rspec",
			"marilari88/neotest-vitest",
			"nvim-neotest/neotest-jest",
		},
		config = function()
			require("neotest").setup({
				adapters = {
					require("neotest-golang"),
					require("neotest-vitest"),
					require("neotest-rspec"),
					require("neotest-deno"),
					require("neotest-phpunit"),
					require("neotest-playwright").adapter({
						options = {
							persist_project_selection = true,
							enable_dynamic_test_discovery = true,
						},
					}),
					require("neotest-jest")({
						jestCommand = "pnpm test --",
						jestConfigFile = "custom.jest.config.ts",
						env = { CI = true },
						cwd = function(path)
							return vim.fn.getcwd()
						end,
					}),
				},
			})
		end,
	},
}
