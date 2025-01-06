return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		{
			-- Make sure to setup it properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "codecompanion" },
			},
			ft = { "markdown", "codecompanion" },
		},
	},
	config = function()
		require("codecompanion").setup({})

		local keymaps = {
			{ "n", "<C-a>", "<cmd>CodeCompanionActions<cr>" },
			{ "v", "<C-a>", "<cmd>CodeCompanionActions<cr>" },
			{ "n", "<leader>zb", "<cmd>CodeCompanionChat Toggle<cr>" },
			{ "v", "<leader>zb", "<cmd>CodeCompanionChat Toggle<cr>" },
			{ "v", "ga", "<cmd>CodeCompanionChat Add<cr>" },
		}

		for _, keymap in ipairs(keymaps) do
			vim.api.nvim_set_keymap(keymap[1], keymap[2], keymap[3], { noremap = true, silent = true })
		end

		-- Expand 'cc' into 'CodeCompanion' in the command line
		vim.cmd([[cab cc CodeCompanion]])
	end,
}
