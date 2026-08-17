-- Monokai — the default colorscheme.
--
-- Declared explicitly rather than left to huez. huez-manager's `import` builds
-- its theme specs from a runtime state file under stdpath("data")/huez, so a
-- theme picked in the huez UI exists only on the machine you picked it on: it
-- lands in lazy-lock.json but in none of the tracked spec files. On a fresh
-- clone — or on a remote-nvim host, where the data dir isn't copied — the spec
-- wouldn't exist, huez would find no saved theme, and you'd land on Neovim's
-- `default`.
--
-- Provides: monokai, monokai_pro, monokai_soda, monokai_ristretto.
-- Switch at runtime with <leader>cop (huez picker); huez persists the choice and
-- re-applies it on UIEnter, overriding the default set here.

return {
	"tanvirtin/monokai.nvim",
	lazy = false,
	priority = 1000, -- load before anything that reads highlight groups
	config = function()
		-- No `opts`/setup() call on purpose: lazy would invoke setup() and this
		-- theme is a plain vim colorscheme file. (huez-manager's import has the
		-- same FIXME for the same reason.)
		vim.cmd.colorscheme("monokai")
	end,
}
