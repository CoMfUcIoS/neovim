vim.g.loaded_perl_provider = 0

local function toggle_verbose()
	if vim.o.verbose == 0 then
		vim.o.verbosefile = vim.fn.expand("~/.vim_verbose.log")
		vim.o.verbose = 15
	else
		vim.o.verbose = 0
		vim.o.verbosefile = ""
	end
end

require("vim-options")
require("keymaps")
if vim.g.vscode then
	-- echo something dont leave this empty
	print("VSCode mode enabled")
else
	require("lazy").setup({
		{
			import = "plugins",
		},
	}, {
		git = {
			log = { "-8" }, -- show the last 8 commits
			timeout = 300, -- kill processes that take more than 5 minutes
			url_format = "https://github.com/%s.git",
			filter = true,
		},
		checker = {
			enabled = true,
			notify = false,
		},
		change_detection = {
			notify = false,
		},
	})
end

-- toggle_verbose()
--

-- Dynamically set python3_host_prog
local python3_host_prog = os.getenv("PYTHON3_HOST_PROG") or vim.fn.expand("~/.pyenv/versions/neovim3/bin/python")
vim.g.python3_host_prog = python3_host_prog
