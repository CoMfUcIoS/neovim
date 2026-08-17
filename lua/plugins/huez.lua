return {
	"vague2k/huez.nvim",
	-- if you want registry related features, uncomment this
	import = "huez-manager.import",
	branch = "stable",
	event = "UIEnter",
	ensure = {},
	config = function()
		require("huez").setup({
			-- Where huez lands when it has no saved theme — a fresh clone, or a
			-- remote-nvim host (huez keeps its state in stdpath("data")/huez,
			-- which isn't in the remote copy allowlist). Default is "default",
			-- i.e. plain Neovim. See lua/plugins/monokai.lua.
			fallback = "monokai",
			--
			-- theme_config_module = "modules.themes" was removed: there is no
			-- lua/modules/ directory, so huez logged "directory not found to load
			-- themes from" and loaded no theme configs. The message is invisible
			-- because huez defaults suppress_messages = true, so it was silently
			-- doing nothing. Re-add it alongside a real lua/modules/themes/ tree
			-- if you ever want per-theme setup hooks.
		})
		local pickers = require("huez.pickers")

		vim.keymap.set("n", "<leader>cop", pickers.themes, { desc = "Colorscheme" })
		vim.keymap.set("n", "<leader>coi", "<cmd>Huez<CR>", { desc = "Installed colorschemes" })
		vim.keymap.set("n", "<leader>cof", pickers.favorites, { desc = "Favorite colorschemes" })
		vim.keymap.set("n", "<leader>col", pickers.live, { desc = "Registry of colorschemes" })
		vim.keymap.set("n", "<leader>coe", pickers.ensured, { desc = "Ensured colorschemes" })
	end,
}
