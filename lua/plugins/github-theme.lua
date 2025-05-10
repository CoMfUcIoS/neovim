return {
	"projekt0n/github-nvim-theme",
	name = "github-theme",
	lazy = false, -- make sure we load this during startup if it is your main colorscheme
	priority = 1000, -- make sure to load this before all the other start plugins
	config = function()
		require("github-theme").setup({})

		local colorschemes = {
			{ cmd = "github_dark", name = "Github Dark" },
			{ cmd = "github_dark_default", name = "Github Dark Default" },
			{ cmd = "github_dark_dimmed", name = "Github Dark Dimmed" },
			{ cmd = "github_dark_high_contrast", name = "Github Dark High Contrast" },
			{ cmd = "github_dark_colorblind", name = "Github Dark Colorblind (Beta)" },
			{ cmd = "github_dark_tritanopia", name = "Github Dark Tritanopia (Beta)" },
			{ cmd = "github_light", name = "Github Light" },
			{ cmd = "github_light_default", name = "Github Light Default" },
			{ cmd = "github_light_high_contrast", name = "Github Light High Contrast" },
			{ cmd = "github_light_colorblind", name = "Github Light Colorblind (Beta)" },
			{ cmd = "github_light_tritanopia", name = "Github Light Tritanopia (Beta)" },
		}

		local current_index = 1

		vim.keymap.set("n", "<leader>cos", function()
			current_index = (current_index % #colorschemes) + 1
			local selected_colorscheme = colorschemes[current_index]
			vim.cmd("colorscheme " .. selected_colorscheme.cmd)
			vim.notify("Switched to colorscheme: " .. selected_colorscheme.name)
		end, { desc = "Cycle through GitHub colorschemes" })
	end,
}
