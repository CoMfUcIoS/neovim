return {
	"joshuavial/aider.nvim",
	config = function()
		require("aider").setup({
			auto_manage_context = true,
			default_bindings = true,
			model = "xai/grok-beta",
		})
	end,
	keys = {
		{
			"<leader>aw",
			function()
				require("aider").AiderOpen(" --no-auto-commits --model xai/grok-beta")
			end,
			desc = "Aider Open",
		},
		{
			"<leader>ab",
			function()
				require("aider").AiderBackground()
			end,
			desc = "Aider Background",
		},
	},
}
