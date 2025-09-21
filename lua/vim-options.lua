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

-- Always enable wrap for normal buffers
vim.api.nvim_create_autocmd("BufWinEnter", {
	pattern = "*",
	callback = function()
		-- Only set wrap for normal buffers (not plugin/special windows)
		if vim.bo.buftype == "" then
			vim.opt_local.wrap = true
			vim.opt_local.linebreak = true
			vim.opt.textwidth = 0 -- Do not auto-insert line breaks
			vim.opt.wrapmargin = 0 -- No wrap margin
		end
	end,
})

opt.background = "dark"
opt.signcolumn = "yes"

--backspace settings
opt.backspace = "indent,eol,start"

-- Dynamically adjust wrapmargin to avoid minimap overlap
local function set_wrapmargin_for_minimap()
	-- Find minimap window (filetype = 'neominimap')
	local minimap_width = nil
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		local buf = vim.api.nvim_win_get_buf(win)
		local ft = vim.api.nvim_buf_get_option(buf, "filetype")
		if ft == "neominimap" then
			local width = vim.api.nvim_win_get_width(win)
			minimap_width = width
			break
		end
	end
	-- Only set wrapmargin for normal buffers
	if vim.bo.buftype == "" then
		if minimap_width then
			-- Set wrapmargin so wrapping occurs before minimap (plus 3 columns)
			vim.opt_local.wrapmargin = minimap_width + 3
		-- print('[wrapmargin] minimap width: ' .. minimap_width .. ', setting wrapmargin to ' .. (minimap_width + 3))
		else
			-- No minimap, reset wrapmargin
			vim.opt_local.wrapmargin = 0
			-- print('[wrapmargin] no minimap, setting wrapmargin to 0')
		end
	end
end

vim.api.nvim_create_autocmd({ "WinEnter", "WinClosed", "BufWinEnter" }, {
	pattern = "*",
	callback = set_wrapmargin_for_minimap,
})

--clipboard settings
opt.clipboard = "unnamedplus"

--split settings
opt.splitright = true
opt.splitbelow = true

--no swap files
opt.swapfile = false
