return {
	"polarmutex/git-worktree.nvim",
	version = "^2",
	dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	config = function()
		local Hooks = require("git-worktree.hooks")
		Hooks.register(Hooks.type.SWITCH, Hooks.builtins.update_current_buffer_on_switch)

		require("telescope").load_extension("git_worktree")

		vim.api.nvim_set_keymap(
			"n",
			"<leader>gn",
			[[:lua require('git-worktree').create_worktree(vim.fn.input('Worktree name: '), vim.fn.input('Branch name: '), vim.fn.input('Upstream: '))<CR>]],
			{ noremap = true, silent = true, desc = "Create worktree" }
		)

		vim.api.nvim_set_keymap(
			"n",
			"<leader>gd",
			[[:lua require('git-worktree').delete_worktree(vim.fn.input('Worktree name: '))<CR>]],
			{ noremap = true, silent = true, desc = "Delete worktree" }
		)

		vim.api.nvim_set_keymap(
			"n",
			"<leader>gs",
			[[:lua require('git-worktree').switch_worktree(vim.fn.input('Worktree name: '))<CR>]],
			{ noremap = true, silent = true, desc = "Switch worktree" }
		)

		vim.api.nvim_set_keymap(
			"n",
			"<leader>gw",
			":lua require('telescope').extensions.git_worktree.git_worktree()<CR>",
			{ noremap = true, silent = true, desc = "List Worktrees" }
		)
	end,
}
