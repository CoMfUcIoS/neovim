return {
	"pwntester/octo.nvim",
	requires = {
		"nvim-lua/plenary.nvim",
		"nvim-telescope/telescope.nvim",
		-- OR 'ibhagwan/fzf-lua',
		"nvim-tree/nvim-web-devicons",
	},
	config = function()
		require("octo").setup()
	end,
	keys = {
		{ "<leader>lh", ":Octo issue list<CR>", desc = "Octo: List issues" },
		{ "<leader>lp", ":Octo pr list<CR>", desc = "Octo: List pull requests" },
		{ "<leader>lP", ":Octo pr list --mine<CR>", desc = "Octo: List my pull requests" },
		{ "<leader>lH", ":Octo issue list --mine<CR>", desc = "Octo: List my issues" },
		{ "<leader>lC", ":Octo issue list --closed<CR>", desc = "Octo: List closed issues" },
		{ "<leader>lM", ":Octo issue list --merged<CR>", desc = "Octo: List merged issues" },
		{ "<leader>lR", ":Octo issue list --review-requested<CR>", desc = "Octo: List issues with review requests" },
		{ "<leader>lA", ":Octo issue list --assignee<CR>", desc = "Octo: List issues assigned to me" },
		{ "<leader>lL", ":Octo issue list --label<CR>", desc = "Octo: List issues by label" },
		{ "<leader>lS", ":Octo issue list --search<CR>", desc = "Octo: List issues by search" },
		{ "<leader>lT", ":Octo issue list --mine --label<CR>", desc = "Octo: List my issues by label" },
		{ "<leader>lW", ":Octo issue list --mine --search<CR>", desc = "Octo: List my issues by search" },
		{
			"<leader>lB",
			":Octo issue list --mine --label --search<CR>",
			desc = "Octo: List my issues by label and search",
		},
		{ "<leader>lO", ":Octo issue list --org<CR>", desc = "Octo: List issues in organization" },
		{ "<leader>lG", ":Octo issue list --org --label<CR>", desc = "Octo: List issues in organization by label" },
		{ "<leader>lQ", ":Octo issue list --org --search<CR>", desc = "Octo: List issues in organization by search" },
		{
			"<leader>lY",
			":Octo issue list --org --label --search<CR>",
			desc = "Octo: List issues in organization by label and search",
		},
		{ "<leader>lN", ":Octo issue list --org --mine<CR>", desc = "Octo: List my issues in organization" },
		{
			"<leader>lZ",
			":Octo issue list --org --mine --label<CR>",
			desc = "Octo: List my issues in organization by label",
		},
		{
			"<leader>lX",
			":Octo issue list --org --mine --search<CR>",
			desc = "Octo: List my issues in organization by search",
		},
		{
			"<leader>lV",
			":Octo issue list --org --mine --label --search<CR>",
			desc = "Octo: List my issues in organization by label and search",
		},
		{ "<leader>lD", ":Octo issue list --org --closed<CR>", desc = "Octo: List closed issues in organization" },
	},
}
