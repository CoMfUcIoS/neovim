return {
	"mfussenegger/nvim-dap",
	dependencies = {
		"leoluz/nvim-dap-go",
		"rcarriga/nvim-dap-ui",
		"nvim-neotest/nvim-nio",
	},
	config = function()
		require("dapui").setup()
		require("dap-go").setup({
			delve = {
				path = "dlv",
				port = 2345,
			},
			dap_configurations = {
				{
					type = "go",
					name = "Attach to pim",
					args = get_arguments,
					mode = "remote",
					program = "main.go",
					remote_path = "${workspaceFolder}",
					request = "attach",
				},
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

		dap.listeners.before.attach.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.launch.dapui_config = function()
			dapui.open()
		end
		dap.listeners.before.event_terminated.dapui_config = function()
			dapui.close()
		end
		dap.listeners.before.event_exited.dapui_config = function()
			dapui.close()
		end

		vim.keymap.set("n", "<Leader>dt", ":DapToggleBreakpoint<CR>", { desc = "Toggle breakpoint" })
		vim.keymap.set("n", "<Leader>dc", ":DapContinue<CR>", { desc = "Debug Continue" })
		vim.keymap.set("n", "<Leader>dx", ":DapTerminate<CR>", { desc = "Debug Terminate" })
		vim.keymap.set("n", "<Leader>do", ":DapStepOver<CR>", { desc = "Debug Step Over" })
	end,
}
