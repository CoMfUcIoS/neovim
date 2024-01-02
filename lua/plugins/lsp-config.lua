return {
  {
    "williamboman/mason.nvim",
    lazy = false,
    opts = {
      ui = {
        icons = {
          package_installed = "✓",
          package_pending = "➜",
          package_uninstalled = "✗",
        },
      },
    },
  },
  {
    "williamboman/mason-lspconfig.nvim",
    lazy = false,
    opts = {
      auto_install = true,
    },
  },
  {
    "neovim/nvim-lspconfig",
    lazy = false,
    config = function()
      local capabilities = require("cmp_nvim_lsp").default_capabilities()

      local lspconfig = require("lspconfig")
      lspconfig.tsserver.setup({
        capabilites = capabilities,
      })
      lspconfig.html.setup({
        capabilites = capabilities,
      })
      lspconfig.cmake.setup({
        capabilites = capabilities,
      })
      lspconfig.rubocop.setup({
        capabilites = capabilities,
      })
      lspconfig.prismals.setup({
        capabilites = capabilities,
      })
      lspconfig.golangci_lint_ls.setup({
        capabilites = capabilities,
      })
      lspconfig.dockerls.setup({
        capabilites = capabilities,
      })
      lspconfig.docker_compose_language_service.setup({
        capabilites = capabilities,
      })
      lspconfig.lua_ls.setup({
        capabilites = capabilities,
      })
      lspconfig.gopls.setup({
        capabilites = capabilities,
      })

      vim.keymap.set("n", "K", vim.lsp.buf.hover, {})
      vim.keymap.set("n", "<leader>gd", vim.lsp.buf.definition, {})
      vim.keymap.set("n", "<leader>gr", vim.lsp.buf.references, {})
      vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, {})
    end,
  },
}
