return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"leoluz/nvim-dap-go",
			"rcarriga/nvim-dap-ui",
			"nvim-neotest/nvim-nio",
			{
				"b1nhack/nvim-json5",
				-- if you're on windows
				-- run = 'powershell ./install.ps1'
				build = "./install.sh",
				lazy = false,
			},
		},
		config = function()
			require("dapui").setup()
			require("dap-go").setup({
				delve = {
					path = "dlv",
					port = 2345,
				},
			})

			local dap, dapui = require("dap"), require("dapui")

			dap.adapters.php = {
				type = "executable",
				command = "php-debug-adapter",
			}

			dap.configurations.php = {
				{
					type = "php",
					request = "launch",
					name = "Listen for Xdebug",
					port = 9000,
					stopOnEntry = true,
					pathMappings = {
						{
							localRoot = "${workspaceFolder}",
							remoteRoot = "/var/www/html",
						},
					},
				},
			}

			require("dap.ext.vscode").json_decode = require("json5").parse
			require("overseer").enable_dap()
			dap.listeners.before.attach.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.launch.dapui_config = function()
				dapui.open()
			end
			dap.listeners.after.event_initialized.dapui_config = function()
				dapui.open()
			end
			dap.listeners.before.event_terminated.dapui_config = function()
				dapui.close()
			end
			dap.listeners.before.event_exited.dapui_config = function()
				dapui.close()
			end

			vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "", linehl = "", numhl = "" })
			vim.fn.sign_define("DapStopped", { text = "", texthl = "", linehl = "", numhl = "" })

			vim.keymap.set("n", "<Leader>dt", "<cmd>DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" })
			vim.keymap.set("n", "<Leader>dc", "<cmd>DapContinue<CR>", { desc = "Debug Continue" })
			vim.keymap.set("n", "<Leader>dx", "<cmd>DapTerminate<CR>", { desc = "Debug Terminate" })
			vim.keymap.set("n", "<Leader>do", "<cmd>DapStepOver<CR>", { desc = "Debug Step Over" })
			vim.keymap.set("n", "<Leader>di", "<cmd>DapStepInto<CR>", { desc = "Debug Step Into" })
			vim.keymap.set("n", "<Leader>du", "<cmd>DapStepOut<CR>", { desc = "Debug Step Out" })
			vim.keymap.set("n", "<Leader>dw", function()
				dapui.open()
			end, { desc = "Open Debug Window" })
			vim.keymap.set("n", "<Leader>dW", function()
				dapui.close()
			end, { desc = "Close Debug Window" })
			vim.keymap.set("n", "<Leader>dr", function()
				require("dap").repl.open()
			end)
			vim.keymap.set("n", "<Leader>dl", function()
				require("dap").run_last()
			end)
		end,
	},
}
