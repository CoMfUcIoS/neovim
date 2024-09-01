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
		{ "<leader>lh", "<cmd>Octo issue list<CR>", desc = "Octo: List issues" },
		{ "<leader>lp", "<cmd>Octo pr list<CR>", desc = "Octo: List pull requests" },
		{ "<leader>lP", "<cmd>Octo pr list --mine<CR>", desc = "Octo: List my pull requests" },
		{ "<leader>lH", "<cmd>Octo issue list --mine<CR>", desc = "Octo: List my issues" },
		{ "<leader>lC", "<cmd>Octo issue list --closed<CR>", desc = "Octo: List closed issues" },
		{ "<leader>lM", "<cmd>Octo issue list --merged<CR>", desc = "Octo: List merged issues" },
		{
			"<leader>lR",
			"<cmd>Octo issue list --review-requested<CR>",
			desc = "Octo: List issues with review requests",
		},
		{ "<leader>lA", "<cmd>Octo issue list --assignee<CR>", desc = "Octo: List issues assigned to me" },
		{ "<leader>lL", "<cmd>Octo issue list --label<CR>", desc = "Octo: List issues by label" },
		{ "<leader>lS", "<cmd>Octo issue list --search<CR>", desc = "Octo: List issues by search" },
		{ "<leader>lT", "<cmd>Octo issue list --mine --label<CR>", desc = "Octo: List my issues by label" },
		{ "<leader>lW", "<cmd>Octo issue list --mine --search<CR>", desc = "Octo: List my issues by search" },
		{
			"<leader>lB",
			"<cmd>Octo issue list --mine --label --search<CR>",
			desc = "Octo: List my issues by label and search",
		},
		{ "<leader>lO", "<cmd>Octo issue list --org<CR>", desc = "Octo: List issues in organization" },
		{ "<leader>lG", "<cmd>Octo issue list --org --label<CR>", desc = "Octo: List issues in organization by label" },
		{
			"<leader>lQ",
			"<cmd>Octo issue list --org --search<CR>",
			desc = "Octo: List issues in organization by search",
		},
		{
			"<leader>lY",
			"<cmd>Octo issue list --org --label --search<CR>",
			desc = "Octo: List issues in organization by label and search",
		},
		{ "<leader>lN", "<cmd>Octo issue list --org --mine<CR>", desc = "Octo: List my issues in organization" },
		{
			"<leader>lZ",
			"<cmd>Octo issue list --org --mine --label<CR>",
			desc = "Octo: List my issues in organization by label",
		},
		{
			"<leader>lX",
			"<cmd>Octo issue list --org --mine --search<CR>",
			desc = "Octo: List my issues in organization by search",
		},
		{
			"<leader>lV",
			"<cmd>Octo issue list --org --mine --label --search<CR>",
			desc = "Octo: List my issues in organization by label and search",
		},
		{ "<leader>lD", "<cmd>Octo issue list --org --closed<CR>", desc = "Octo: List closed issues in organization" },
	},
}
