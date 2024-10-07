return {
	{
		"mfussenegger/nvim-dap",
		dependencies = {
			"leoluz/nvim-dap-go",
			{ "rcarriga/nvim-dap-ui", dependencies = { "nvim-neotest/nvim-nio" }, config = true },
			{
				"b1nhack/nvim-json5",
				-- if you're on windows
				-- run = 'powershell ./install.ps1'
				build = "./install.sh",
				lazy = false,
			},
			{ "theHamsta/nvim-dap-virtual-text", config = true },
			{ "mxsdev/nvim-dap-vscode-js", module = { "dap-vscode-js" } },
			{
				"microsoft/vscode-js-debug",
				opt = true,
				run = "npm install --legacy-peer-deps && npx gulp vsDebugServerBundle && mv dist out",
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

			local DEBUGGER_PATH = os.getenv("HOME") .. "/.local/share/nvim/lazy/vscode-js-debug"

			require("dap-vscode-js").setup({
				node_path = "node",
				debugger_path = DEBUGGER_PATH,
				debugger_cmd = { "js-debug-adapter" },
				log_file_path = os.getenv("HOME") .. "/.local/share/nvim/dap_vscode_js.log",
				log_file_level = 2,
				log_console_level = 2,
				adapters = {
					"pwa-node",
					"pwa-chrome",
					"pwa-msedge",
					"node-terminal",
					"pwa-extensionHost",
				}, -- which adapters to register in nvim-dap
			})

			for _, language in ipairs({ "typescript", "javascript" }) do
				dap.configurations[language] = {
					{
						type = "pwa-node",
						request = "launch",
						name = "Launch file",
						program = "${file}",
						cwd = "${workspaceFolder}",
					},
					{
						type = "pwa-node",
						request = "attach",
						name = "Attach",
						processId = require("dap.utils").pick_process,
						cwd = "${workspaceFolder}",
					},
					{
						type = "pwa-node",
						request = "launch",
						name = "Debug Jest Tests",
						-- trace = true, -- include debugger info
						runtimeExecutable = "node",
						runtimeArgs = {
							"./node_modules/jest/bin/jest.js",
							"--runInBand",
						},
						rootPath = "${workspaceFolder}",
						cwd = "${workspaceFolder}",
						console = "integratedTerminal",
						internalConsoleOptions = "neverOpen",
					},
				}
			end

			for _, language in ipairs({ "typescriptreact", "javascriptreact" }) do
				dap.configurations[language] = {
					{
						type = "pwa-chrome",
						name = "Attach - Remote Debugging",
						request = "attach",
						program = "${file}",
						cwd = vim.fn.getcwd(),
						sourceMaps = true,
						protocol = "inspector",
						port = 9222,
						webRoot = "${workspaceFolder}",
					},
					{
						type = "pwa-chrome",
						name = "Launch Chrome",
						request = "launch",
						url = "http://localhost:3000",
					},
				}
			end
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
