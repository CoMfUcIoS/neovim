return {
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
}
