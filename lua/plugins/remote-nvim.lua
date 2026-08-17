-- Remote development over SSH — VSCode Remote-SSH architecture.
--
-- Installs Neovim on the remote host, copies this config over, runs a headless
-- server there, and attaches a local TUI via `nvim --server ... --remote-ui`.
-- Everything heavy (gopls, treesitter, git, grep) runs where the code is, which
-- is why it can't be half-broken the way a local-LSP-over-remote-files setup is.
--
-- Complements <leader>dR (dap-remote.lua): that keeps the editor local and moves
-- only the debugger. This moves the whole editor.
--
-- ⚠ The upstream repo was ARCHIVED on 2026-08-13. Pinned to the last release so
-- it can't drift. See CONFIG.md for the state of things and the exit plan.

return {
	"amitds1997/remote-nvim.nvim",
	-- Archived upstream: pin the last release rather than track a dead branch.
	tag = "v0.3.12",
	-- All three are already in this config for other reasons (plenary, nui via
	-- noice, telescope via neoclip/obsidian/overseer). Declared so lazy orders
	-- them correctly, not because they're new.
	dependencies = {
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		"nvim-telescope/telescope.nvim",
	},
	cmd = { "RemoteStart", "RemoteStop", "RemoteInfo", "RemoteCleanup", "RemoteConfigDel", "RemoteLog" },
	keys = {
		-- <leader>H* as a prefix, not a bare <leader>H: a complete mapping that
		-- is also a prefix stalls for timeoutlen. See CONFIG.md.
		{ "<leader>Hs", "<cmd>RemoteStart<cr>", desc = "Remote: start / connect session" },
		{ "<leader>Hq", "<cmd>RemoteStop<cr>", desc = "Remote: stop session" },
	},
	-- NOTE: setup is `M.setup = function(opts)` — a DOT function (init.lua:216).
	-- Upstream's README shows `require('remote-nvim'):setup()` with a colon,
	-- which passes the module table as `opts` and deep-merges its fields into
	-- the config. Call it with a dot.
	config = function()
		require("remote-nvim").setup({
			remote = {
				copy_dirs = {
					config = {
						base = vim.fn.stdpath("config"),
						-- An allowlist, NOT the default "*". "*" resolves to
						-- `base/.` (provider.lua:71-73), i.e. the whole
						-- directory — which for this repo means shipping .git
						-- (752K of 1.2M) to every remote on every connect.
						--
						-- `patches` is required, not optional: codecompanion's
						-- build runs `git apply ~/.config/nvim/patches/...`.
						dirs = {
							"init.lua",
							"lua",
							"lazy-lock.json",
							"patches",
						},
						compression = { enabled = true },
					},
				},
			},
		})
	end,
	-- Other defaults are left alone because they already do what we want:
	--   ssh_config.ssh_config_file_paths = { "$HOME/.ssh/config" }  (Include respected)
	--   client_callback                  = float_term running --remote-ui
}
