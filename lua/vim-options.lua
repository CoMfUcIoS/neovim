vim.cmd("let g:netrw_liststyle = 3")

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end

vim.opt.rtp:prepend(lazypath)

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
