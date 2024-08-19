vim.g.mapleader = " "

local keymap = vim.keymap

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

keymap.set("n", '<leader>qa"', 'ciw""<ESC>P', { desc = "Surround word with double quotes" })
keymap.set("n", "<leader>qa'", "ciw''<ESC>P", { desc = "Surround word with single quotes" })
keymap.set("n", "<leader>qa(", "ciw()<ESC>P", { desc = "Surround word with parentheses" })
keymap.set("n", "<leader>qa[", "ciw[]<ESC>P", { desc = "Surround word with brackets" })
keymap.set("n", "<leader>qa{", "ciw{}<ESC>P", { desc = "Surround word with braces" })
keymap.set("n", "<leader>qc'", "ciw<DEl><BS>''<ESC>P", { desc = "Change surround to '" })
keymap.set("n", '<leader>qc"', 'ciw<DEl><BS>""<ESC>P', { desc = 'Change surround to "' })
