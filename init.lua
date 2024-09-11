
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
			import = "plugins" 
		} 
	}, {
		checker = {
			enabled = true,
			notify = false,
		},
		change_detection = {
			notify = false,
		},
	})
end
