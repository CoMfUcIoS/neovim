-- Java: jdtls + debugging + tests.
--
-- Java was previously entirely absent from this config — no server, formatter,
-- linter, debugger or treesitter parser. The only mention anywhere was
-- auto-pairs.lua disabling a treesitter check for it.
--
-- jdtls is deliberately NOT started by mason-lspconfig's automatic_enable (it's
-- in that feature's `exclude` list in mason.lua). Two reasons it needs special
-- handling:
--   1. It wants a per-project data/workspace directory, or projects corrupt each
--      other's index.
--   2. Debugging and test-running only work if the java-debug-adapter and
--      java-test bundles are passed in `init_options.bundles` — that's what
--      turns on dap.adapters.java.
--
-- Remote hosts need a JDK 17+ and python3 (mason's jdtls launcher is
-- `python:bin/jdtls`). scripts/remote-bootstrap.sh installs both.

return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	dependencies = { "mfussenegger/nvim-dap" },
	config = function()
		local jdtls = require("jdtls")
		local mason = vim.fn.stdpath("data") .. "/mason"

		-- One workspace dir per project root, keyed by the project directory name.
		local function workspace_dir()
			local root = vim.fs.root(0, { "gradlew", "mvnw", "pom.xml", "build.gradle", ".git" })
				or vim.fn.getcwd()
			return vim.fn.stdpath("cache") .. "/jdtls-workspace/" .. vim.fn.fnamemodify(root, ":p:h:t")
		end

		-- jdtls loads these as OSGi plugins. Without the debug one,
		-- `dap.adapters.java` never appears.
		--
		-- Only the *plugin* jars belong here. java-test's directory also contains
		-- ~27 junit/jacoco/opentest4j jars, which are test-*runtime* dependencies,
		-- not jdtls extensions — globbing them all in is a common recipe that
		-- makes jdtls try to start them as bundles.
		local function bundles()
			local jars = vim.fn.glob(
				mason .. "/packages/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
				true,
				true
			)
			vim.list_extend(
				jars,
				vim.fn.glob(mason .. "/packages/java-test/extension/server/com.microsoft.java.test.plugin-*.jar", true, true)
			)
			return vim.tbl_filter(function(j)
				return j ~= ""
			end, jars)
		end

		-- jdtls needs Java 21+ (it checks: mason/packages/jdtls/bin/jdtls.py:39).
		--
		-- On macOS, Homebrew's openjdk formulae are keg-only — brew never links
		-- them into /usr/bin — so `java` on PATH is Apple's stub, which just
		-- errors and offers to install a JRE. jdtls then dies with
		-- "Command '['java', '-version']' returned non-zero exit status 1".
		-- So prefer an explicit Homebrew JDK when one exists and hand it to
		-- jdtls via --java-executable. openjdk@17 is deliberately not a
		-- candidate: too old for jdtls.
		--
		-- On Linux (including remote hosts, where the bootstrap script installs
		-- default-jdk) there is no /opt/homebrew, so this returns nil and jdtls
		-- resolves `java` from PATH as normal.
		--
		-- `host = true` marks a JDK new enough to *run* jdtls. openjdk@17 is not
		-- one, but it still has to be registered as a runtime below: monolith and
		-- mongodb-service-sdk in ~/Apps target Java 17, and an unregistered target
		-- silently falls back to the API level of jdtls' own JVM.
		local brew_jdks = {
			{ formula = "openjdk@17", name = "JavaSE-17" },
			{ formula = "openjdk@21", name = "JavaSE-21", host = true, default = true },
			{ formula = "openjdk@26", name = "JavaSE-26", host = true },
		}

		local function brew_java()
			for _, jdk in ipairs(brew_jdks) do
				local java = "/opt/homebrew/opt/" .. jdk.formula .. "/bin/java"
				if jdk.host and vim.fn.executable(java) == 1 then
					return java
				end
			end
			local fallback = "/opt/homebrew/opt/openjdk/bin/java"
			return vim.fn.executable(fallback) == 1 and fallback or nil
		end

		-- Registered JDKs for the *project* to compile against, which is separate
		-- from the JVM that runs jdtls itself (--java-executable above).
		local function runtimes()
			local found = {}
			for _, jdk in ipairs(brew_jdks) do
				local home = "/opt/homebrew/opt/" .. jdk.formula .. "/libexec/openjdk.jdk/Contents/Home"
				if vim.fn.isdirectory(home) == 1 then
					found[#found + 1] = { name = jdk.name, path = home, default = jdk.default }
				end
			end
			return found
		end

		-- Lombok rewrites the AST at compile time. Without the javaagent, jdtls
		-- reports every @Data/@Builder/@Slf4j-generated member as unresolved, and
		-- all four Gradle projects in ~/Apps use Lombok. Mason has no lombok
		-- package, so reuse the jar Gradle already downloaded.
		--
		-- ponytail: plain string sort picks the newest, fine across 1.18.x --
		-- compare version tuples if a 1.18.9 ever sits next to a 1.18.46.
		local function lombok_jar()
			local jars = vim.fn.glob(
				vim.env.HOME .. "/.gradle/caches/modules-2/files-2.1/org.projectlombok/lombok/*/*/lombok-*.jar",
				true,
				true
			)
			jars = vim.tbl_filter(function(j)
				return not j:match("%-sources%.jar$") and not j:match("%-javadoc%.jar$")
			end, jars)
			table.sort(jars)
			return jars[#jars]
		end

		local function attach()
			local jdtls_bin = mason .. "/bin/jdtls"
			if vim.fn.executable(jdtls_bin) == 0 then
				return vim.notify(
					"jdtls not installed — run :Mason and install jdtls",
					vim.log.levels.WARN,
					{ title = "java" }
				)
			end

			local cmd = { jdtls_bin, "-data", workspace_dir() }
			local java = brew_java()
			if java then
				vim.list_extend(cmd, { "--java-executable", java })
			end

			local lombok = lombok_jar()
			if lombok then
				cmd[#cmd + 1] = "--jvm-arg=-javaagent:" .. lombok
			end
			-- monolith is big enough (protobuf + shadow) to OOM the launcher default.
			cmd[#cmd + 1] = "--jvm-arg=-Xmx4g"

			-- Same capabilities every other server gets. lsp-config.lua sets these
			-- on "*" via vim.lsp.config, but jdtls is started by start_or_attach
			-- and so bypasses that.
			local capabilities = vim.lsp.protocol.make_client_capabilities()
			local ok_cmp, cmp_lsp = pcall(require, "cmp_nvim_lsp")
			if ok_cmp then
				capabilities = cmp_lsp.default_capabilities()
			end
			capabilities.workspace = capabilities.workspace or {}
			capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = true }

			jdtls.start_or_attach({
				cmd = cmd,
				root_dir = vim.fs.root(0, { "gradlew", "mvnw", "pom.xml", "build.gradle", ".git" }),
				capabilities = capabilities,
				init_options = { bundles = bundles() },
				settings = {
					java = {
						signatureHelp = { enabled = true },
						contentProvider = { preferred = "fernflower" }, -- decompile .class files
						inlayHints = { parameterNames = { enabled = "all" } },
						format = { enabled = false }, -- conform runs google-java-format
						configuration = {
							-- Without a registered runtime, java-debug's
							-- ResolveJavaExecutableHandler throws
							-- "IndexOutOfBoundsException: Index 1 out of bounds
							-- for length 1" and logs "Could not resolve java
							-- executable" when starting a debug session.
							runtimes = runtimes(),
						},
						completion = {
							favoriteStaticMembers = {
								"org.junit.jupiter.api.Assertions.*",
								"org.mockito.Mockito.*",
								"java.util.Objects.requireNonNull",
							},
						},
						sources = {
							organizeImports = { starThreshold = 9999, staticStarThreshold = 9999 },
						},
					},
				},
				on_attach = function(_, bufnr)
					-- Wires up dap.adapters.java from the loaded bundles, and
					-- discovers test classes/methods.
					pcall(jdtls.setup_dap, { hotcodereplace = "auto" })
					pcall(function()
						require("jdtls.dap").setup_dap_main_class_configs()
					end)

					local map = function(lhs, rhs, desc)
						vim.keymap.set("n", lhs, rhs, { buffer = bufnr, desc = desc })
					end
					-- Java-specific refactors gopls-style code actions can't express.
					map("<leader>Ji", jdtls.organize_imports, "Java: organize imports")
					map("<leader>Jv", jdtls.extract_variable, "Java: extract variable")
					map("<leader>Jc", jdtls.extract_constant, "Java: extract constant")
					map("<leader>Jm", jdtls.extract_method, "Java: extract method")
					map("<leader>Jt", function()
						require("jdtls.dap").test_nearest_method()
					end, "Java: debug nearest test")
					map("<leader>JT", function()
						require("jdtls.dap").test_class()
					end, "Java: debug test class")
					vim.keymap.set("v", "<leader>Jm", function()
						jdtls.extract_method(true)
					end, { buffer = bufnr, desc = "Java: extract method" })
				end,
			})
		end

		-- jdtls.setup_dap only discovers *launch* configs for main classes. Attaching
		-- is how the Spring Boot services in ~/Apps get debugged: start one with
		-- `./gradlew bootRun --debug-jvm` (listens on 5005) or
		-- -agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005, then
		-- pick this config. setup_dap_main_class_configs appends, so it survives.
		local dap = require("dap")
		dap.configurations.java = dap.configurations.java or {}
		table.insert(dap.configurations.java, {
			type = "java",
			request = "attach",
			name = "Attach to JVM (jdwp)",
			hostName = function()
				local host = vim.fn.input("Debug host [127.0.0.1]: ")
				return host ~= "" and host or "127.0.0.1"
			end,
			port = function()
				return tonumber(vim.fn.input("Debug port [5005]: ")) or 5005
			end,
		})

		-- ft = "java" means this config runs on the first java buffer, which the
		-- autocmd below then also covers for subsequent ones.
		vim.api.nvim_create_autocmd("FileType", { pattern = "java", callback = attach })
		if vim.bo.filetype == "java" then
			attach()
		end
	end,
}
