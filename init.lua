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
require("claude-declaw").setup()

-- Are we the remote half of a remote-nvim.nvim session?
--
-- ponytail: this laptop is macOS and the remote boxes are Linux, so sysname is
-- a reliable one-liner with no env plumbing. Export NVIM_REMOTE=1 (or 0) to
-- override — needed only if you ever run this config on a local Linux machine.
if vim.env.NVIM_REMOTE ~= nil then
	vim.g.nvim_remote = vim.env.NVIM_REMOTE == "1"
else
	vim.g.nvim_remote = vim.uv.os_uname().sysname ~= "Darwin"
end

-- Plugins that are pointless or unbuildable on a remote box. Cutting these is
-- what removes cargo, yarn, ImageMagick/luarocks and pngpaste from the remote
-- dependency set — they are exactly the specs carrying those build steps.
local remote_disabled = {
	["image.nvim"] = true, -- cannot render through --remote-ui; wants magick + luarocks
	["diagram.nvim"] = true, -- renders via image.nvim, so useless without it
	["img-clip.nvim"] = true, -- clipboard images; wants pngpaste
	["codesnap.nvim"] = true, -- screenshots of code; Rust build
	["firenvim"] = true, -- browser integration; build drives a local browser
	["markdown-preview.nvim"] = true, -- opens a local browser; yarn build
	["obsidian.nvim"] = true, -- vault lives on the laptop
}

if vim.g.vscode then
	-- echo something dont leave this empty
	print("VSCode mode enabled")
else
	-- NOTE: everything must live in this ONE table. lazy.setup(spec, opts)
	-- discards its second argument whenever the first has a `spec` key
	-- (lazy/init.lua:32-38) — the git/checker/change_detection settings used to
	-- sit in a second table and were silently dead.
	require("lazy").setup({
		spec = {
			{
				import = "plugins",
			},
		},
		rocks = {
			hererocks = true,
		},
		defaults = {
			-- lazy's own documented hook for globally disabling plugins
			-- ("when running inside vscode for example"). A plugin's own `cond`
			-- takes precedence over this (lazy/core/meta.lua:267-272).
			cond = function(plugin)
				return not (vim.g.nvim_remote and remote_disabled[plugin.name])
			end,
		},
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
