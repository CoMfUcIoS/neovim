return {
	"folke/snacks.nvim",
	dependencies = {
		{
			"folke/todo-comments.nvim",
			optional = true,
			keys = {
				{
					"<leader>ft",
					function()
						Snacks.picker.todo_comments()
					end,
					desc = "Todo",
				},
				{
					"<leader>fT",
					function()
						Snacks.picker.todo_comments({ keywords = { "TODO", "FIX", "FIXME" } })
					end,
					desc = "Todo/Fix/Fixme",
				},
			},
		},
		{
			"folke/trouble.nvim",
			optional = true,
			specs = {
				"folke/snacks.nvim",
				opts = function(_, opts)
					return vim.tbl_deep_extend("force", opts or {}, {
						picker = {
							actions = require("trouble.sources.snacks").actions,
							win = {
								input = {
									keys = {
										["<C-t>"] = {
											"trouble_open",
											mode = { "n", "i" },
										},
									},
								},
							},
						},
					})
				end,
			},
		},
	},
	priority = 1000,
	lazy = false,
	---@type snacks.Config
	opts = {
		picker = {},
		bigfile = {
			enabled = true,
			notify = true, -- show notification when big file detected
			size = 1.5 * 1024 * 1024, -- 1.5MB
			-- Enable or disable features when big file detected
			---@param ctx {buf: number, ft:string}
			setup = function(ctx)
				vim.cmd([[NoMatchParen]])
				Snacks.util.wo(0, { foldmethod = "manual", statuscolumn = "", conceallevel = 0 })
				vim.b.minianimate_disable = true
				vim.schedule(function()
					vim.bo[ctx.buf].syntax = ctx.ft
				end)
			end,
		},
		dashboard = {
			enabled = true,
			width = 60,
			row = nil, -- dashboard position. nil for center
			col = nil, -- dashboard position. nil for center
			pane_gap = 4, -- empty columns between vertical panes
			autokeys = "1234567890abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ", -- autokey sequence
			-- These settings are used by some built-in sections
			preset = {
				-- Defaults to a picker that supports `fzf-lua`, `telescope.nvim` and `mini.pick`
				---@type fun(cmd:string, opts:table)|nil
				pick = nil,
				-- Used by the `keys` section to show keymaps.
				-- Set your custom keymaps here.
				-- When using a function, the `items` argument are the default keymaps.
				---@type snacks.dashboard.Item[]
				keys = {
					{ icon = " ", key = "f", desc = "Find File", action = ":lua Snacks.dashboard.pick('files')" },
					{ icon = " ", key = "n", desc = "New File", action = ":ene | startinsert" },
					{
						icon = " ",
						key = "g",
						desc = "Find Text",
						action = ":lua Snacks.dashboard.pick('live_grep')",
					},
					{
						icon = " ",
						key = "r",
						desc = "Recent Files",
						action = ":lua Snacks.dashboard.pick('oldfiles')",
					},
					{
						icon = " ",
						key = "c",
						desc = "Config",
						action = ":lua Snacks.dashboard.pick('files', {cwd = vim.fn.stdpath('config')})",
					},
					{ icon = " ", key = "s", desc = "Restore Session", action = "<cmd>SessionRestore<CR>" },
					{
						icon = "󰒲 ",
						key = "L",
						desc = "Lazy",
						action = ":Lazy",
						enabled = package.loaded.lazy ~= nil,
					},
					{
						icon = "",
						key = "M",
						desc = "Mason",
						action = ":Mason",
					},
					{
						icon = " ",
						desc = "Browse Repo",
						key = "b",
						action = function()
							Snacks.gitbrowse()
						end,
					},
					{
						icon = " ",
						desc = "Healthcheck",
						key = "H",
						action = ":checkhealth",
					},
					{ icon = " ", key = "q", desc = "Quit", action = ":qa" },
				},
				-- Used by the `header` section
				header = [[
 ▄▄·       • ▌ ▄ ·. ·▄▄▄▄• ▄▌ ▄▄· ▪        .▄▄ · 
▐█ ▌▪▪     ·██ ▐███▪▐▄▄·█▪██▌▐█ ▌▪██ ▪     ▐█ ▀. 
██ ▄▄ ▄█▀▄ ▐█ ▌▐▌▐█·██▪ █▌▐█▌██ ▄▄▐█· ▄█▀▄ ▄▀▀▀█▄
▐███▌▐█▌.▐▌██ ██▌▐█▌██▌.▐█▄█▌▐███▌▐█▌▐█▌.▐▌▐█▄▪▐█
·▀▀▀  ▀█▄▀▪▀▀  █▪▀▀▀▀▀▀  ▀▀▀ ·▀▀▀ ▀▀▀ ▀█▄▀▪ ▀▀▀▀ 
]],
			},
			-- item field formatters
			formats = {
				icon = function(item)
					if item.file and item.icon == "file" or item.icon == "directory" then
						return Snacks.dashboard.icon(item.file, item.icon)
					end
					return { item.icon, width = 2, hl = "icon" }
				end,
				footer = { "%s", align = "center" },
				header = { "%s", align = "center" },
				file = function(item, ctx)
					local fname = vim.fn.fnamemodify(item.file, ":~")
					fname = ctx.width and #fname > ctx.width and vim.fn.pathshorten(fname) or fname
					if #fname > ctx.width then
						local dir = vim.fn.fnamemodify(fname, ":h")
						local file = vim.fn.fnamemodify(fname, ":t")
						if dir and file then
							file = file:sub(-(ctx.width - #dir - 2))
							fname = dir .. "/…" .. file
						end
					end
					local dir, file = fname:match("^(.*)/(.+)$")
					return dir and { { dir .. "/", hl = "dir" }, { file, hl = "file" } } or { { fname, hl = "file" } }
				end,
			},

			sections = {
				{ section = "header" },
				{ section = "keys", gap = 1, padding = 1 },
				{ section = "startup" },
			},
		},
		notifier = {
			enabled = true,
			timeout = 3000,
		},
		quickfile = { enabled = true },
		statuscolumn = { enabled = true },
		words = { enabled = true },
		styles = {
			notification = {
				wo = { wrap = true }, -- Wrap notifications
			},
		},
	},
	keys = {
		{
			"<leader>.",
			function()
				Snacks.scratch()
			end,
			desc = "Toggle Scratch Buffer",
		},
		{
			"<leader>S",
			function()
				Snacks.scratch.select()
			end,
			desc = "Select Scratch Buffer",
		},
		{
			"<leader>nn",
			function()
				Snacks.notifier.show_history()
			end,
			desc = "Notification History",
		},
		{
			"<leader>bd",
			function()
				Snacks.bufdelete()
			end,
			desc = "Delete Buffer",
		},
		{
			"<leader>cR",
			function()
				Snacks.rename.rename_file()
			end,
			desc = "Rename File",
		},
		{
			"<leader>gbr",
			function()
				Snacks.gitbrowse()
			end,
			desc = "Git Browse",
		},
		{
			"<leader>hb",
			function()
				Snacks.git.blame_line()
			end,
			desc = "Git Blame Line",
		},
		{
			"<leader>gf",
			function()
				Snacks.lazygit.log_file()
			end,
			desc = "Lazygit Current File History",
		},
		{
			"<leader>gg",
			function()
				Snacks.lazygit()
			end,
			desc = "Lazygit",
		},
		{
			"<leader>gl",
			function()
				Snacks.lazygit.log()
			end,
			desc = "Lazygit Log (cwd)",
		},
		{
			"<leader>un",
			function()
				Snacks.notifier.hide()
			end,
			desc = "Dismiss All Notifications",
		},
		{
			"<leader>tg",
			function()
				Snacks.terminal()
			end,
			desc = "Toggle Terminal",
		},
		{
			"]]",
			function()
				Snacks.words.jump(vim.v.count1)
			end,
			desc = "Next Reference",
			mode = { "n", "t" },
		},
		{
			"[[",
			function()
				Snacks.words.jump(-vim.v.count1)
			end,
			desc = "Prev Reference",
			mode = { "n", "t" },
		},
		{
			"<leader>R",
			desc = "Current Repository README.md",
			function()
				Snacks.win({
					file = vim.fn.getcwd() .. "/README.md",
					width = 0.6,
					height = 0.6,
					wo = {
						spell = false,
						wrap = false,
						signcolumn = "yes",
						statuscolumn = " ",
						conceallevel = 3,
					},
				})
			end,
		},
		{
			"<leader>ff",
			function()
				Snacks.picker.files()
			end,
			desc = "Find Files",
		},
		{
			"<leader>fr",
			function()
				Snacks.picker.recent()
			end,
			desc = "Recent",
		},
		{
			"<leader>fl",
			function()
				Snacks.picker.lines()
			end,
			desc = "Buffer Lines",
		},
		{
			"<leader>fgb",
			function()
				Snacks.picker.grep_buffers()
			end,
			desc = "Grep Open Buffers",
		},
		{
			"<leader>fs",
			function()
				Snacks.picker.grep()
			end,
			desc = "Grep",
		},
		{
			"<leader>fw",
			function()
				Snacks.picker.grep_word()
			end,
			desc = "Visual selection or word",
			mode = { "n", "x" },
		},
		{
			"<leader>fb",
			function()
				Snacks.picker.buffers()
			end,
			desc = "Buffers",
		},
		{
			"<leader>fC",
			function()
				Snacks.picker.files({ cwd = vim.fn.stdpath("config") })
			end,
			desc = "Find Config File",
		},
		{
			"<leader>fgg",
			function()
				Snacks.picker.git_files()
			end,
			desc = "Find Git Files",
		},
		{
			"<leader>fgl",
			function()
				Snacks.picker.git_log()
			end,
			desc = "Git Log",
		},
		{
			"<leader>fgs",
			function()
				Snacks.picker.git_status()
			end,
			desc = "Git Status",
		},
		{
			"<leader>fd",
			function()
				Snacks.picker.diagnostics()
			end,
			desc = "Diagnostics",
		},
		{
			"<leader>fc",
			function()
				Snacks.picker.commands()
			end,
			desc = "Commands",
		},
		{
			"<leader>fk",
			function()
				Snacks.picker.keymaps()
			end,
			desc = "Keymaps",
		},
		{
			"gd",
			function()
				Snacks.picker.lsp_definitions()
			end,
			desc = "Goto Definition",
		},
		{
			"gr",
			function()
				Snacks.picker.lsp_references()
			end,
			nowait = true,
			desc = "References",
		},
		{
			"gI",
			function()
				Snacks.picker.lsp_implementations()
			end,
			desc = "Goto Implementation",
		},
		{
			"gy",
			function()
				Snacks.picker.lsp_type_definitions()
			end,
			desc = "Goto T[y]pe Definition",
		},
		{
			"<leader>fgs",
			function()
				Snacks.picker.lsp_symbols()
			end,
			desc = "LSP Symbols",
		},
	},
	init = function()
		vim.api.nvim_create_autocmd("User", {
			pattern = "VeryLazy",
			callback = function()
				-- Setup some globals for debugging (lazy-loaded)
				_G.dd = function(...)
					Snacks.debug.inspect(...)
				end
				_G.bt = function()
					Snacks.debug.backtrace()
				end
				vim.print = _G.dd -- Override print to use snacks for `:=` command

				-- Create some toggle mappings
				Snacks.toggle.option("spell", { name = "Spelling" }):map("<leader>us")
				Snacks.toggle.option("wrap", { name = "Wrap" }):map("<leader>uw")
				Snacks.toggle.option("relativenumber", { name = "Relative Number" }):map("<leader>uL")
				Snacks.toggle.diagnostics():map("<leader>ud")
				Snacks.toggle.line_number():map("<leader>ul")
				Snacks.toggle
					.option("conceallevel", { off = 0, on = vim.o.conceallevel > 0 and vim.o.conceallevel or 2 })
					:map("<leader>uc")
				Snacks.toggle.treesitter():map("<leader>uT")
				Snacks.toggle
					.option("background", { off = "light", on = "dark", name = "Dark Background" })
					:map("<leader>ub")
				Snacks.toggle.inlay_hints():map("<leader>uh")
			end,
		})
	end,
}
