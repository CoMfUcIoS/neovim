local fmt = string.format

return {
	{
		"ravitemer/mcphub.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		build = "bundled_build.lua", -- Bundles `mcp-hub` binary along with the neovim plugin
		config = function()
			-- Prefer a system mcp-hub (npm global, as on the laptop), but fall
			-- back to the bundled binary the build step produces. Without this
			-- the remote gets cmd = "" from exepath and mcphub never starts,
			-- which takes codecompanion's mcphub extension down with it.
			local system_mcp_hub = vim.fn.exepath("mcp-hub")
			require("mcphub").setup({
				use_bundled_binary = system_mcp_hub == "",
				cmd = system_mcp_hub ~= "" and system_mcp_hub or nil,
			})
		end,
	},
	{
		"olimorris/codecompanion.nvim",
		build = "git apply ~/.config/nvim/patches/codecompanion.patch",
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-treesitter/nvim-treesitter",
			{
				"MeanderingProgrammer/render-markdown.nvim",
				opts = {
					file_types = { "markdown", "codecompanion" },
					latex = { enabled = false },
				},
				ft = { "markdown", "codecompanion" },
			},
		},
		config = function()
			local codecompanion = require("codecompanion")
			local adapters = require("codecompanion.adapters")

			-- Keep these two in sync: the index must point at "claude_code".
			local adapter_names = { "claude_code", "xai", "anthropic", "openrouter", "ollama_remote", "ollama" }
			local current_adapter_index = 1 -- claude_code is the default

			_G.toggle_adapter = function()
				current_adapter_index = current_adapter_index % #adapter_names + 1
				local adapter_name = adapter_names[current_adapter_index]

				vim.notify("Switched to adapter: " .. adapter_name)
				vim.g.codecompanion_adapter = adapter_name

				vim.api.nvim_set_keymap(
					"n",
					"<leader>za",
					"<cmd>CodeCompanionChat adapter=" .. adapter_name .. "<cr>",
					{ noremap = true, silent = true, desc = "CodeCompanionChat " .. adapter_name }
				)

				vim.api.nvim_set_keymap(
					"v",
					"<leader>za",
					"<cmd>CodeCompanionChat adapter=" .. adapter_name .. "<cr>",
					{ noremap = true, silent = true, desc = "CodeCompanionChat " .. adapter_name }
				)
			end

			_G.show_current_adapter = function()
				local adapter_name = adapter_names[current_adapter_index]
				vim.notify("Current adapter: " .. adapter_name)
			end

			codecompanion.setup({
				extensions = {
					mcphub = {
						callback = "mcphub.extensions.codecompanion",
						opts = {
							-- MCP Tools
							make_tools = true, -- Make individual tools (@server__tool) and server groups (@server) from MCP servers
							show_server_tools_in_chat = true, -- Show individual tools in chat completion (when make_tools=true)
							add_mcp_prefix_to_tool_names = false, -- Add mcp__ prefix (e.g `@mcp__github`, `@mcp__neovim__list_issues`)
							show_result_in_chat = true, -- Show tool results directly in chat buffer
							format_tool = nil, -- function(tool_name:string, tool: CodeCompanion.Agent.Tool) : string Function to format tool names to show in the chat buffer

							-- MCP Resources
							make_vars = true, -- Convert MCP resources to #variables for prompts

							-- MCP Prompts
							make_slash_commands = true, -- Add MCP prompts as /slash commands
						},
					},
				},

				strategies = {
					chat = {
						adapter = "claude_code",
					},
					inline = {
						adapter = "openrouter",
					},
				},

				-- strategies = {
				-- chat = {
				-- 	tools = {
				-- 		["mcp"] = {
				-- 			callback = function()
				-- 				return require("mcphub.extensions.codecompanion")
				-- 			end,
				-- 			description = "Call tools and resources from the MCP Servers",
				-- 		},
				-- 	},
				-- },
				-- },

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
									local lines = vim.api.nvim_buf_get_lines(
										context.bufnr,
										context.start_line - 1,
										context.end_line,
										false
									)

									local text = table.concat(lines, "\n")

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
						default = "claude-3.5-sonnet",
					},
				},

				adapters = {
					acp = {
						claude_code = function()
							return adapters.extend("claude_code", {
								-- codecompanion resolves an *unset* env var to its own name
								-- (adapters/utils/init.lua:330), so the adapter's auth handler
								-- exported the literal "CLAUDE_CODE_OAUTH_TOKEN" and the bridge
								-- sent it as a bearer token -> 401. Return nil instead so
								-- claude-agent-acp falls back to the Claude CLI login, and still
								-- pick the token up if one is ever exported.
								env = {
									CLAUDE_CODE_OAUTH_TOKEN = function()
										return vim.env.CLAUDE_CODE_OAUTH_TOKEN
									end,
								},
							})
						end,
					},

					http = {
						opts = {
							show_model_choices = true,
						},

						xai = function()
							return adapters.extend("xai", {
								name = "xai",
							})
						end,

						anthropic = function()
							return adapters.extend("anthropic", {
								name = "claude",
								max_tokens = {
									default = 4096,
								},
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
										default = "glm-4-32b-0414:q6_k",
									},
								},
							})
						end,

						openrouter = function()
							local openrouter_models = {
								"nvidia/nemotron-3-super-120b-a12b:free",
								"nvidia/nemotron-3-ultra-550b-a55b:free",
								"openrouter/owl-alpha",
								"poolside/laguna-m.1:free",
								-- "qwen/qwen3-next-80b-a3b-instruct:free",
								-- "google/gemini-2.0-pro-exp-02-05:free",
								-- "deepseek/deepseek-r1:free",
								-- "google/gemini-2.0-flash-exp:free",
								-- "google/gemini-exp-1206:free",
								-- "meta-llama/llama-3.2-3b-instruct:free",
								-- "deepseek/deepseek-r1-distill-qwen-32b:free",
							}

							local current_openrouter_model_index = 1

							-- Initialize selected OpenRouter model
							vim.g.codecompanion_openrouter_model = openrouter_models[current_openrouter_model_index]

							-- Expose a global toggle for OpenRouter model cycling
							_G.toggle_openrouter_model = function()
								current_openrouter_model_index = current_openrouter_model_index % #openrouter_models + 1

								local model_name = openrouter_models[current_openrouter_model_index]

								vim.g.codecompanion_openrouter_model = model_name
								vim.notify("Switched to OpenRouter model: " .. model_name)
							end

							-- Keymaps to toggle OpenRouter models
							vim.api.nvim_set_keymap("n", "<leader>zm", "<cmd>lua toggle_openrouter_model()<cr>", {
								noremap = true,
								silent = true,
								desc = "CodeCompanion Toggle OpenRouter Model",
							})

							vim.api.nvim_set_keymap("v", "<leader>zm", "<cmd>lua toggle_openrouter_model()<cr>", {
								noremap = true,
								silent = true,
								desc = "CodeCompanion Toggle OpenRouter Model",
							})

							return adapters.extend("openai_compatible", {
								name = "openrouter",
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
							})
						end,
					},
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

			-- Set initial adapter and keymap for <leader>za to OpenRouter
			vim.g.codecompanion_adapter = "claude_code"

			vim.api.nvim_set_keymap(
				"n",
				"<leader>za",
				"<cmd>CodeCompanionChat adapter=claude_code<cr>",
				{ noremap = true, silent = true, desc = "CodeCompanionChat claude_code" }
			)

			vim.api.nvim_set_keymap(
				"v",
				"<leader>za",
				"<cmd>CodeCompanionChat adapter=claude_code<cr>",
				{ noremap = true, silent = true, desc = "CodeCompanionChat claude_code" }
			)

			vim.cmd([[cab cc CodeCompanion]])
		end,
	},
}
