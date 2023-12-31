local function border(hl_name)
	return {
		{ "╭", hl_name },
		{ "─", hl_name },
		{ "╮", hl_name },
		{ "│", hl_name },
		{ "╯", hl_name },
		{ "─", hl_name },
		{ "╰", hl_name },
		{ "│", hl_name },
	}
end

return {
	{
		"L3MON4D3/LuaSnip",
		lazy = false,
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
		lazy = false,
		config = true,
	},
  {
      "zbirenbaum/copilot-cmp",
      config = function()
          require("copilot_cmp").setup()
      end,
  },
	{
		"hrsh7th/nvim-cmp",
		lazy = false,
		config = function()
      local lspkind = require('lspkind')
			local cmp = require("cmp")
			cmp.setup({
				window = {
					completion = {
						border = border("CmpItemKindBorder"),
					},
					documentation = {
						border = border("CmpItemKindBorder"),
					},
				},
				-- window = {
				--   documentation = cmp.config.window.bordered(),
				--   completion = cmp.config.window.bordered(),
				-- },
				snippet = {
					expand = function(args)
						require("luasnip").lsp_expand(args.body)
					end,
				},
				mapping = cmp.mapping.preset.insert({
					["<C-b>"] = cmp.mapping.scroll_docs(-4),
					["<C-f>"] = cmp.mapping.scroll_docs(4),
					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),
					["<CR>"] = cmp.mapping.confirm({ select = true }),
				}),
				sources = cmp.config.sources({
          { name = "copilot"},
					{ name = "nvim_lsp" },
					{ name = "luasnip" },
				}, {
					{ name = "buffer" },
				}),
        formatting = {
          format = lspkind.cmp_format({
      mode = "symbol",
      max_width = 50,
      symbol_map = { Copilot = "" }
    })
        }
			})
		end,
	},
}
