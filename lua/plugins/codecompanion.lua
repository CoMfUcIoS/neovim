local fmt = string.format
return {
	"olimorris/codecompanion.nvim",
	dependencies = {
		"nvim-lua/plenary.nvim",
		"nvim-treesitter/nvim-treesitter",
		{
			"MeanderingProgrammer/render-markdown.nvim",
			opts = {
				file_types = { "markdown", "codecompanion" },
			},
			ft = { "markdown", "codecompanion" },
		},
	},
	config = function()
		local codecompanion = require("codecompanion")
		local actions = require("codecompanion.helpers.actions")
		local adapters = require("codecompanion.adapters")
		local current_adapter_index = 1
		local adapter_names = { "copilot", "xai", "anthropic", "openrouter", "ollama_remote", "ollama" }

		_G.toggle_adapter = function()
			current_adapter_index = current_adapter_index % #adapter_names + 1
			local adapter_name = adapter_names[current_adapter_index]
			vim.notify("Switched to adapter: " .. adapter_name)
			vim.g.codecompanion_adapter = adapter_name
			vim.api.nvim_set_keymap(
				"n",
				"<leader>za",
				"<cmd>CodeCompanionChat " .. adapter_name .. "<cr>",
				{ noremap = true, silent = true }
			)
			vim.api.nvim_set_keymap(
				"v",
				"<leader>za",
				"<cmd>CodeCompanionChat " .. adapter_name .. "<cr>",
				{ noremap = true, silent = true }
			)
		end

		_G.show_current_adapter = function()
			local adapter_name = adapter_names[current_adapter_index]
			vim.notify("Current adapter: " .. adapter_name)
		end

		codecompanion.setup({
			prompt_library = {
				["Generate a Commitizen Convention Message"] = {
					strategy = "chat",
					description = "Generate a commit message",
					opts = {
						index = 10,
						is_default = true,
						is_slash_cmd = true,
						short_name = "commit",
						auto_submit = true,
					},
					prompts = {
						{
							role = "user",
							content = function()
								return fmt(
									[[Write commit message for the change with commitizen convention. Make sure the title has maximum 50 characters and message is wrapped at 72 characters. Wrap the whole message in code block with language gitcommit:

```diff
%s
```
]],
									vim.fn.system("git diff --no-ext-diff --staged")
								)
							end,
							opts = {
								contains_code = true,
							},
						},
					},
				},
				["Code Expert"] = {
					strategy = "chat",
					description = "Get some special advice from an LLM",
					opts = {
						mapping = "<leader>ze",
						modes = { "v" },
						short_name = "expert",
						auto_submit = true,
						stop_context_insertion = true,
						user_prompt = true,
					},
					prompts = {
						{
							role = "system",
							content = function(context)
								return "I want you to act as a senior "
									.. context.filetype
									.. " developer. I will ask you specific questions and I want you to return concise explanations and codebase examples."
							end,
						},
						{
							role = "user",
							content = function(context)
								local text = actions.get_code(context.start_line, context.end_line)
								return "I have the following code:\n\n```"
									.. context.filetype
									.. "\n"
									.. text
									.. "\n```\n\n"
							end,
							opts = {
								contains_code = true,
							},
						},
					},
				},
			},
			display = {
				chat = {
					show_settings = true,
				},
				action_palette = {
					provider = "telescope",
				},
			},
			schema = {
				model = {
					default = "claude-3.7-sonnet",
				},
			},
			adapters = {
				xai = function()
					return adapters.extend("xai", {
						name = "xai",
					})
				end,
				anthropic = function()
					return adapters.extend("anthropic", {
						name = "claude",
						max_tokens = { default = 4096 },
					})
				end,
				ollama_remote = function()
					return adapters.extend("ollama", {
						env = {
							name = "qwen2.5-coder:14b",
							url = "http://10.0.0.114:11434",
						},
						parameters = {
							sync = true,
						},
						schema = {
							model = {
								default = "qwen2.5-coder:14b",
							},
						},
					})
				end,
				ollama = function()
					return adapters.extend("ollama", {
						parameters = {
							sync = true,
						},
						schema = {
							model = {
								default = "deepseek-r1:32b",
							},
						},
					})
				end,
				openrouter = function()
					local openrouter_models = {
						"google/gemini-2.0-pro-exp-02-05:free",
						"deepseek/deepseek-r1:free",
						"google/gemini-2.0-flash-exp:free",
						"google/gemini-exp-1206:free",
						"meta-llama/llama-3.2-3b-instruct:free",
						"deepseek/deepseek-r1-distill-qwen-32b:free",
					}
					local current_openrouter_model_index = 1

					local function reload_openrouter_adapter()
						codecompanion.setup({
							adapters = {
								openrouter = function()
									return require("codecompanion.adapters").extend("openai_compatible", {
										env = {
											url = "https://openrouter.ai/api",
											api_key = vim.env.OPENROUTER_API_KEY,
											chat_url = "/v1/chat/completions",
											models_endpoint = "/v1/models",
										},
										schema = {
											model = {
												default = function()
													return vim.g.codecompanion_openrouter_model
												end,
											},
										},
										hooks = {
											before = {
												function(adapter)
													if adapter.name == "openrouter" then
														adapter.model = vim.g.codecompanion_openrouter_model
													end
												end,
											},
										},
									})
								end,
							},
						})
					end

					_G.toggle_openrouter_model = function()
						current_openrouter_model_index = current_openrouter_model_index % #openrouter_models + 1
						local model_name = openrouter_models[current_openrouter_model_index]
						vim.g.codecompanion_openrouter_model = model_name
						vim.notify("Switched to OpenRouter model: " .. model_name)
						reload_openrouter_adapter() -- Reload the adapter config
					end

					-- Initialize the model here
					vim.g.codecompanion_openrouter_model = openrouter_models[current_openrouter_model_index]

					vim.api.nvim_set_keymap(
						"n",
						"<leader>zm",
						"<cmd>lua toggle_openrouter_model()<cr>",
						{ noremap = true, silent = true, desc = "CodeCompanion Toggle OpenRouter Model" }
					)

					vim.api.nvim_set_keymap(
						"v",
						"<leader>zm",
						"<cmd>lua toggle_openrouter_model()<cr>",
						{ noremap = true, silent = true, desc = "CodeCompanion Toggle OpenRouter Model" }
					)

					return require("codecompanion.adapters").extend("openai_compatible", {
						env = {
							url = "https://openrouter.ai/api",
							api_key = vim.env.OPENROUTER_API_KEY,
							chat_url = "/v1/chat/completions",
							models_endpoint = "/v1/models",
						},
						schema = {
							model = {
								default = function()
									return vim.g.codecompanion_openrouter_model
								end,
							},
						},
						hooks = {
							before = {
								function(adapter)
									if adapter.name == "openrouter" then
										adapter.model = vim.g.codecompanion_openrouter_model
									end
								end,
							},
						},
					})
				end,
			},
		})

		local keymaps = {
			{ "n", "<C-a>", "<cmd>CodeCompanionActions<cr>", "" },
			{ "v", "<C-a>", "<cmd>CodeCompanionActions<cr>", "" },
			{ "n", "<leader>zz", "<cmd>Telescope codecompanion<cr>", "CodeCompanion" },
			{ "v", "<leader>zz", "<cmd>Telescope codecompanion<cr>", "CodeCompanion" },
			{ "n", "<leader>zT", "<cmd>lua show_current_adapter()<cr>", "CodeCompanion: Show Current Adapter" },
			{ "v", "<leader>zT", "<cmd>lua show_current_adapter()<cr>", "CodeCompanion: Show Current Adapter" },
			{ "n", "<leader>zt", "<cmd>lua toggle_adapter()<cr>", "CodeCompanion: Toggle Adapter" },
			{ "v", "<leader>zt", "<cmd>lua toggle_adapter()<cr>", "CodeCompanion: Toggle Adapter" },
			{ "v", "ga", "<cmd>CodeCompanionChat Add<cr>", "" },
		}
		for _, keymap in ipairs(keymaps) do
			vim.api.nvim_set_keymap(
				keymap[1],
				keymap[2],
				keymap[3],
				{ noremap = true, silent = true, desc = keymap[4] }
			)
		end

		-- Set initial keymap for <leader>za
		local function codecompanion_chat_with_openrouter_model()
			return "<cmd>CodeCompanionChat openrouter<cr>"
		end
		vim.api.nvim_set_keymap(
			"n",
			"<leader>za",
			codecompanion_chat_with_openrouter_model(),
			{ noremap = true, silent = true, desc = "CodeCompanionChat openrouter" }
		)
		vim.api.nvim_set_keymap(
			"v",
			"<leader>za",
			codecompanion_chat_with_openrouter_model(),
			{ noremap = true, silent = true, desc = "CodeCompanionChat openrouter" }
		)

		vim.cmd([[cab cc CodeCompanion]])
	end,
}
