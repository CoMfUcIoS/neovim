local js_filetypes = { "typescript", "javascript", "typescriptreact", "javascriptreact" }

--- Pick the runtime for a "Launch file" JS/TS debug session.
---
--- `node` cannot execute TypeScript, so a `.ts`/`.tsx` entrypoint needs a loader.
--- Prefers the project's own tsx over one on PATH, since that's the version the
--- project's other scripts use. Returns nil for `.js`/`.jsx` (and when no tsx
--- exists), which leaves js-debug on its default of plain node — nvim-dap drops
--- nil-returning config fields (`dap.lua:405`).
local function launch_runtime()
	local file = vim.api.nvim_buf_get_name(0)
	if not file:match("%.tsx?$") then
		return nil
	end
	local root = vim.fs.root(0, { "node_modules", "package.json", "tsconfig.json" }) or vim.fn.getcwd()
	local project_tsx = root .. "/node_modules/.bin/tsx"
	if vim.fn.executable(project_tsx) == 1 then
		return project_tsx
	end
	local path_tsx = vim.fn.exepath("tsx")
	if path_tsx ~= "" then
		return path_tsx
	end
	vim.notify(
		"no tsx found (npm i -D tsx) — node cannot run TypeScript directly",
		vim.log.levels.WARN,
		{ title = "dap" }
	)
	return nil
end

--- Read a .env-style file into a table for delve's `env`.
---
--- delve's DAP LaunchConfig has `env` (a map) but NOT `envFile` — that's a
--- VSCode-Go client feature, where the editor expands the file before sending
--- the request. nvim-dap doesn't do it either, in launch.json or otherwise, so
--- an app that gets its config from a .env file starts with none of it unless we
--- build the map ourselves.
---@param path string
---@return table<string,string>
local function read_env_file(path)
	local env = {}
	local fd = io.open(vim.fn.expand(path), "r")
	if not fd then
		vim.notify("env file not found: " .. path, vim.log.levels.WARN, { title = "dap" })
		return env
	end
	for line in fd:lines() do
		line = line:gsub("^%s*export%s+", "")
		local key, value = line:match("^%s*([%w_.]+)%s*=%s*(.*)$")
		if key and not line:match("^%s*#") then
			-- Strip one layer of matching quotes; leave the value otherwise verbatim
			-- (delve does no variable substitution).
			value = value:gsub("%s+#.*$", ""):gsub("^\"(.*)\"$", "%1"):gsub("^'(.*)'$", "%1")
			env[key] = value
		end
	end
	fd:close()
	return env
end

--- Find the nearest .env-ish file, preferring the more specific ones this repo
--- family tends to use.
---@return string?
local function guess_env_file()
	local root = vim.fs.root(0, { "go.mod", ".git" }) or vim.fn.getcwd()
	for _, name in ipairs({ ".env.server", ".env.worker", ".env.local", ".env" }) do
		local path = root .. "/" .. name
		if vim.fn.filereadable(path) == 1 then
			return path
		end
	end
	return nil
end

---@param config {args?:string[]|fun():string[]?}
local function get_args(config)
	local args = type(config.args) == "function" and (config.args() or {}) or config.args or {}
	config = vim.deepcopy(config)
	---@cast args string[]
	config.args = function()
		local new_args = vim.fn.input("Run with args: ", table.concat(args, " ")) --[[@as string]]
		return vim.split(vim.fn.expand(new_args) --[[@as string]], " ")
	end
	return config
end

