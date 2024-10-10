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
				log_level = vim.log.levels.INFO,
				consumers = {},
				icons = {
					passed = "✔",
					running = "⟳",
					failed = "✖",
					skipped = "➜",
					unknown = "?",
				},
				highlights = {
					passed = "NeotestPassed",
					running = "NeotestRunning",
					failed = "NeotestFailed",
					skipped = "NeotestSkipped",
					unknown = "NeotestUnknown",
				},
				floating = {
					border = "rounded",
					max_height = 0.9,
					max_width = 0.9,
					options = {},
				},
				strategies = {
					integrated = {
						width = 120,
						height = 40,
					},
				},
				run = {
					enabled = true,
				},
				summary = {
					enabled = true,
					animated = true,
					follow = true,
					expand_errors = true,
					mappings = {
						expand = "zo",
						expand_all = "zO",
						output = "zo",
						short = "zO",
						attach = "a",
						jumpto = "j",
						stop = "s",
						run = "r",
						debug = "d",
						mark = "m",
						run_marked = "R",
						debug_marked = "D",
						clear_marked = "c",
						target = "t",
						clear_target = "T",
						next_failed = "n",
						prev_failed = "p",
						watch = "w",
					},
					open = "botright split | resize 10",
					count = true,
				},
				output = {
					enabled = true,
					open_on_run = "short",
				},
				output_panel = {
					enabled = true,
					open = "botright split | resize 10",
				},
				quickfix = {
					enabled = true,
					open = true,
				},
				status = {
					enabled = true,
					virtual_text = true,
					signs = true,
				},
				state = {
					enabled = true,
				},
				watch = {
					enabled = true,
					symbol_queries = {},
				},
				diagnostic = {
					enabled = true,
					severity = vim.diagnostic.severity.ERROR,
				},
				projects = {},
			})
		end,
	},
}
