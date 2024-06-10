vim.cmd("let g:netrw_liststyle = 3")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end

local opt = vim.opt

opt.rtp:prepend(lazypath)

opt.relativenumber = true
opt.number = true

--tabs and identation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true

-- searce settings
opt.ignorecase = true
opt.smartcase = true

opt.cursorline = true

-- colorscheme
opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

--backspace settings
opt.backspace = "indent,eol,start"

--clipboard settings
opt.clipboard = "unnamedplus"

--split settings
opt.splitright = true
opt.splitbelow = true

--no swap files
opt.swapfile = false
