return {
  "pocco81/auto-save.nvim",
  lazy = false,
  config = function()
    local autoSave = require("auto-save")
    autoSave.setup({
      enabled = true,
      execution_message = {
        message = function()
          return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
        end,
        dim = 0.18,
        cleaning_interval = 1250,
      },
      events = { "InsertLeave"},
      write_all_buffers = false,
      debounce_delay = 135,
    })
  end,
}
