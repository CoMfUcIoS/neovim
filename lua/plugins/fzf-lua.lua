return {
	"ibhagwan/fzf-lua",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	-- $TMPDIR on macOS is ~50 chars, so fzf-lua's own socket name blows past the
	-- 104-byte unix path limit. Claim g:fzf_lua_server first with a short path.
	init = function()
		vim.g.fzf_lua_server = vim.fn.serverstart(
			vim.fn.stdpath("cache") .. "/fzf-lua." .. vim.fn.getpid()
		)
	end,
	opts = {},
}
