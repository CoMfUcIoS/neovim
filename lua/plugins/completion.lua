return {
	{
		"L3MON4D3/LuaSnip",
		lazy = false,
		version = "v2.*",
		build = "make install_jsregexp",
		dependencies = {
			"rafamadriz/friendly-snippets",
			"saadparwaiz1/cmp_luasnip",
		},
		config = function()
			require("luasnip.loaders.from_vscode").lazy_load()
		end,
	},
	{
		"hrsh7th/cmp-nvim-lsp",
		config = true,
	},
	{
		"hrsh7th/cmp-path",
		lazy = false,
	},
	{
		"hrsh7th/cmp-buffer",
		lazy = false,
	},
	{
		"supermaven-inc/supermaven-nvim",
		opts = {
			log_level = "warn",
			disable_keymaps = true,
			disable_inline_completion = true,
			condition = function()
				return false
			end,
		},
	},
	{
		"folke/lazydev.nvim",
	},
	-- {
	-- 	"zbirenbaum/copilot.lua",
	-- 	cmd = "Copilot",
	-- 	event = "InsertEnter",
	-- 	opts = {
	-- 		suggestion = { enabled = false },
	-- 		panel = { enabled = false },
	-- 		filetypes = {
	-- 			markdown = true,
	-- 			help = true,
	-- 		},
	-- 	},
	-- },
	-- {
	-- 	"Exafunction/codeium.nvim",
	-- 	dependencies = {
	-- 		"nvim-lua/plenary.nvim",
	-- 		"hrsh7th/nvim-cmp",
	-- 	},
	-- 	config = function()
	-- 		require("codeium").setup({})
	-- 	end,
	-- },
	-- {
	-- 	"zbirenbaum/copilot-cmp",
	-- 	opts = {},
	-- },
	{
		"hrsh7th/nvim-cmp",
		lazy = false,
		config = function()
			local lspkind = require("lspkind")
			local cmp = require("cmp")
			local luasnip = require("luasnip")
			local source_mapping = {
				buffer = "[Buffer]",
				nvim_lsp = "[LSP]",
				nvim_lua = "[Lua]",
				path = "[Path]",
			}
			local has_words_before = function()
				if vim.api.nvim_buf_get_option(0, "buftype") == "prompt" then
					return false
				end
				local line, col = unpack(vim.api.nvim_win_get_cursor(0))
				return col ~= 0
					and vim.api.nvim_buf_get_text(0, line - 1, 0, line - 1, col, {})[1]:match("^%s*$") == nil
			end

			cmp.setup({
				completion = {
					autocomplete = {
						cmp.TriggerEvent.TextChanged,
						cmp.TriggerEvent.InsertEnter,
					},
					completeopt = "menu,menuone,preview,noinsert,noselect",
					-- keyword_length = 0,
				},
				window = {
					documentation = cmp.config.window.bordered(),
					completion = cmp.config.window.bordered(),
				},
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				mapping = {
					-- ["<Tab>"] = cmp.mapping(function(fallback)
					--   if luasnip.expand_or_jumpable() then
					--     luasnip.expand_or_jump()
					--   elseif cmp.visible() then
					--     cmp.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace })
					--   else
					--     fallback()
					--   end
					-- end, { "i", "s" }),
					["<Tab>"] = vim.schedule_wrap(function(fallback)
						if luasnip.expand_or_jumpable() and has_words_before() then
							luasnip.expand_or_jump()
						elseif cmp.visible() and has_words_before() then
							cmp.confirm({ select = true, behavior = cmp.ConfirmBehavior.Replace })
						else
							fallback()
						end
					end),
					["<C-e>"] = cmp.mapping({
						i = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
					}),
					["<C-i>"] = cmp.mapping({
						i = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
					}),
					["<C-x>"] = cmp.mapping({
						i = cmp.mapping.abort(),
					}),
					["<CR>"] = cmp.mapping({
						i = cmp.mapping.confirm({ select = true }),
					}),
					-- ["<C-Space>"] = cmp.mapping({
					--   i = cmp.mapping.complete(),
					-- }),
				},
				performance = {
					debounce = 0,
					throttle = 0,
					fetching_timeout = 200,
					confirm_resolve_timeout = 80,
					async_budget = 1,
					max_view_entries = 10,
				},
				sources = {
					{ name = "lazydev", group_index = 1 },
					{ name = "supermaven" },
					-- { name = "copilot" },
					-- { name = "codeium" },
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
					{ name = "path" },
					{
						name = "buffer",
						option = {
							-- complete from visible buffers
							get_bufnrs = function()
								local bufs = {}
								for _, win in ipairs(vim.api.nvim_list_wins()) do
									bufs[vim.api.nvim_win_get_buf(win)] = true
								end
								return vim.tbl_keys(bufs)
							end,
						},
					},
					{ name = "codecompanion" },
				},
				sorting = {
					priority_weight = 2,
					comparators = {
						-- require("copilot_cmp.comparators").prioritize,
						-- require("copilot_cmp.comparators").score,

						-- Below is the default comparitor list and order for nvim-cmp
						cmp.config.compare.offset,
						-- cmp.config.compare.scopes, --this is commented in nvim-cmp too
						cmp.config.compare.exact,
						cmp.config.compare.score,
						cmp.config.compare.recently_used,
						cmp.config.compare.locality,
						cmp.config.compare.kind,
						cmp.config.compare.sort_text,
						cmp.config.compare.length,
						cmp.config.compare.order,
					},
				},
				formatting = {
					fields = { "abbr", "kind", "menu" },
					expandable_indicator = true,
					format = lspkind.cmp_format({
						mode = "symbol_text", -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
						maxwidth = 50, -- prevent the popup from showing more than provided characters
						ellipsis_char = "...", -- the character to show ellipsis in place of omitted part (default is '...')
						before = function(entry, vim_item)
							vim_item.kind = lspkind.presets.default[vim_item.kind]

							local menu = source_mapping[entry.source.name]

							if entry.source.name == "supermaven" then
								-- if entry.source.name == "copilot" then
								-- if entry.source.name == "codeium" then
								if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
									menu = entry.completion_item.data.detail .. " " .. menu
								end
								vim_item.kind = ""
								-- vim_item.kind = ""
							end

							vim_item.menu = menu

							return vim_item
						end,
					}),
				},
				experimental = {
					view = {
						-- entries = true,
						entries = { name = "custom", selection_order = "near_cursor" },
					},
					ghost_text = false,
				},
			})
			-- vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
			vim.api.nvim_set_hl(0, "CmpItemKindSupermaven", { fg = "#6CC644" })
		end,
	},
}
