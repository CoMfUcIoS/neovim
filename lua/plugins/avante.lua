return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	lazy = false,
	version = false, -- set this if you want to always pull the latest change
	keys = {
		{ "<leader>zt", "<cmd>AvanteToggleProvider<cr>", { desc = "Toggle Avante provider" } },
		{ "<leader>zp", "<cmd>AvanteProvider<cr>", { desc = "Show Avante provider" } },
	},
	config = function()
		local opts = {
			-- The default provider is "copilot"
			provider = "copilot",
			behaviour = {
				auto_suggestions = false, -- Experimental stage
				auto_set_highlight_group = true,
				auto_set_keymaps = true,
				auto_apply_diff_after_generation = false,
				support_paste_from_clipboard = false,
			},
			mappings = {
				ask = "<leader>za", -- ask
				edit = "<leader>ze", -- edit
				refresh = "<leader>zr", -- refresh
			},
		}

		local function notify_provider()
			vim.notify("Current provider: " .. opts.provider)
		end

		local function toggle_provider()
			if opts.provider == "copilot" then
				opts.provider = "claude"
				opts.claude = {
					endpoint = "https://api.anthropic.com",
					model = "claude-3-5-sonnet-20241022",
					temperature = 0,
					max_tokens = 4096,
				}
			else
				opts.provider = "copilot"
			end
			require("avante").setup(opts)
			notify_provider()
		end

		vim.api.nvim_create_user_command("AvanteToggleProvider", function()
			toggle_provider()
		end, {})

		vim.api.nvim_create_user_command("AvanteProvider", function()
			notify_provider()
		end, {})

		require("avante").setup(opts)
	end,
	build = "make BUILD_FROM_SOURCE=true",
	dependencies = {
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		{
			-- support for image pasting
			"HakonHarnes/img-clip.nvim",
			event = "VeryLazy",
			opts = {
				-- recommended settings
				default = {
					embed_image_as_base64 = false,
					prompt_for_file_name = false,
					drag_and_drop = {
						insert_mode = true,
					},
					-- required for Windows users
					use_absolute_path = true,
				},
			},
		},
		{
			-- Make sure to setup it properly if you have lazy=true
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "Avante" },
			},
			ft = { "markdown", "Avante" },
		},
	},
}
