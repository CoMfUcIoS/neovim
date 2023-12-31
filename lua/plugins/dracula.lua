return {
  {
    "maxmx03/dracula.nvim",
    lazy = false,
    name = "dracula",
    priority = 1000,
    config = function()
      local dracula = require("dracula")
      dracula.setup({
        soft = false,
        transparent = false,
        saturation = {
          enabled = false,
          amount = 10,
        },
        override = function(c)
          return {
            TelescopeResultsBorder = { fg = c.bgdark, bg = c.bgdark },
            TelescopeResultsNormal = { bg = c.bgdark },
            TelescopePreviewNormal = { bg = c.bg },
            TelescopePromptBorder = { fg = c.bgdark, bg = c.bgdark },
            TelescopeTitle = { fg = c.fg, bg = c.comment },
            TelescopePromptPrefix = { fg = c.purple },
            CmpItemKindText = { reverse = true },
            CmpItemKindMethod = { reverse = true },
            CmpItemKindFunction = { reverse = true },
            CmpItemKindConstructor = { reverse = true },
            CmpItemKindField = { reverse = true },
            CmpItemKindVariable = { reverse = true },
            CmpItemKindClass = { reverse = true },
            CmpItemKindInterface = { reverse = true },
            CmpItemKindModule = { reverse = true },
            CmpItemKindProperty = { reverse = true },
            CmpItemKindUnit = { reverse = true },
            CmpItemKindValue = { reverse = true },
            CmpItemKindEnum = { reverse = true },
            CmpItemKindKeyword = { reverse = true },
            CmpItemKindSnippet = { reverse = true },
            CmpItemKindColor = { reverse = true },
            CmpItemKindFile = { reverse = true },
            CmpItemKindReference = { reverse = true },
            CmpItemKindFolder = { reverse = true },
            CmpItemKindEnumMember = { reverse = true },
            CmpItemKindConstant = { reverse = true },
            CmpItemKindStruct = { reverse = true },
            CmpItemKindEvent = { reverse = true },
            CmpItemKindOperator = { reverse = true },
            CmpItemKindTypeParameter = { reverse = true },
            CmpItemKindBorder = { fg = c.bgdark, bg = c.bgdark },
          }
        end,
      })
      vim.cmd.colorscheme("dracula")
    end,
  },
}
