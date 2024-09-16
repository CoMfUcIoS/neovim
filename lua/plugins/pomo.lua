return {
	"comfucios/pomo.nvim",
	version = "*", -- Recommended, use latest release instead of latest commit
	lazy = true,
	cmd = { "TimerStart", "TimerRepeat", "TimerSession" },
	dependencies = {
		"rcarriga/nvim-notify",
	},
	config = function()
		local pomo = require("pomo")
		local telescope = require("telescope")

		pomo.setup({
			update_interval = 1000,
			sessions = {
				pomodoro = {
					{ name = "Work", duration = "25m" },
					{ name = "Short Break", duration = "5m" },
					{ name = "Work", duration = "25m" },
					{ name = "Short Break", duration = "5m" },
					{ name = "Work", duration = "25m" },
					{ name = "Long Break", duration = "20m" },
				},
			},
		})

		vim.keymap.set("n", "<leader>pt", function()
			telescope.extensions.pomodori.timers({})
		end, { desc = "Manage Pomodori Timers" })
	end,
	keys = {
		{ "<leader>pp", "<cmd>TimerPause<CR>", desc = "Pause timer" },
		{ "<leader>pr", "<cmd>TimerResume<CR>", desc = "Resume timer" },
		{ "<leader>ps", "<cmd>TimerSession pomodoro<CR>", desc = "Start timer session" },
	},
}
