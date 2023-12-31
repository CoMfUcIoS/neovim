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
    "hrsh7th/cmp-path",
    lazy = false,
  },
  {
    "hrsh7th/cmp-buffer",
    lazy = false,
  },
  {
    "zbirenbaum/copilot.lua",
    cmd = "Copilot",
    event = "InsertEnter",
    config = function()
      local copilot = require("copilot")
      copilot.setup({
        suggestion = { enabled = false },
        panel = { enabled = false },
      })
    end,
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
          completeopt = "menuone,noinsert,noselect",
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
          ["<C-j>"] = cmp.mapping({
            i = cmp.mapping.select_next_item({ behavior = cmp.SelectBehavior.Select }),
          }),
          ["<C-k>"] = cmp.mapping({
            i = cmp.mapping.select_prev_item({ behavior = cmp.SelectBehavior.Select }),
          }),
          ["<C-e>"] = cmp.mapping({
            i = cmp.mapping.abort(),
          }),
          ["<CR>"] = cmp.mapping({
            i = cmp.mapping.confirm({ select = true }),
          }),
          -- ["<C-Space>"] = cmp.mapping({
          --   i = cmp.mapping.complete(),
          -- }),
        },
        sources = {
          { name = "copilot" },
          { name = "luasnip" },
          { name = "nvim_lsp" },
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
        },
        sorting = {
          priority_weight = 2,
          comparators = {
            require("copilot_cmp.comparators").prioritize,
            require("copilot_cmp.comparators").score,

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
          format = lspkind.cmp_format({
            mode = "symbol_text", -- options: 'text', 'text_symbol', 'symbol_text', 'symbol'
            maxwidth = 50,  -- prevent the popup from showing more than provided characters (e.g 50 will not show more than 50 characters)

            -- The function below will be called before any actual modifications from lspkind
            -- so that you can provide more controls on popup customization. (See [#30](https://github.com/onsails/lspkind-nvim/pull/30))
            before = function(entry, vim_item)
              vim_item.kind = lspkind.presets.default[vim_item.kind]

              local menu = source_mapping[entry.source.name]

              if entry.source.name == "copilot" then
                if entry.completion_item.data ~= nil and entry.completion_item.data.detail ~= nil then
                  menu = entry.completion_item.data.detail .. " " .. menu
                end
                vim_item.kind = ""
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
          ghost_text = true,
        },
      })
      vim.api.nvim_set_hl(0, "CmpItemKindCopilot", { fg = "#6CC644" })
    end,
  },
}
