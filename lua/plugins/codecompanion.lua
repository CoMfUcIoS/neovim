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
		local adapter_names = { "copilot", "xai", "anthropic", "ollama_remote", "ollama" }

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
									.. " developer. I will ask you specific questions and I want you to return concise explanations and codeblock examples."
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
					default = "claude-3.5-sonnet",
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
								default = "qwen2.5-coder:14b",
							},
						},
					})
				end,
			},
		})

		local keymaps = {
			{ "n", "<C-a>", "<cmd>CodeCompanionActions<cr>" },
			{ "v", "<C-a>", "<cmd>CodeCompanionActions<cr>" },
			{ "n", "<leader>zd", "<cmd>Telescope codecompanion<cr>" },
			{ "v", "<leader>zd", "<cmd>Telescope codecompanion<cr>" },
			{ "n", "<leader>zT", "<cmd>lua show_current_adapter()<cr>" },
			{ "v", "<leader>zT", "<cmd>lua show_current_adapter()<cr>" },
			{ "n", "<leader>zt", "<cmd>lua toggle_adapter()<cr>" },
			{ "v", "<leader>zt", "<cmd>lua toggle_adapter()<cr>" },
			{ "v", "ga", "<cmd>CodeCompanionChat Add<cr>" },
		}

		for _, keymap in ipairs(keymaps) do
			vim.api.nvim_set_keymap(keymap[1], keymap[2], keymap[3], { noremap = true, silent = true })
		end

		-- Set initial keymap for <leader>za
		vim.api.nvim_set_keymap(
			"n",
			"<leader>za",
			"<cmd>CodeCompanionChat " .. adapter_names[current_adapter_index] .. "<cr>",
			{ noremap = true, silent = true }
		)
		vim.api.nvim_set_keymap(
			"v",
			"<leader>za",
			"<cmd>CodeCompanionChat " .. adapter_names[current_adapter_index] .. "<cr>",
			{ noremap = true, silent = true }
		)

		vim.cmd([[cab cc CodeCompanion]])
	end,
}
