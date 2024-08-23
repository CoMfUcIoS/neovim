vim.g.mapleader = " "

local keymap = vim.keymap

local getSelectedRange = function()
	local line1 = vim.fn.getpos("v")[2]
	local line2 = vim.fn.getpos(".")[2]
	if line1 > line2 then
		line1, line2 = line2, line1
	end
	return line1 .. "," .. line2 .. " "
end

keymap.set("n", "<leader>nh", ":nohl<CR>", { desc = "Clear highlights" })

-- increment/decrement numbers
keymap.set("n", "<leader>+", "<C-a>", { desc = "Increment number" }) -- increment
keymap.set("n", "<leader>-", "<C-x>", { desc = "Decrement number" }) -- decrement

-- window management
keymap.set("n", "<leader>sv", "<C-w>v", { desc = "Split window vertically" }) -- split window vertically
keymap.set("n", "<leader>sh", "<C-w>s", { desc = "Split window horizontally" }) -- split window horizontally
keymap.set("n", "<leader>s=", "<C-w>=", { desc = "Make splits equal size" }) -- make split windows equal width & height
keymap.set("n", "<leader>sx", "<cmd>close<CR>", { desc = "Close current split" }) -- close current split window
keymap.set("n", "<leader>sn", "<C-w>h", { desc = "Navigate to left split" })
keymap.set("n", "<leader>se", "<C-w>j", { desc = "Navigate to Upper split" })
keymap.set("n", "<leader>si", "<C-w>k", { desc = "Navigate to Lower split" })
keymap.set("n", "<leader>so", "<C-w>l", { desc = "Navigate to Right split" })

keymap.set("n", "<leader>to", "<cmd>tabnew<CR>", { desc = "Open new tab" }) -- open new tab
keymap.set("n", "<leader>tx", "<cmd>tabclose<CR>", { desc = "Close current tab" }) -- close current tab
keymap.set("n", "<leader>tn", "<cmd>tabn<CR>", { desc = "Go to next tab" }) --  go to next tab
keymap.set("n", "<leader>tp", "<cmd>tabp<CR>", { desc = "Go to previous tab" }) --  go to previous tab
keymap.set("n", "<leader>tf", "<cmd>tabnew %<CR>", { desc = "Open current buffer in new tab" }) --  move current buffer to new tab

keymap.set("n", "<leader>qx", "<cmd>qa<CR>", { desc = "Quit" }) -- quit
keymap.set("n", "<leader>qb", "<cmd>bd<CR>", { desc = "Close buffer" })
keymap.set("n", "<leader>qw", "<cmd>%bd<CR>", { desc = "Close all buffers" })

keymap.set("n", "<leader>qa", "", { desc = "Add Surround" })
keymap.set("n", '<leader>qa"', 'ciw""<ESC>P', { desc = "Surround word with double quotes" })
keymap.set("n", "<leader>qa'", "ciw''<ESC>P", { desc = "Surround word with single quotes" })
keymap.set("n", "<leader>qa(", "ciw()<ESC>P", { desc = "Surround word with parentheses" })
keymap.set("n", "<leader>qa[", "ciw[]<ESC>P", { desc = "Surround word with brackets" })
keymap.set("n", "<leader>qa{", "ciw{}<ESC>P", { desc = "Surround word with braces" })
keymap.set("n", "<leader>qc", "", { desc = "Change Surround" })
keymap.set("n", "<leader>qc'", "ciw<DEl><BS>''<ESC>P", { desc = "Change surround to '" })
keymap.set("n", '<leader>qc"', 'ciw<DEl><BS>""<ESC>P', { desc = 'Change surround to "' })

keymap.set("n", "<leader>mj", "<cmd>m .+1<CR>==", { desc = "Move line down" })
keymap.set("n", "<leader>mk", "<cmd>m .-2<CR>==", { desc = "Move line up" })
keymap.set("v", "<leader>me", "<cmd>m '>+1<CR>gv=gv", { desc = "Move Line Down" })
keymap.set("v", "<leader>mi", "<cmd>m '<-2<CR>gv=gv", { desc = "Move Line Up" })

keymap.set("n", "<leader>ss", "<cmd>s/\\v", { desc = "search and replace on line" })
keymap.set("n", "<leader>SS", "<cmd>%s/\\v", { desc = "search and replace in file" })

keymap.set("n", "<leader>yf", "<cmd>%y<cr>", { desc = "yank current file to the clipboard buffer" })
keymap.set("n", "<leader>df", "<cmd>%d_<cr>", { desc = "delete file content to black hole register" })
keymap.set("n", "<leader>sa", "ggVG", { desc = "select all" })

keymap.set({ "n", "v" }, "<leader>gbf", "<cmd>GBrowse<cr>", { desc = "Git browse current file in browser" })
keymap.set("n", "<leader>gbc", "<cmd>GBrowse!<cr>", { desc = "Copy URL to current file" })
keymap.set("v", "<leader>gbl", function()
	local range = getSelectedRange()
	vim.cmd(range .. "GBrowse ")
end, { desc = "Git browse current file and selected line in browser" })
keymap.set("v", "<leader>gbc", function()
	local range = getSelectedRange()
	vim.cmd(range .. "GBrowse!")
end, { desc = "Copy URL to current file with selected lines" })
