return {
	lazy = false,
	"rest-nvim/rest.nvim",
	config = function()
		vim.api.nvim_create_autocmd("FileType", {
			pattern = { "json" },
			callback = function()
				vim.api.nvim_set_option_value("formatprg", "jq", { scope = "local" })
			end,
		})
		vim.api.nvim_create_autocmd("BufRead", {
			group = vim.api.nvim_create_augroup("detect_http", { clear = true }),
			desc = "Set filetype for http files",
			pattern = { ".http" },
			callback = function()
				vim.cmd("setfiletype http")
			end,
		})
	end,
	keys = {
		{ "<leader>rr", ":Rest run<CR>", desc = "Run Rest request under the cursor" },
		{ "<leader>ro", ":Rest open<CR>", desc = "Open Rest result pane" },
		{ "<leader>rp", ":Rest last<CR>", desc = "Run last Rest request" },
		{ "<leader>rl", ":Rest logs<CR>", desc = "Edit Rest logs file" },
		{ "<leader>rc", ":Rest cookies<CR>", desc = "Edit Rest cookies file" },
	},
}
