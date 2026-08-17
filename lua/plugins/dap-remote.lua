-- Remote Go debugging over SSH.
--
-- Flow: pick a host from ~/.ssh/config, pick a target, then this starts
--
--   ssh -L P:127.0.0.1:P <host> bash -lc 'dlv dap --listen=127.0.0.1:P'
--
-- as one background job and points nvim-dap at the local end of the tunnel.
--
-- Why `dlv dap` and not `dlv --headless`: `dlv dap` speaks DAP natively and
-- lets the *client* name the target, so all three targets below are just
-- different DAP request tables over one identical remote command. With
-- `dlv --headless` the target is fixed on the remote command line (and it
-- speaks JSON-RPC, requiring request=attach mode=remote instead).
--
-- Why a separate `go_remote` adapter and not dap-go's `go`: dap-go's adapter
-- always attaches an `executable`, so reusing it would spawn a *local* dlv
-- alongside the remote one. See dap-go.lua:84-100.

local STATE_FILE = vim.fn.stdpath("state") .. "/dlv-remote.json"
local SSH_CONFIG = vim.fn.expand("~/.ssh/config")

local M = {}

-- Session-scoped handle so a second <leader>dR doesn't leak the first tunnel.
local session = { job = nil }

--- Parse Host aliases out of an ssh config, following Include globs.
--- Wildcard patterns (Host *) are skipped: they configure other hosts, they
--- aren't connectable targets themselves.
---@param path string
---@param out? string[]
---@param seen? table<string, boolean>
---@return string[]
function M.parse_hosts(path, out, seen)
	out, seen = out or {}, seen or {}
	if seen[path] then
		return out -- Include cycles are legal to write and fatal to follow.
	end
	seen[path] = true

	local fd = io.open(path, "r")
	if not fd then
		return out
	end

	for raw in fd:lines() do
		local line = raw:gsub("#.*", "")
		local include = line:match("^%s*[Ii]nclude%s+(.+)$")
		local hosts = line:match("^%s*[Hh]ost%s+(.+)$")

		if include then
			for _, pattern in ipairs(vim.split(vim.trim(include), "%s+")) do
				pattern = pattern:gsub("^~", vim.env.HOME)
				if not pattern:match("^/") then
					-- Relative Include paths resolve against ~/.ssh.
					pattern = vim.env.HOME .. "/.ssh/" .. pattern
				end
				for _, file in ipairs(vim.fn.glob(pattern, false, true)) do
					M.parse_hosts(file, out, seen)
				end
			end
		elseif hosts then
			for _, host in ipairs(vim.split(vim.trim(hosts), "%s+")) do
				if host ~= "" and not host:find("[*?]") and not vim.tbl_contains(out, host) then
					out[#out + 1] = host
				end
			end
		end
	end

	fd:close()
	return out
end

--- Bind an ephemeral port, note the number, release it.
--- Not reusing dap-go's pinned 2345 (debugging.lua) so a remote session can
--- run alongside a local one.
---@return integer
local function free_port()
	local sock = assert(vim.uv.new_tcp())
	sock:bind("127.0.0.1", 0)
	local port = sock:getsockname().port
	sock:close()
	return port
end

--- Retry a TCP connect until dlv is listening. nvim-dap does not retry a
--- refused connection, and a fixed sleep is exactly the flaky-on-slow-link case.
---@param port integer
---@param tries integer
---@param cb fun(ok: boolean)
local function wait_for_port(port, tries, cb)
	local client = assert(vim.uv.new_tcp())
	client:connect("127.0.0.1", port, function(err)
		client:close()
		if not err then
			return vim.schedule(function()
				cb(true)
			end)
		end
		if tries <= 0 then
			return vim.schedule(function()
				cb(false)
			end)
		end
		vim.defer_fn(function()
			wait_for_port(port, tries - 1, cb)
		end, 100)
	end)
end

---@return table<string, string>
local function read_roots()
	local fd = io.open(STATE_FILE, "r")
	if not fd then
		return {}
	end
	local body = fd:read("*a")
	fd:close()
	local ok, decoded = pcall(vim.json.decode, body)
	return (ok and type(decoded) == "table") and decoded or {}
end

---@param roots table<string, string>
local function write_roots(roots)
	local fd = io.open(STATE_FILE, "w")
	if not fd then
		return
	end
	fd:write(vim.json.encode(roots))
	fd:close()
end

--- Remote repo root for a host: asked once, then cached.
---@param host string
---@param cb fun(root: string)
local function remote_root(host, cb)
	local roots = read_roots()
	if roots[host] then
		return cb(roots[host])
	end
	vim.ui.input({
		prompt = "Remote repo root on " .. host .. ": ",
		default = "/home/ec2-user/" .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"),
	}, function(root)
		if not root or root == "" then
			return
		end
		root = root:gsub("/+$", "")
		roots[host] = root
		write_roots(roots)
		cb(root)
	end)
end

--- Pick a PID *on the remote host*. nvim-dap's own pick_process enumerates
--- this laptop, which is never what we want here.
---@param host string
---@param cb fun(pid: integer)
local function pick_remote_pid(host, cb)
	vim.ui.input({ prompt = "Remote process name filter: ", default = "" }, function(filter)
		if filter == nil then
			return
		end
		local out = vim.system({ "ssh", host, "pgrep", "-a", filter ~= "" and filter or "." }):wait()
		local items = vim.tbl_filter(function(l)
			return l ~= ""
		end, vim.split(out.stdout or "", "\n"))

		if #items == 0 then
			return vim.notify("No matching processes on " .. host, vim.log.levels.WARN)
		end
		vim.ui.select(items, { prompt = "Remote process on " .. host }, function(choice)
			if not choice then
				return
			end
			cb(tonumber(choice:match("^(%d+)")))
		end)
	end)
end

--- Kill the ssh job backing the current session, if any.
local function stop()
	if session.job then
		pcall(vim.fn.jobstop, session.job)
		session.job = nil
	end
end

--- Open the tunnel, start `dlv dap` on the remote, run `config` once it answers.
---@param host string
---@param config table
local function launch(host, config)
	stop()
	local port = free_port()
	local listen = "127.0.0.1:" .. port

	-- jobstart with a list means no local shell. ssh then joins its trailing
	-- argv with spaces and hands the result to the *remote* shell, so the
	-- remote command has to arrive pre-quoted for that shell.
	-- bash -lc because dlv usually lives in ~/go/bin, which only a login
	-- shell puts on PATH.
	session.job = vim.fn.jobstart({
		"ssh",
		"-L",
		port .. ":" .. listen,
		"-o",
		"ExitOnForwardFailure=yes",
		host,
		"bash -lc " .. vim.fn.shellescape("dlv dap --listen=" .. listen),
	}, {
		on_exit = function(_, code)
			session.job = nil
			if code ~= 0 then
				vim.schedule(function()
					vim.notify("ssh/dlv on " .. host .. " exited: " .. code, vim.log.levels.WARN)
				end)
			end
		end,
	})

	if session.job <= 0 then
		return vim.notify("Could not start ssh to " .. host, vim.log.levels.ERROR)
	end

	vim.notify("Starting dlv on " .. host .. " (port " .. port .. ")...")
	wait_for_port(port, 100, function(ok)
		if not ok then
			stop()
			return vim.notify("dlv on " .. host .. " never started listening", vim.log.levels.ERROR)
		end
		local dap = require("dap")

		-- Registered here, not in a spec `config`: lazy.nvim merges only
		-- opts/cmd/event/ft/keys across specs for the same plugin. A second
		-- `config` would shadow debugging.lua's entirely (plugin.lua:423).
		-- dlv dap is single-use and exits on disconnect, ending the ssh job;
		-- these cover the paths where it doesn't get that far.
		dap.listeners.after.event_terminated["dap_remote"] = stop
		dap.listeners.after.disconnect["dap_remote"] = stop

		dap.adapters.go_remote = {
			type = "server",
			host = "127.0.0.1",
			port = port,
			options = { initialize_timeout_sec = 20 },
		}
		dap.run(config)
	end)
end

--- Local path of the current buffer's directory, relative to cwd ("." at root).
---@return string
local function buffer_package()
	local dir = vim.fn.expand("%:p:h")
	local rel = vim.fn.fnamemodify(dir, ":.")
	return (rel == "" or rel:match("^/")) and "." or rel
end

--- Targets, keyed by picker label. Each returns a DAP config via callback.
--- `mode = "local"` on attach means local *to the dlv server*, i.e. remote.
local targets = {
	{
		label = "Attach to running process",
		build = function(host, root, cb)
			pick_remote_pid(host, function(pid)
				cb({
					type = "go_remote",
					name = "Remote attach (" .. host .. ":" .. pid .. ")",
					request = "attach",
					mode = "local",
					processId = pid,
					cwd = root,
				})
			end)
		end,
	},
	{
		label = "dlv debug (build a package)",
		build = function(host, root, cb)
			vim.ui.input({ prompt = "Package (relative to " .. root .. "): ", default = buffer_package() }, function(pkg)
				if not pkg or pkg == "" then
					return
				end
				cb({
					type = "go_remote",
					name = "Remote debug " .. pkg .. " (" .. host .. ")",
					request = "launch",
					mode = "debug",
					program = root .. "/" .. pkg:gsub("^%./", ""),
					cwd = root,
				})
			end)
		end,
	},
	{
		label = "dlv exec (prebuilt binary)",
		build = function(host, root, cb)
			vim.ui.input({ prompt = "Remote binary path: ", default = root .. "/" }, function(bin)
				if not bin or bin == "" or bin:sub(-1) == "/" then
					return
				end
				cb({
					type = "go_remote",
					name = "Remote exec " .. bin .. " (" .. host .. ")",
					request = "launch",
					mode = "exec",
					program = bin,
					cwd = root,
				})
			end)
		end,
	},
}

--- pick host -> remote root -> pick target -> launch.
function M.start()
	local hosts = M.parse_hosts(SSH_CONFIG)
	if #hosts == 0 then
		return vim.notify("No Host entries in " .. SSH_CONFIG, vim.log.levels.WARN)
	end

	vim.ui.select(hosts, { prompt = "SSH host" }, function(host)
		if not host then
			return
		end
		remote_root(host, function(root)
			vim.ui.select(targets, {
				prompt = "Remote debug target",
				format_item = function(t)
					return t.label
				end,
			}, function(target)
				if not target then
					return
				end
				target.build(host, root, function(config)
					-- from = client (local), to = server (remote).
					-- delve: service/dap/config.go:90
					config.substitutePath = { { from = vim.fn.getcwd(), to = root } }
					launch(host, config)
				end)
			end)
		end)
	end)
end

--- Forget a host's cached remote root, so the next connect re-asks.
function M.forget_root()
	local roots = read_roots()
	local hosts = vim.tbl_keys(roots)
	if #hosts == 0 then
		return vim.notify("No cached remote roots", vim.log.levels.INFO)
	end
	vim.ui.select(hosts, { prompt = "Forget remote root for" }, function(host)
		if not host then
			return
		end
		roots[host] = nil
		write_roots(roots)
		vim.notify("Forgot remote root for " .. host)
	end)
end

-- Commands are created at spec-eval time rather than in a `config` function,
-- for the merge reason noted in launch(). Neither requires dap.
vim.api.nvim_create_user_command("DapRemoteForgetRoot", M.forget_root, {
	desc = "Forget a host's cached remote repo root",
})

vim.api.nvim_create_user_command("DapRemoteSelfCheck", function()
	local fixture, included = vim.fn.tempname(), vim.fn.tempname()

	vim.fn.writefile({ "Host from-include" }, included)
	vim.fn.writefile({
		"# comment",
		"Host alpha bravo",
		"  HostName 10.0.0.1",
		"Host *", -- wildcard: not a connectable target
		"  User nobody",
		"Host charlie # trailing comment",
		"Host alpha", -- duplicate
		"Include " .. included,
	}, fixture)

	local hosts = M.parse_hosts(fixture)
	assert(
		vim.deep_equal(hosts, { "alpha", "bravo", "charlie", "from-include" }),
		"parse_hosts: got " .. vim.inspect(hosts)
	)
	vim.fn.delete(fixture)
	vim.fn.delete(included)

	local port = free_port()
	assert(type(port) == "number" and port > 1024, "free_port: got " .. tostring(port))
	local probe = assert(vim.uv.new_tcp())
	local bound = probe:bind("127.0.0.1", port)
	probe:close()
	assert(bound, "free_port returned an unbindable port: " .. port)

	local expected = {
		["Attach to running process"] = { request = "attach", mode = "local" },
		["dlv debug (build a package)"] = { request = "launch", mode = "debug" },
		["dlv exec (prebuilt binary)"] = { request = "launch", mode = "exec" },
	}
	assert(#targets == 3, "expected 3 targets, got " .. #targets)

	-- Stub the prompts and ssh so build() can be driven without a network.
	local input, select, system = vim.ui.input, vim.ui.select, vim.system
	vim.ui.input = function(opts, cb)
		cb(opts and opts.prompt and opts.prompt:match("binary") and "/remote/root/bin/svc" or "svc")
	end
	vim.ui.select = function(items, _, cb)
		cb(items[1])
	end
	vim.system = function()
		return { wait = function()
			return { stdout = "4321 /remote/root/bin/svc --flag\n", code = 0 }
		end }
	end

	local errors = {}
	for _, target in ipairs(targets) do
		local got
		local ok, err = pcall(target.build, "testhost", "/remote/root", function(c)
			got = c
		end)
		local want = expected[target.label]
		expected[target.label] = nil
		if not want then
			errors[#errors + 1] = "unexpected target label: " .. target.label
		elseif not ok then
			errors[#errors + 1] = target.label .. ": build errored: " .. tostring(err)
		elseif not got then
			errors[#errors + 1] = target.label .. ": build produced no config"
		else
			local checks = {
				{ "type", got.type, "go_remote" },
				{ "request", got.request, want.request },
				{ "mode", got.mode, want.mode },
				{ "cwd", got.cwd, "/remote/root" },
			}
			for _, c in ipairs(checks) do
				if c[2] ~= c[3] then
					errors[#errors + 1] =
						("%s: %s = %s, want %s"):format(target.label, c[1], tostring(c[2]), tostring(c[3]))
				end
			end
			if want.request == "attach" and got.processId ~= 4321 then
				errors[#errors + 1] = target.label .. ": processId = " .. tostring(got.processId) .. ", want 4321"
			end
			if want.request == "launch" and not tostring(got.program):match("^/remote/root/") then
				errors[#errors + 1] = target.label .. ": program not under remote root: " .. tostring(got.program)
			end
		end
	end
	-- Restore before asserting, or a failure leaves the UI stubbed out.
	vim.ui.input, vim.ui.select, vim.system = input, select, system

	for label in pairs(expected) do
		errors[#errors + 1] = "target missing: " .. label
	end
	assert(#errors == 0, "DapRemoteSelfCheck failed:\n  " .. table.concat(errors, "\n  "))
	vim.notify("DapRemoteSelfCheck: all checks passed", vim.log.levels.INFO)
end, { desc = "Self-check the remote dlv config" })

return {
	"mfussenegger/nvim-dap",
	-- Only `keys` here. lazy merges opts/cmd/event/ft/keys across specs for the
	-- same plugin; anything else would shadow debugging.lua's spec.
	keys = {
		{
			"<leader>dR",
			function()
				M.start()
			end,
			desc = "Remote Debug over SSH (dlv)",
		},
	},
}
