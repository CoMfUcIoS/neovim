return {
	"okuuva/auto-save.nvim",
	lazy = false,
	config = function()
		local autoSave = require("auto-save")
		autoSave.setup({
			enabled = false,
			execution_message = {
				message = function()
					return ("AutoSave: saved at " .. vim.fn.strftime("%H:%M:%S"))
				end,
				dim = 0.18,
				cleaning_interval = 1250,
			},
			events = { "InsertLeave" },
			write_all_buffers = false,
			debounce_delay = 135,
		})

		vim.keymap.set(
			"n",
			"<leader>as",
			":ASToggle<CR>",
			{ desc = "Toggle auto save function", noremap = true, silent = true }
		)
	end,
}
