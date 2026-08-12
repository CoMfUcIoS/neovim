-- Go / GoLand-parity layer.
-- gopls does the heavy lifting (analysis, refactors, codelens, inlay hints).
-- go.nvim is used ONLY as a command toolbox for the things gopls has no answer
-- for: struct tags, test generation, `if err != nil`, coverage gutters, alt-file.
return {
	{
		-- gopls settings. `init` so this lands before mason-lspconfig's
		-- automatic vim.lsp.enable() resolves the config at attach time.
		"neovim/nvim-lspconfig",
		init = function()
			vim.lsp.config("gopls", {
				settings = {
					gopls = {
						gofumpt = true,
						usePlaceholders = true, -- fills function args on completion
						completeUnimported = true, -- auto-import as you complete
						staticcheck = true, -- GoLand's inspections
						semanticTokens = true,
						symbolMatcher = "fuzzy",
						directoryFilters = { "-.git", "-node_modules", "-vendor", "-bazel-out" },
						analyses = {
							nilness = true,
							shadow = true,
							unusedparams = true,
							unusedwrite = true,
							unusedvariable = true,
							useany = true,
							fieldalignment = false, -- noisy; flip on for perf work
						},
						-- gutter actions: run test / run main / go mod tidy / upgrade dep
						codelenses = {
							generate = true,
							gc_details = true,
							test = true,
							tidy = true,
							run_govulncheck = true,
							upgrade_dependency = true,
							regenerate_cgo = true,
						},
						hints = {
							assignVariableTypes = true,
							compositeLiteralFields = true,
							compositeLiteralTypes = true,
							constantValues = true,
							functionTypeParameters = true,
							parameterNames = true,
							rangeVariableTypes = true,
						},
					},
				},
			})

			-- golangci-lint-langserver needs to be told how to run.
			vim.lsp.config("golangci_lint_ls", {
				init_options = {
					command = { "golangci-lint", "run", "--output.json.path=stdout", "--show-stats=false" },
				},
			})
		end,
	},
	{
		"ray-x/go.nvim",
		dependencies = { "ray-x/guihua.lua" },
		ft = { "go", "gomod", "gowork", "gotmpl" },
		opts = {
			-- Everything below is owned by another plugin already. go.nvim is a
			-- command toolbox here, nothing more.
			lsp_cfg = false, -- gopls configured above
			lsp_keymaps = false, -- lsp-config.lua owns keymaps
			lsp_inlay_hints = { enable = false }, -- native vim.lsp.inlay_hint
			lsp_document_formatting = false, -- conform.nvim owns formatting
			dap_debug = false, -- nvim-dap-go owns debugging
			dap_debug_gui = false,
			trouble = true,
			luasnip = true,
			icons = false,
			verbose = false,
		},
		keys = {
			-- struct tags (gomodifytags) -- GoLand's "Generate > Tags"
			{ "<leader>Gta", "<cmd>GoAddTag<cr>", ft = "go", desc = "Go: add struct tag" },
			{ "<leader>Gtr", "<cmd>GoRmTag<cr>", ft = "go", desc = "Go: remove struct tag" },
			{ "<leader>Gtc", "<cmd>GoClearTag<cr>", ft = "go", desc = "Go: clear struct tags" },
			-- test generation (gotests) -- GoLand's "Generate > Test for function"
			{ "<leader>Gtt", "<cmd>GoAddTest<cr>", ft = "go", desc = "Go: generate test for func" },
			{ "<leader>GtT", "<cmd>GoAddExpTest<cr>", ft = "go", desc = "Go: generate exported tests" },
			{ "<leader>GtA", "<cmd>GoAddAllTest<cr>", ft = "go", desc = "Go: generate all tests" },
			-- codegen
			{ "<leader>Ge", "<cmd>GoIfErr<cr>", ft = "go", desc = "Go: insert if err != nil" },
			{ "<leader>Gf", "<cmd>GoFillStruct<cr>", ft = "go", desc = "Go: fill struct" },
			{ "<leader>Gs", "<cmd>GoFillSwitch<cr>", ft = "go", desc = "Go: fill switch" },
			{ "<leader>Gi", "<cmd>GoImpl<cr>", ft = "go", desc = "Go: implement interface" },
			-- coverage gutters -- GoLand's coverage view
			{ "<leader>Gc", "<cmd>GoCoverage<cr>", ft = "go", desc = "Go: test coverage (gutter)" },
			{ "<leader>GC", "<cmd>GoCoverage -t<cr>", ft = "go", desc = "Go: coverage toggle" },
			-- module / project
			{ "<leader>Gm", "<cmd>GoModTidy<cr>", ft = "go", desc = "Go: mod tidy" },
			{ "<leader>Gg", "<cmd>GoGenerate<cr>", ft = "go", desc = "Go: generate" },
			{ "<leader>Gv", "<cmd>GoVulnCheck<cr>", ft = "go", desc = "Go: govulncheck" },
			-- alternate file -- GoLand's Ctrl+Shift+T (jump impl <-> test)
			{ "<leader>Ga", "<cmd>GoAlt!<cr>", ft = "go", desc = "Go: alternate file (impl/test)" },
			{ "<leader>GA", "<cmd>GoAltV!<cr>", ft = "go", desc = "Go: alternate file (vsplit)" },
		},
	},
}
