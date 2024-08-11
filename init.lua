require("vim-options")
require("keymaps")
if vim.g.vscode then
	-- echo something dont leave this empty
	print("VSCode mode enabled")
else
	require("lazy").setup({ { import = "plugins" } }, {
		checker = {
			enabled = true,
			notify = false,
		},
		change_detection = {
			notify = false,
		},
	})
end
