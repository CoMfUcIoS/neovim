return {
	lazy = false,
	"rest-nvim/rest.nvim",
	dependencies = { "nvim-neotest/nvim-nio", "manoelcampos/xml2lua" },
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
		vim.g.rest_nvim = {
			request = {
				skip_ssl_verification = true,
			},
		}
	end,
	keys = {
		{ "<leader>rr", "<cmd>Rest run<CR>", desc = "Run Rest request under the cursor" },
		{ "<leader>ro", "<cmd>Rest open<CR>", desc = "Open Rest result pane" },
		{ "<leader>rp", "<cmd>Rest last<CR>", desc = "Run last Rest request" },
		{ "<leader>rl", "<cmd>Rest logs<CR>", desc = "Edit Rest logs file" },
		{ "<leader>rc", "<cmd>Rest cookies<CR>", desc = "Edit Rest cookies file" },
	},
}
