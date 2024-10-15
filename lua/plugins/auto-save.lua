return {
	"okuuva/auto-save.nvim",
	lazy = false,
	config = function()
		local autoSave = require("auto-save")
		autoSave.setup({
			enabled = false,
			events = { "InsertLeave" },
			write_all_buffers = false,
			debounce_delay = 135,
		})

		vim.keymap.set(
			"n",
			"<leader>as",
			"<cmd>ASToggle<CR>",
			{ desc = "Toggle auto save function", noremap = true, silent = true }
		)
	end,
}
