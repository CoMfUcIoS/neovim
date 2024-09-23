return {
	"polarmutex/git-worktree.nvim",
	version = "^2",
	dependencies = { "nvim-telescope/telescope.nvim", "nvim-lua/plenary.nvim" },
	config = function()
		local telescope = require("telescope")
		telescope.load_extension("git_worktree")
		local Hooks = require("git-worktree.hooks")

		Hooks.register(Hooks.type.CREATE, function(path, prev_path)
			if _G.worktree_create_callback ~= nil then
				_G.worktree_create_callback(path, prev_path)
			else
				vim.notify("No git worktree callback", vim.log.levels.WARN)
			end
		end)

		Hooks.register(Hooks.type.SWITCH, function(path, prev_path)
			vim.notify("Moved:" .. prev_path .. "  ~>  " .. path)
		end)

		vim.keymap.set("n", "<leader>gw", function()
			require("telescope").extensions.git_worktree.git_worktree()
		end, { desc = "worktree_switch" })

		vim.keymap.set("n", "<leader>gW", function()
			require("telescope").extensions.git_worktree.create_git_worktree()
		end, { desc = "worktree_create" })
	end,
}
