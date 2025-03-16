return {
	"yetone/avante.nvim",
	event = "VeryLazy",
	lazy = false,
	version = false, -- set this if you want to always pull the latest change
	keys = {
		{ "<leader>aT", "<cmd>AvanteToggleProvider<cr>", { desc = "Toggle Avante provider" } },
		{ "<leader>ap", "<cmd>AvanteProvider<cr>", { desc = "Show Avante provider" } },
		{ "<leader>am", "<cmd>AvanteToggleOpenRouterModel<cr>", { desc = "Toggle OpenRouter Model" } },
	},
	config = function()
		-- openrouter models
		local openrouter_models = {
			"google/gemini-2.0-pro-exp-02-05:free",
			"deepseek/deepseek-r1:free",
			"google/gemini-2.0-flash-exp:free",
			"google/gemini-exp-1206:free",
			"meta-llama/llama-3.2-3b-instruct:free",
			"deepseek/deepseek-r1-distill-qwen-32b:free",
		}

		local current_openrouter_model_index = 1

		-- Provider configurations
		local provider_configs = {
			copilot = {}, -- copilot doesn't need special config
			claude = {
				endpoint = "https://api.anthropic.com",
				model = "claude-3-5-sonnet-20241022",
				temperature = 0,
				max_tokens = 4096,
			},
			openrouter = {
				__inherited_from = "openai",
				endpoint = "https://openrouter.ai/api/v1/",
				api_key_name = "OPENROUTER_API_KEY",
				model = "google/gemini-2.0-pro-exp-02-05:free",
			},
		}

		-- Base configuration
		local opts = {

			provider = "copilot",
			behaviour = {
				auto_suggestions = false, -- Experimental stage
				auto_set_highlight_group = true,
				auto_set_keymaps = true,
				auto_apply_diff_after_generation = false,
				support_paste_from_clipboard = false,
				minimize_diff = true, -- Whether to remove unchanged lines when applying a code block
			},
			mappings = {
				ask = "<leader>aa", -- ask
				edit = "<leader>ae", -- edit
				refresh = "<leader>ar", -- refresh
			},
			dual_boost = {
				enabled = false,
				first_provider = "copilot",
				second_provider = "openrouter",
				prompt = "Based on the two reference outputs below, generate a response that incorporates elements from both but reflects your own judgment and unique perspective. Do not provide any explanation, just give the response directly. Reference Output 1: [{{provider1_output}}], Reference Output 2: [{{provider2_output}}]",
				timeout = 60000, -- Timeout in milliseconds
			},
			hints = { enabled = true },
		}

		-- Provider management functions
		local function notify_provider()
			vim.notify("Current provider: " .. opts.provider, vim.log.levels.INFO)
		end

		local function set_provider(provider_name)
			opts.provider = provider_name
			if provider_configs[provider_name] then
				if provider_name == "openrouter" then
					opts.vendors = {
						openrouter = provider_configs[provider_name],
					}
				else
					opts[provider_name] = provider_configs[provider_name]
				end
			end
			require("avante").setup(opts)
			notify_provider()
		end

		local function set_openrouter_model(model_name)
			provider_configs.openrouter.model = model_name
			if opts.provider == "openrouter" then
				set_provider("openrouter")
			end
		end

		local function toggle_openrouter_model()
			current_openrouter_model_index = (current_openrouter_model_index % #openrouter_models) + 1
			local next_model = openrouter_models[current_openrouter_model_index]
			set_openrouter_model(next_model)
			vim.notify("Current OpenRouter model: " .. next_model, vim.log.levels.INFO)
		end

		local function index_of(tbl, value)
			for i, v in ipairs(tbl) do
				if v == value then
					return i
				end
			end
			return nil
		end

		local function toggle_provider()
			local providers = { "copilot", "claude", "openrouter" }
			local current_index = index_of(providers, opts.provider)
			local next_index = (current_index % #providers) + 1
			local next_provider = providers[next_index]
			set_provider(next_provider)
		end

		-- Create commands
		vim.api.nvim_create_user_command("AvanteToggleProvider", toggle_provider, {})
		vim.api.nvim_create_user_command("AvanteProvider", notify_provider, {})
		vim.api.nvim_create_user_command("AvanteToggleOpenRouterModel", toggle_openrouter_model, {})

		-- Initial setup
		require("avante").setup(opts)
	end,
	build = "make BUILD_FROM_SOURCE=true",
	dependencies = {
		"stevearc/dressing.nvim",
		"nvim-lua/plenary.nvim",
		"MunifTanjim/nui.nvim",
		--- The below dependencies are optional,
		"nvim-tree/nvim-web-devicons", -- or echasnovski/mini.icons
		"zbirenbaum/copilot.lua", -- for providers='copilot'
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