return {
	"mfussenegger/nvim-dap",
	dependencies = {
		{ "leoluz/nvim-dap-go" },
		{ "stevearc/overseer.nvim", opts = { dap = false } },
		{
			"rcarriga/nvim-dap-ui",
			keys = {
				{
					"<leader>du",
					function()
						require("dapui").toggle({})
					end,
					desc = "Dap UI",
				},
				{
					"<leader>de",
					function()
						require("dapui").eval()
					end,
					desc = "Eval",
					mode = { "n", "v" },
				},
			},
			dependencies = { "nvim-neotest/nvim-nio" },
			config = true,
			opts = {
				floating = { border = "single" },
				layouts = {
					{
						elements = {
							{ id = "scopes", size = 0.25 },
							{ id = "breakpoints", size = 0.25 },
							{ id = "stacks", size = 0.25 },
							{ id = "watches", size = 0.25 },
						},
						position = "left",
						size = 30,
					},
					{
						elements = {
							{ id = "console", size = 1 },
						},
						position = "bottom",
						size = 10,
					},
				},
			},
		},
		{ "theHamsta/nvim-dap-virtual-text", opts = {} },
		-- Python. debugpy was in the Mason list but nothing ever registered a
		-- `python` adapter, so python debugging didn't work at all. Point
		-- dap-python at Mason's debugpy venv rather than the system python, so it
		-- works without debugpy being installed into every project venv.
		{
			"mfussenegger/nvim-dap-python",
			ft = "python",
			config = function()
				local debugpy = vim.fn.stdpath("data") .. "/mason/packages/debugpy/venv/bin/python"
				require("dap-python").setup(vim.fn.executable(debugpy) == 1 and debugpy or "python3")
			end,
			keys = {
				{
					"<leader>dPt",
					function()
						require("dap-python").test_method()
					end,
					ft = "python",
					desc = "Debug Nearest Python Test",
				},
				{
					"<leader>dPc",
					function()
						require("dap-python").test_class()
					end,
					ft = "python",
					desc = "Debug Python Test Class",
				},
			},
		},
		-- Lua adapter
		{
			"jbyuki/one-small-step-for-vimkind",
			keys = {
				{
					"<leader>dL",
					function()
						require("osv").launch({ port = 8086 })
					end,
					desc = "Launch Lua adapter",
				},
				{
					"<leader>dT",
					function()
						require("osv").run_this()
					end,
					desc = "Lua adapter: Run this",
				},
			},
		},
	},
	keys = {
		{
			"<leader>Td",
			function()
				require("neotest").run.run({ strategy = "dap" })
			end,
			desc = "Debug Nearest",
		},
		-- dap-go drives delve straight off the test function under the cursor,
		-- without going through neotest's discovery. Useful when neotest hasn't
		-- found the test (build tags, generated files, odd layouts).
		{
			"<leader>dn",
			function()
				require("dap-go").debug_test()
			end,
			ft = "go",
			desc = "Debug Nearest Go Test (delve)",
		},
		{
			"<leader>dN",
			function()
				require("dap-go").debug_last_test()
			end,
			ft = "go",
			desc = "Debug Last Go Test (delve)",
		},
		{
			"<leader>dB",
			function()
				require("dap").set_breakpoint(vim.fn.input("Breakpoint condition: "))
			end,
			desc = "Breakpoint Condition",
		},
		{
			"<leader>db",
			function()
				require("dap").toggle_breakpoint()
			end,
			desc = "Toggle Breakpoint",
		},
		{
			"<leader>dq",
			function()
				require("dap").clear_breakpoints()
			end,
			desc = "Clear Breakpoints",
		},
		{
			"<leader>dc",
			function()
				require("dap.ext.vscode").load_launchjs(nil, vscode_type_to_ft)
				require("dap").continue()
			end,
			desc = "Continue",
		},
		{
			"<leader>da",
			function()
				require("dap").continue({ before = get_args })
			end,
			desc = "Run with Args",
		},
		{
			"<leader>dC",
			function()
				require("dap").run_to_cursor()
			end,
			desc = "Run to Cursor",
		},
		{
			"<leader>dg",
			function()
				require("dap").goto_()
			end,
			desc = "Go to line (no execute)",
		},
		{
			"<leader>dj",
			function()
				require("dap").down()
			end,
			desc = "Down",
		},
		{
			"<leader>dk",
			function()
				require("dap").up()
			end,
			desc = "Up",
		},
		{
			"<leader>dl",
			function()
				require("dap").run_last()
			end,
			desc = "Run Last",
		},
		{
			"<leader>di",
			function()
				require("dap").step_into()
			end,
			desc = "Step Into",
		},
		{
			"<leader>dO",
			function()
				require("dap").step_out()
			end,
			desc = "Step Out",
		},
		{
			"<leader>do",
			function()
				require("dap").step_over()
			end,
			desc = "Step Over",
		},
		{
			"<leader>dp",
			function()
				require("dap").pause()
			end,
			desc = "Pause",
		},
		{
			"<leader>dr",
			function()
				require("dap").repl.toggle({ wrap = false }, "belowright vsplit")
			end,
			desc = "Toggle REPL",
		},
		{
			"<leader>ds",
			function()
				require("dap").session()
			end,
			desc = "Session",
		},
		{
			"<leader>dt",
			function()
				require("dap").terminate()
			end,
			desc = "Terminate",
		},
		{
			"<leader>dh",
			function()
				require("dap.ui.widgets").hover()
			end,
			desc = "Widgets",
		},
	},
	config = function()
		local dap = require("dap")
		local dapui = require("dapui")
		local icons = {
			Stopped = { "󰁕 ", "DiagnosticSignWarn", "DapStoppedLine" },
			Breakpoint = { " ", "DiagnosticSignInfo" },
			BreakpointCondition = { " ", "DiagnosticSignHint" },
			BreakpointRejected = { " ", "DiagnosticSignError" },
			LogPoint = "",
		}
		require("dap-go").setup({
			delve = {
				path = "dlv",
				port = 2345,
			},
		})

		-- Attach to a delve that something *else* already started — the live-reload
		-- case: `air` launches `dlv exec ... --headless`, so the target is fixed on
		-- dlv's command line and the client attaches with mode="remote".
		--
		-- dap-go's own `go` adapter can't do this: given a port it still attaches an
		-- `executable` (dap-go.lua:84-100) and nvim-dap would spawn a *second*,
		-- local dlv instead of connecting to the running one.
		dap.adapters.go_attach = function(callback, config)
			callback({
				type = "server",
				host = config.host or "127.0.0.1",
				port = config.port or 2345,
				options = { initialize_timeout_sec = 20 },
			})
		end

		dap.configurations.go = dap.configurations.go or {}
		vim.list_extend(dap.configurations.go, {
			{
				-- The straightforward way to debug a server that normally runs under
				-- air: don't use air. delve builds and runs it, breakpoints work
				-- immediately, and there's no attach step. You lose live reload —
				-- restart the session with <leader>dl instead.
				type = "go",
				name = "Debug package + .env file (pick dir)",
				request = "launch",
				mode = "debug",
				program = function()
					return vim.fn.input("Package dir: ", "./cmd/", "file")
				end,
				args = function()
					return vim.split(vim.fn.input("Args: ", "--log-level=debug"), " ", { trimempty = true })
				end,
				env = function()
					local guess = guess_env_file()
					local path = vim.fn.input("Env file (empty for none): ", guess or "", "file")
					return path ~= "" and read_env_file(path) or nil
				end,
				outputMode = "remote",
			},
			{
				-- Live reload kept: air runs the binary under a headless delve and
				-- this attaches to it. See CONFIG.md "Debugging a live-reload (air)
				-- Go server" for the .air toml.
				type = "go_attach",
				name = "Attach to headless delve / air (port)",
				request = "attach",
				mode = "remote",
				port = function()
					return tonumber(vim.fn.input("dlv --headless port: ", "2345")) or 2345
				end,
			},
		})

		dap.listeners.after.event_initialized["dapui_config"] = function()
			dapui.open({})
		end

		if not dap.adapters["node"] then
			dap.adapters["node"] = function(cb, config)
				if config.type == "node" then
					config.type = "pwa-node"
				end
				local nativeAdapter = dap.adapters["pwa-node"]
				if type(nativeAdapter) == "function" then
					nativeAdapter(cb, config)
				else
					cb(nativeAdapter)
				end
			end
		end

		vim.api.nvim_set_hl(0, "DapStoppedLine", { default = true, link = "Visual" })

		-- DAP signs are vim signs, not diagnostics. The old loop called
		-- vim.diagnostic.config() per icon, which both did nothing for DAP and
		-- wiped the LSP diagnostic gutter icons the moment dap loaded.
		for name, sign in pairs(icons) do
			sign = type(sign) == "table" and sign or { sign }
			vim.fn.sign_define("Dap" .. name, {
				text = sign[1],
				texthl = sign[2] or "DiagnosticInfo",
				linehl = sign[3],
				numhl = sign[3],
			})
		end

		-- setup dap config by VsCode launch.json file
		local dap_vscode = require("dap.ext.vscode")
		local json = require("plenary.json")
		---@diagnostic disable-next-line: duplicate-set-field
		dap_vscode.json_decode = function(str)
			return vim.json.decode(json.json_strip_comments(str, {}))
		end

		-- Extends dap.configurations with entries read from .vscode/launch.json
		if vim.fn.filereadable(".vscode/launch.json") then
			dap_vscode.load_launchjs()
		end

		-- vscode-js-debug, from Mason's prebuilt `js-debug-adapter`, replacing a
		-- `microsoft/vscode-js-debug` source checkout whose `npm i && npm run
		-- compile` build never completed here — leaving nvim-dap-vscode-js pointed at
		-- an empty `out/`, so every pwa-node session failed to launch. Mason's bin is
		-- a one-line wrapper: `node .../dapDebugServer.js "$@"`, port as argv.
		--
		-- Registering the adapters directly is all nvim-dap-vscode-js was doing, so
		-- that plugin is gone too.
		local js_debug = vim.fn.stdpath("data") .. "/mason/bin/js-debug-adapter"
		for _, adapter in ipairs({ "pwa-node", "pwa-chrome", "pwa-msedge", "node-terminal", "pwa-extensionHost" }) do
			dap.adapters[adapter] = {
				type = "server",
				host = "localhost",
				port = "${port}",
				executable = { command = js_debug, args = { "${port}" } },
			}
		end

		dap_vscode.type_to_filetypes["node"] = js_filetypes

		for _, language in ipairs(js_filetypes) do
			dap.configurations[language] = {
				-- Debug single nodejs files
				{
					name = "Launch file",
					type = "pwa-node",
					request = "launch",
					program = "${file}",
					runtimeExecutable = launch_runtime,
					cwd = "${workspaceFolder}",
					args = { "${file}" },
					sourceMaps = true,
					sourceMapPathOverrides = {
						["./*"] = "${workspaceFolder}/src/*",
					},
				},
				-- Debug nodejs processes (make sure to add --inspect when you run the process)
				{
					name = "Attach",
					type = "pwa-node",
					request = "attach",
					processId = require("dap.utils").pick_process,
					cwd = "${workspaceFolder}",
					sourceMaps = true,
				},
				{
					name = "Debug Jest Tests",
					type = "pwa-node",
					request = "launch",
					runtimeExecutable = "node",
					runtimeArgs = { "${workspaceFolder}/node_modules/.bin/jest", "--runInBand" },
					rootPath = "${workspaceFolder}",
					cwd = "${workspaceFolder}",
					console = "integratedTerminal",
					internalConsoleOptions = "neverOpen",
					-- args = {'${file}', '--coverage', 'false'},
					-- sourceMaps = true,
					-- skipFiles = {'<node_internals>/**', 'node_modules/**'},
				},
				{
					name = "Debug Vitest Tests",
					type = "pwa-node",
					request = "launch",
					cwd = vim.fn.getcwd(),
					program = "${workspaceFolder}/node_modules/vitest/vitest.mjs",
					args = { "run", "${file}" },
					autoAttachChildProcesses = true,
					smartStep = true,
					skipFiles = { "<node_internals>/**", "node_modules/**" },
				},
				-- Debug web applications (client side)
				{
					name = "Launch & Debug Chrome",
					type = "pwa-chrome",
					request = "launch",
					url = function()
						local co = coroutine.running()
						return coroutine.create(function()
							vim.ui.input({ prompt = "Enter URL: ", default = "http://localhost:3000" }, function(url)
								if url == nil or url == "" then
									return
								else
									coroutine.resume(co, url)
								end
							end)
						end)
					end,
					webRoot = vim.fn.getcwd(),
					protocol = "inspector",
					sourceMaps = true,
					userDataDir = false,
					resolveSourceMapLocations = {
						"${workspaceFolder}/**",
						"!**/node_modules/**",
					},

					-- From https://github.com/lukas-reineke/dotfiles/blob/master/vim/lua/plugins/dap.lua
					-- To test how it behaves
					rootPath = "${workspaceFolder}",
					cwd = "${workspaceFolder}",
					console = "integratedTerminal",
					internalConsoleOptions = "neverOpen",
					sourceMapPathOverrides = {
						["./*"] = "${workspaceFolder}/src/*",
					},
				},
				{
					name = "----- ↑ launch.json configs (if available) ↑ -----",
					type = "",
					request = "launch",
				},
			}
		end
		local php_debug_adapt_path = require("mason-registry").get_package("php-debug-adapter"):get_install_path()
		dap.adapters.php = {
			type = "executable",
			command = "node",
			args = { php_debug_adapt_path .. "/extension/out/phpDebug.js" },
		}

		dap.configurations.php = {
			-- to run php right from the editor
			{
				name = "run current script",
				type = "php",
				request = "launch",
				port = 9003,
				cwd = "${fileDirname}",
				program = "${file}",
				runtimeExecutable = "php",
			},
			-- to listen to any php call
			{
				name = "listen for Xdebug local",
				type = "php",
				request = "launch",
				port = 9003,
			},
			-- to listen to php call in docker container
			{
				name = "listen for Xdebug docker",
				type = "php",
				request = "launch",
				port = 9003,
				-- this is where your file is in the container
				pathMappings = {
					["/usr/local/apache2/htdocs/"] = "${workspaceFolder}",
				},
			},
		}
		-- Lua configurations.
		-- 1. Open a Neovim instance (instance A)
		-- 2. Launch the DAP server with (A) >
		--    :lua require"osv".launch({port=8086})
		-- 3. Open another Neovim instance (instance B)
		-- 4. Open `myscript.lua` (B)
		-- 5. Place a breakpoint on line 2 using (B) >
		--    :lua require"dap".toggle_breakpoint()
		-- 6. Connect the DAP client using (B) >
		--    :lua require"dap".continue()
		-- 7. Run `myscript.lua` in the other instance (A) >
		--    :luafile myscript.lua
		-- 8. The breakpoint should hit and freeze the instance (B)

		dap.adapters.nlua = function(callback, config)
			local adapter = {
				type = "server",
				host = config.host or "127.0.0.1",
				port = config.port or 8086,
			}
			if config.start_neovim then
				local dap_run = dap.run
				dap.run = function(c)
					adapter.port = c.port
					adapter.host = c.host
				end
				require("osv").run_this()
				dap.run = dap_run
			end
			callback(adapter)
		end

		dap.configurations.lua = {
			{
				type = "nlua",
				request = "attach",
				name = "Run this file",
				start_neovim = {},
			},
			{
				type = "nlua",
				request = "attach",
				name = "Attach to running Neovim instance (port = 8086)",
				port = 8086,
			},
		}
	end,
}
