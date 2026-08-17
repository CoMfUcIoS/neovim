# Neovim Config — How Everything Works

Reference for this config: what each piece does, every keybinding, and what
changed in the GoLand-parity pass.

> Looking for **how to get Go work done** rather than what each plugin is?
> See [GO-WORKFLOW.md](GO-WORKFLOW.md) — task-oriented, organized by
> writing / navigating / refactoring / testing / debugging.

> **Leader is `<Space>`.** Keyboard layout is Miryoku ColemakDH — split
> navigation uses `n/e/i/o` (left/down/up/right), not `h/j/k/l`. See
> [README.md](README.md).

**Contents**

- [Bootstrap & load order](#bootstrap--load-order)
- [Editor options](#editor-options)
- [Language server layer](#language-server-layer)
- [Go — the GoLand parity layer](#go--the-goland-parity-layer)
- [Completion](#completion)
- [Formatting & linting](#formatting--linting)
- [Testing](#testing)
- [Debugging](#debugging)
- [Treesitter & structural editing](#treesitter--structural-editing)
- [Finding things](#finding-things)
- [Git](#git)
- [UI](#ui)
- [Editing helpers](#editing-helpers)
- [AI](#ai)
- [Language-specific & misc](#language-specific--misc)
- [Keymap conflicts to know about](#keymap-conflicts-to-know-about)
- [What changed in the GoLand pass](#what-changed-in-the-goland-pass)
- [Troubleshooting](#troubleshooting)

---

## Bootstrap & load order

```
init.lua
 ├─ require("vim-options")   ← bootstraps lazy.nvim, sets core options
 ├─ require("keymaps")       ← sets <leader>, global keymaps
 ├─ vim.g.nvim_remote        ← remote profile flag (see Remote profile)
 └─ lazy.setup{ ... }        ← every lua/plugins/*.lua, ONE options table
```

> **Everything must go in lazy.setup's first table.** `lazy.setup(spec, opts)`
> discards its second argument whenever the first has a `spec` key
> (`lazy/init.lua:32-38`). `git`, `checker` and `change_detection` used to sit in
> a second table and were **silently dead** — `checker.enabled` read `false`
> despite being set to `true`, so there was no update checker at all. Now merged
> into the first table.

`init.lua` short-circuits when `vim.g.vscode` is set (VSCode Neovim extension)
— options and keymaps load, no plugins. It also resolves the Python provider
from `$PYTHON3_HOST_PROG`, falling back to `~/.pyenv/versions/neovim3/bin/python`.

Each file in `lua/plugins/` returns a lazy.nvim spec. Files returning `{}`
(`plugins.lua`, `rest.lua`, `console-inline.lua`) are disabled placeholders —
harmless, kept for easy re-enabling.

`lazy.nvim` is set to auto-check for updates silently (`checker.enabled`,
`notify = false`) and not to nag on config changes (`change_detection.notify = false`).

**Order matters in exactly two places:** plugin `init` functions run at
startup before anything loads (this is where gopls settings are registered),
and `priority = 1000` plugins (`monokai`, `github-theme`, `snacks`) load first.

---

## Editor options

`lua/vim-options.lua`

| Option | Value | Why |
|---|---|---|
| `relativenumber` + `number` | on | hybrid line numbers |
| `tabstop` / `shiftwidth` | 2 | note: Go uses hard tabs, gofumpt handles it |
| `expandtab` | on | |
| `ignorecase` + `smartcase` | on | lowercase search = case-insensitive |
| `cursorline`, `termguicolors` | on | |
| `signcolumn` | `yes` | always reserved, no gutter jitter |
| `clipboard` | `unnamedplus` | yank goes to system clipboard |
| `splitright` / `splitbelow` | on | new splits open right/below |
| `swapfile` | off | |
| `background` | dark | |

Two autocmds worth knowing:

- **Soft wrap for real files only** — `BufWinEnter` sets `wrap` + `linebreak`
  on buffers with empty `buftype`, so plugin windows aren't wrapped.
- **Minimap-aware `wrapmargin`** — recalculates `wrapmargin` on
  `WinEnter`/`WinClosed`/`BufWinEnter` so text wraps *before* the neominimap
  split instead of sliding under it.

---

## Language server layer

`lua/plugins/lsp-config.lua` + `lua/plugins/mason.lua`

### How servers get started

Neovim 0.12's native `vim.lsp.config` / `vim.lsp.enable` API — **not** the old
`lspconfig.<server>.setup{}` pattern.

```
mason.nvim              installs the binaries
  └─ mason-lspconfig    ensure_installed → auto-calls vim.lsp.enable() for each (v2 behavior)
       └─ nvim-lspconfig  ships the default config (cmd, root markers, filetypes)
            └─ vim.lsp.config("gopls", {...})  ← your overrides, merged on top
```

Because mason-lspconfig v2 auto-enables, **you never write a `setup{}` call**.
To tune a server, add a `vim.lsp.config("<name>", {...})` block — it deep-merges
onto nvim-lspconfig's default.

`vim.lsp.config("*", { capabilities })` sets the baseline for every server:
nvim-cmp's capabilities (snippet support, completion resolve, item defaults)
plus dynamic file-watcher registration.

### Servers installed

`cmake` · `dockerls` · `docker_compose_language_service` · `eslint` · `jsonls` ·
`gopls` · `golangci_lint_ls` · `harper_ls` (prose/grammar) · `puppet` ·
`rubocop` · `rust_analyzer` · `ts_ls` · `html` · `cssls` · `tailwindcss` ·
`svelte` · `lua_ls` · `graphql` · `emmet_ls` · `prismals` · `pyright` ·
`markdown_oxide` · `intelephense`

Plus `pullminder_lsp`, a custom server registered by hand (`pullminder lsp`,
rooted at `.git`) across yaml/json/markdown/go/ts/js/python/dockerfile/terraform/shell.

### LSP keymaps

Set buffer-local on `LspAttach`, so they only exist where a server is running.

| Key | Action |
|---|---|
| `gd` | Go to definition (snacks picker) |
| `gD` | Go to declaration |
| `gR` | References |
| `gi` | Implementations |
| `gt` | Type definition |
| `K` | Hover docs |
| `<C-k>` | Signature help (normal + insert) |
| `<leader>ca` | Code actions (normal + visual) |
| `<leader>rn` | Rename symbol |
| `<leader>rs` | Restart LSP |
| `<leader>ci` | Incoming calls (call hierarchy) |
| `<leader>cO` | Outgoing calls |
| `<leader>cS` | Document symbols (outline) |
| `<leader>cw` | Workspace symbols |
| `<leader>cc` | Run code lens |
| `<leader>cd` | Line diagnostics (float) |
| `<leader>D` | Buffer diagnostics (picker) |
| `[d` / `]d` | Prev / next diagnostic |

### Automatic behavior on attach

- **Inlay hints** enabled if the server supports them — parameter names and
  inferred types shown inline. Toggle with `<leader>uh`.
- **Code lens** enabled via `vim.lsp.codelens.enable()`, which owns its own
  refresh cycle. This is what puts `run test` above Go test functions.
- **Document highlight** — on `CursorHold`, other occurrences of the symbol
  under the cursor light up; cleared on `CursorMoved`.

### Diagnostics display

One `vim.diagnostic.config()` call sets all four severity icons
(` `/` `/` `/`󰠠 `), `virtual_text` with `source = "if_many"`,
`severity_sort`, rounded float borders, and `update_in_insert = false`.

---

## Go — the GoLand parity layer

`lua/plugins/go.lua`

### gopls settings

Registered in the spec's `init` so it lands before mason-lspconfig's
auto-enable resolves the config.

| Setting | Effect |
|---|---|
| `staticcheck = true` | GoLand's inspection set |
| `gofumpt = true` | stricter gofmt in LSP-provided formatting |
| `usePlaceholders = true` | completing a function fills its parameters |
| `completeUnimported = true` | complete symbols from packages not yet imported, auto-adding the import |
| `semanticTokens = true` | richer, LSP-driven highlighting |
| `symbolMatcher = "fuzzy"` | fuzzy workspace-symbol search |
| `directoryFilters` | skips `.git`, `node_modules`, `vendor`, `bazel-out` |

**Analyses on:** `nilness` (nil derefs), `shadow` (shadowed vars),
`unusedparams`, `unusedwrite`, `unusedvariable`, `useany`.
`fieldalignment` is **off** — it fires on nearly every struct; turn it on
deliberately when doing memory-layout work.

**Code lenses on:** `generate`, `gc_details`, `test`, `tidy`,
`run_govulncheck`, `upgrade_dependency`, `regenerate_cgo`. Run the one under
the cursor with `<leader>cc`.

**All seven inlay hint categories on:** assigned variable types, composite
literal fields and types, constant values, function type parameters,
parameter names, range variable types.

`golangci_lint_ls` is also configured here with the `--output.json.path=stdout`
invocation it needs to actually run `golangci-lint`.

### go.nvim — command toolbox only

`ray-x/go.nvim` is loaded on Go filetypes, deliberately **stripped down** to
avoid fighting the rest of the config:

```lua
lsp_cfg = false                  -- gopls configured above
lsp_keymaps = false              -- lsp-config.lua owns keymaps
lsp_inlay_hints = { enable = false }  -- native vim.lsp.inlay_hint
lsp_document_formatting = false  -- conform.nvim owns formatting
dap_debug = false                -- nvim-dap-go owns debugging
```

It's used purely for the things gopls has no answer for.

| Key | Command | GoLand equivalent |
|---|---|---|
| `<leader>Gta` | `GoAddTag` | Generate ▸ Tags |
| `<leader>Gtr` | `GoRmTag` | — |
| `<leader>Gtc` | `GoClearTag` | — |
| `<leader>Gtt` | `GoAddTest` | Generate ▸ Test for function |
| `<leader>GtT` | `GoAddExpTest` | tests for exported funcs |
| `<leader>GtA` | `GoAddAllTest` | tests for every func |
| `<leader>Ge` | `GoIfErr` | `err` live template |
| `<leader>Gf` | `GoFillStruct` | fill struct fields |
| `<leader>Gs` | `GoFillSwitch` | exhaustive switch |
| `<leader>Gi` | `GoImpl` | Implement Methods |
| `<leader>Gc` | `GoCoverage` | Coverage gutters |
| `<leader>GC` | `GoCoverage -t` | toggle coverage |
| `<leader>Gm` | `GoModTidy` | — |
| `<leader>Gg` | `GoGenerate` | — |
| `<leader>Gv` | `GoVulnCheck` | — |
| `<leader>Ga` | `GoAlt!` | **Ctrl+Shift+T** (jump impl ↔ test) |
| `<leader>GA` | `GoAltV!` | same, in a vsplit |

### Go tooling installed via Mason

`gopls` · `delve` (`dlv`) · `golangci-lint` · `golangci-lint-langserver` ·
`gofumpt` · `goimports` · `golines` · `gomodifytags` · `gotests` · `impl` · `iferr`

Mason prepends `~/.local/share/nvim/mason/bin` to Neovim's `PATH`, so these
resolve inside Neovim without touching your shell profile.

### GoLand feature map

| GoLand | Here |
|---|---|
| Inspections | gopls `staticcheck` + analyses, `golangci_lint_ls` |
| Parameter hints | inlay hints, on by default |
| Gutter run/debug arrows | gopls `test` codelens → `<leader>cc` |
| Run/debug test | `<leader>ttn`, `<leader>ttdn` (neotest) |
| Debugger | nvim-dap + delve (`<leader>d*`) |
| Coverage | `<leader>Gc` |
| Rename / extract | `<leader>rn` / `<leader>ca` |
| Call hierarchy | `<leader>ci` / `<leader>cO` |
| Structure view | `<leader>cS`, `<leader>cs` (Trouble) |
| Go to test | `<leader>Ga` |
| Generate tags/tests/impl | `<leader>Gt*`, `<leader>Gi` |
| Quick definition popup | goto-preview (`gp*`) |
| Breadcrumbs | dropbar |
| Structural motions | **treesitter-textobjects — GoLand has no equivalent** |

---

## Completion

`lua/plugins/completion.lua` — nvim-cmp.

| Key | Mode | Action |
|---|---|---|
| `<Tab>` | insert | expand/jump snippet, else confirm selection |
| `<CR>` | insert | confirm |
| `<C-e>` | insert | next item |
| `<C-i>` | insert | previous item |
| `<C-x>` | insert | abort |

Sources in priority order: `lazydev` (Lua API) → `supermaven` → `nvim_lsp` →
`luasnip` → `path` → `buffer` (visible buffers only) → `codecompanion`.

Bordered completion and documentation windows, `lspkind` icons with a source
tag (`[LSP]`, `[Buffer]`, `[Path]`, `[Lua]`), max 10 visible entries, zero
debounce/throttle. Snippets come from LuaSnip + friendly-snippets.

**Supermaven is installed but inert** — `condition = function() return false end`
and inline completion disabled. Copilot and Codeium blocks are commented out.

`nvim-autopairs` hooks cmp's `confirm_done` so completing a function adds its
parens, and uses treesitter to skip pairing inside Lua strings and JS template
literals.

---

## Formatting & linting

**`conform.nvim`** — format on save, synchronous, `timeout_ms = 3000`, LSP fallback.
`<leader>mp` formats manually (works on a visual range too).

| Filetype | Formatters |
|---|---|
| go | `goimports`, `gofumpt` |
| js/ts/jsx/tsx/svelte/css/html/json/markdown/graphql/liquid | `prettierd` |
| yaml | `yamlfix` |
| lua | `stylua` |
| rust | `rustfmt` |
| ruby | `rubocop` |
| sh | `shfmt` |
| php | `php_cs_fixer`, `phpstan` |
| puppet | `puppet-lint` |
| clojure | `cljfmt` |

**`nvim-lint`** — runs on `BufReadPost` + `BufWritePost`; `<leader>ll` triggers manually.
Python (`pylint`, `mypy`), shell (`shellcheck`), puppet, ruby (`rubocop`),
lua (`luacheck`), clojure (`clj-kondo`).

**Go is deliberately absent from nvim-lint** — `golangci_lint_ls` covers it as
a language server. Having both meant two full-package `golangci-lint` runs per save.

---

## Testing

`lua/plugins/neo-test.lua` — neotest with adapters for **golang**, vitest,
jest, rspec, deno, phpunit, playwright.

| Key | Action |
|---|---|
| `<leader>tta` | Run all tests in cwd |
| `<leader>ttf` | Run current file |
| `<leader>ttn` | Run nearest test |
| `<leader>ttdn` | **Debug** nearest test (DAP strategy) |
| `<leader>ttl` | Run last |
| `<leader>ttx` | Stop |
| `<leader>tts` | Toggle summary panel |
| `<leader>tto` | Toggle output panel |
| `<leader>Td` | Debug nearest (from the DAP spec) |

Failures surface as diagnostics (ERROR severity), plus virtual text, signs,
and quickfix. Summary panel supports watch mode (`w`), marking (`m`/`R`/`D`),
and failure jumping (`n`/`p`).

---

## Debugging

`lua/plugins/debugging.lua` — nvim-dap. `lua/plugins/dap-remote.lua` adds
remote Go debugging over SSH (see [below](#remote-go-debugging-over-ssh)).

**Adapters:** Go (`nvim-dap-go` → delve), `go_remote` (remote delve over an SSH
tunnel), Node/Chrome/Edge (Mason's prebuilt `js-debug-adapter`), PHP (Xdebug), Lua
(`one-small-step-for-vimkind`).

> **Why not `microsoft/vscode-js-debug`:** it was specced with
> `build = "npm i && npm run compile …"`, and that build never completed here —
> leaving a 36 MB source checkout with an empty `out/`, which is exactly where
> `nvim-dap-vscode-js` looks for `out/src/vsDebugServer.js`. The adapters still
> *registered*, so nothing warned; every pwa-node session just failed to launch.
> Mason's `js-debug-adapter` is the same debugger, prebuilt, and its bin is a
> one-line `node .../dapDebugServer.js "$@"` wrapper — so `debugging.lua` registers
> the five `pwa-*` adapters itself and nvim-dap-vscode-js is gone.
>
> Verified end to end: breakpoint hit at `app.js:3` under a launched node process,
> and at `app.ts:3` through tsx.
>
> **"Launch file" on a `.ts`/`.tsx` entrypoint:** `node` can't execute TypeScript,
> so `runtimeExecutable` is a function (`launch_runtime`, top of `debugging.lua`)
> that resolves the project's `node_modules/.bin/tsx`, else a `tsx` on PATH, else
> warns. For `.js`/`.jsx` it returns nil and js-debug falls back to plain node —
> nvim-dap drops nil-returning config fields (`dap.lua:405`), which is what makes
> one config serve both. A project with no tsx installed still needs
> `npm i -D tsx` (or use the Jest/Vitest configs, which bring their own transform).

Go configurations from dap-go: Debug · Debug (Arguments) · Debug (Arguments &
Build Flags) · Debug Package · Attach · Debug test · Debug test (go.mod).

`.vscode/launch.json` is read automatically when present (comments stripped
via plenary's JSON parser), so VSCode debug configs work as-is.

| Key | Action |
|---|---|
| `<leader>dc` | Continue / start (loads launch.json first) |
| `<leader>da` | Run with args |
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | Conditional breakpoint |
| `<leader>dq` | Clear all breakpoints |
| `<leader>di` / `<leader>do` / `<leader>dO` | Step into / over / out |
| `<leader>dC` | Run to cursor |
| `<leader>dg` | Go to line (no execute) |
| `<leader>dj` / `<leader>dk` | Down / up the stack |
| `<leader>dp` | Pause |
| `<leader>dt` | Terminate |
| `<leader>dl` | Run last |
| `<leader>ds` | Session info |
| `<leader>dr` | Toggle REPL |
| `<leader>dh` | Hover widget |
| `<leader>du` | Toggle DAP UI |
| `<leader>de` | Evaluate (normal + visual) |
| `<leader>dL` / `<leader>dT` | Launch Lua adapter / run this Lua file |
| `<leader>dn` / `<leader>dN` | Debug nearest / last Go test via dap-go (**Go buffers only**) |
| `<leader>dPt` / `<leader>dPc` | Debug nearest Python test / test class (**Python buffers only**) |
| `<leader>Jt` / `<leader>JT` | Debug nearest Java test / test class (**Java buffers only**) |
| `<leader>dR` | Remote debug over SSH — pick host, pick target |

Two extra Go configurations, for servers that normally run under **air**:

| Config (via `<leader>dc`) | What it does |
|---|---|
| Debug package + .env file (pick dir) | Prompts for package dir, args and a `.env` file; delve launches it. No air, no attach step |
| Attach to headless delve / air (port) | Attaches to a delve that air already started (`request=attach, mode=remote`) |

- **`read_env_file` exists because delve has no `envFile`.** Its DAP LaunchConfig
  has `env` (a map) only; `envFile` is a VSCode-Go feature where the editor
  expands the file before sending the request, and nvim-dap doesn't replicate it —
  not even in `launch.json`. Without this, an app configured from `.env` starts
  with none of its config. `guess_env_file` prefers
  `.env.server` → `.env.worker` → `.env.local` → `.env` from the project root.
- **`dap.adapters.go_attach` is separate from dap-go's `go`** for the same reason
  `go_remote` is: given a port, dap-go's adapter still attaches an `executable`
  (`dap-go.lua:84-100`), so nvim-dap would spawn a *second*, local delve instead of
  connecting to the running one. `go_attach` is a plain `{type="server"}`.

See [GO-WORKFLOW.md](GO-WORKFLOW.md#debugging-a-live-reload-air-server) for the
air-side toml and the reload caveats.

DAP UI opens automatically on session start: scopes, breakpoints, stacks and
watches in a 30-col left panel; console in a 10-row bottom panel.
`nvim-dap-virtual-text` shows variable values inline as you step.

### Remote Go debugging over SSH

`lua/plugins/dap-remote.lua`. `<leader>dR` → pick a host → pick a target. No
new plugins; it's glue over nvim-dap and the `ssh` binary.

What happens on selection:

```
free local port P
ssh -L P:127.0.0.1:P <host> bash -lc 'dlv dap --listen=127.0.0.1:P'   (bg job)
poll 127.0.0.1:P until listening
dap.run{ type = "go_remote", ... }
```

**Three targets**, all one remote command — the target lives in the DAP request,
not the SSH invocation:

| Target | DAP request |
|---|---|
| Attach to running process | `request="attach", mode="local", processId=<remote pid>` |
| `dlv debug` a package | `request="launch", mode="debug", program=<root>/<pkg>` |
| `dlv exec` a prebuilt binary | `request="launch", mode="exec", program=<remote path>` |

**Design notes**, each of which is load-bearing:

- **`dlv dap`, not `dlv --headless`.** `dlv dap` speaks DAP natively and lets
  the *client* name the target, which is what collapses three targets into one
  remote command. `dlv --headless` speaks JSON-RPC, fixes the target on the
  remote command line, and forces `request=attach, mode=remote`.
- **A separate `go_remote` adapter.** dap-go's `go` adapter always attaches an
  `executable` (`dap-go.lua:84-100`), so reusing it would spawn a *local* dlv
  alongside the remote one. `go_remote` is a plain `{type="server", host, port}`.
- **`mode="local"` on attach is correct.** It means local *to the dlv server* —
  i.e. on the remote box. Remote PIDs come from `ssh <host> pgrep -a`, because
  nvim-dap's built-in `pick_process` enumerates *this* laptop.
- **The spec contributes only `keys`.** lazy.nvim merges just
  `opts/cmd/event/ft/keys` across specs for one plugin (`plugin.lua:423`);
  everything else shadows. A second `config` here would have silently replaced
  `debugging.lua`'s entire config — killing the DAP signs, dap-go setup, and the
  PHP/Lua/JS adapters. Listeners are registered inside `launch()`, commands at
  spec-eval time.
- **Ephemeral port, not 2345.** `debugging.lua` pins `delve.port = 2345`, so a
  fixed port would collide with a local dap-go session.
- **Poll, don't sleep.** nvim-dap does not retry a refused connection, and a
  fixed delay is exactly the flaky-on-slow-link case. 100 tries × 100 ms.
- **Both ends bind `127.0.0.1`.** The remote dlv is reachable only through the
  tunnel, never on the remote's network.
- **`bash -lc`** because `dlv` usually lives in `~/go/bin`, which only a login
  shell puts on `PATH`. `ssh` concatenates its trailing argv and hands the result
  to the remote shell, so the command is pre-quoted with `shellescape`.

**Host list** — `Host` lines from `~/.ssh/config`, following `Include` globs,
skipping wildcard patterns (`Host *` configures other hosts, it isn't a
connectable target). Connections then shell out to plain `ssh <alias>`, so
`ProxyCommand`, `IdentityFile` and `User` are resolved by ssh itself rather than
reimplemented.

**Path mapping** — `substitutePath = {{ from = <local cwd>, to = <remote root> }}`;
delve reads `from` as client and `to` as server (`service/dap/config.go:90`).
The remote root is prompted once per host and cached in
`stdpath("state")/dlv-remote.json`. `:DapRemoteForgetRoot` clears one.

**Cleanup** — `dlv dap` is single-use and exits on DAP disconnect, ending the
ssh job. `dap.listeners` on `event_terminated` / `disconnect` cover the paths
that don't get that far, so a failed handshake can't leak a tunnel.

**Commands:** `:DapRemoteSelfCheck` (asserts host parsing incl. includes and
wildcard skipping, port allocation, and all three target tables with stubbed
prompts — no network), `:DapRemoteForgetRoot`.

---

## Remote development (whole editor on the remote)

`lua/plugins/remote-nvim.lua` — `remote-nvim.nvim`. This is the VSCode
Remote-SSH architecture: Neovim is installed on the remote host, this config is
copied over, a headless server runs there, and a local TUI attaches via
`nvim --server localhost:PORT --remote-ui`.

| Key / Command | Action |
|---|---|
| `<leader>Hs` / `:RemoteStart` | Pick a host, connect (provisions on first run) |
| `<leader>Hq` / `:RemoteStop` | Stop the remote server and close the session |
| `:RemoteInfo` | Sessions created this Neovim run |
| `:RemoteCleanup` | Delete the workspace or the whole remote Neovim setup |
| `:RemoteConfigDel` | Forget a saved host record |
| `:RemoteLog` | Plugin log |

**Two different remote stories — don't confuse them:**

| | `<leader>dR` (dap-remote) | `<leader>Hs` (remote-nvim) |
|---|---|---|
| Editor runs | locally | on the remote |
| gopls, grep, git run | locally, on local files | on the remote, on remote files |
| Moves | only the debugger | the whole editor |
| Use when | you want breakpoints in your local buffers against a process you can't move | you're doing real work on that box |

**Why this over the alternatives.** `distant.nvim` was the other candidate: its
remote LSP has been broken since Neovim 0.10 (issue #137, open since July 2024,
with a clean unmerged fix in PR #138) and its last commit was October 2024 —
remote LSP being the only reason to choose it. sshfs would let every existing
plugin work unmodified on local-looking paths, but needs macFUSE on macOS and
makes gopls indexing painful. This approach runs gopls where the code is, so it
can't be half-broken.

### Configuration notes

**Left at defaults:**

- `ssh_config.ssh_config_file_paths = { "$HOME/.ssh/config" }`, `Include`
  respected — the same host list `<leader>dR` uses.
- `client_callback` — float term running `--remote-ui`.

**Overridden: `copy_dirs.config.dirs` is an allowlist, not `"*"`.**

```lua
dirs = { "init.lua", "lua", "lazy-lock.json", "patches" }
```

The default `"*"` resolves to `base/.` (`provider.lua:71-73`) — the *entire*
config directory, which for this repo means shipping `.git` (752K of 1.2M) to
every host on every connect. The allowlist cuts the payload to **336K**.
`lazy-lock.json` is in it so remote plugin versions match the laptop, and
compression is on.

`patches` is **required, not optional** — codecompanion's build runs
`git apply ~/.config/nvim/patches/codecompanion.patch`. Drop it from the
allowlist and codecompanion fails to build remotely.

**`config = true`, not the README's snippet.** Upstream documents
`require('remote-nvim'):setup()` with a **colon**, but setup is
`M.setup = function(opts)` — a dot function (`init.lua:216`). The colon form
passes the module table as `opts` and deep-merges its fields into the config.
lazy's `config = true` calls it with a dot, which is correct. Verified after
install: `rn.config.default_opts` is `nil`, i.e. unpolluted.

**`<leader>H*` is a prefix, never a bare `<leader>H`** — a complete mapping that
is also a prefix stalls for `timeoutlen`. See
[Keymap conflicts](#keymap-conflicts-to-know-about).

**Dependencies are not new.** plenary, nui and telescope were all already here
(nui via noice, telescope via neoclip/obsidian/overseer/goto-preview). They're
declared in the spec for load ordering only.

### ⚠ Upstream is archived

**The repo was archived 2026-08-13** — a day after the last release line of this
config was written. It is pinned to `tag = "v0.3.12"` (commit `9992c2f`,
released 2025-08-22) so it cannot drift.

Verified working on **Neovim 0.12.4** as of this writing: loads clean, all six
commands register, setup applies unpolluted, and it parses `~/.ssh/config`
correctly including the `ProxyCommand` on the SSM host. Neovim 0.12.4 still
ships `nvim-linux-x86_64.appimage`, which is what its remote installer
downloads — the thing most likely to break first when a future Neovim drops that
asset.

**Exit plan when it does break:** the plugin only automates three manual steps —
install Neovim on the remote, copy this config there, run `nvim`. Doing that by
hand over `ssh` loses the local-TUI niceties and nothing else. No data lives in
the plugin; `:RemoteCleanup` removes the remote side.

### Languages (remote parity)

The six languages worked on remotely, and what backs each one. Identical in both
profiles — verified by reading `ensure_installed`, `formatters_by_ft` and
`linters_by_ft` back out at runtime with `NVIM_REMOTE` forced both ways.

| | LSP | Format | Lint | Debug | Parser |
|---|---|---|---|---|---|
| **Go** | gopls + golangci_lint_ls | goimports, gofumpt | via LSP | dap-go → delve | go, gomod, gosum |
| **PHP** | intelephense | php_cs_fixer | phpcs | php-debug-adapter (Xdebug) | php, phpdoc |
| **TS / JS** | ts_ls + eslint | prettierd | via eslint LSP | js-debug-adapter (pwa-node/chrome) | typescript, javascript, tsx |
| **Java** | jdtls (via nvim-jdtls) | google-java-format | via LSP | java-debug-adapter + java-test | java |
| **Python** | pyright | ruff_organize_imports, ruff_format | pylint, mypy | debugpy via nvim-dap-python | python |

Verified live on this machine by opening a real project per language and reading
back the attached clients, available formatters and treesitter state:

| | attached servers | formatters | parser |
|---|---|---|---|
| Go | `gopls`, `golangci_lint_ls` | goimports, gofumpt | ✅ |
| PHP | `intelephense` | php_cs_fixer¹ | ✅ |
| TS/JS | `ts_ls`, `eslint`² | prettierd | ✅ |
| Java | `jdtls` | google-java-format | ✅ |
| Python | `pyright`, `ruff`³ | ruff_organize_imports, ruff_format | ✅ |

¹ present but unrunnable without a `php` interpreter — see
[runtimes](#language-runtimes-are-a-separate-question-from-mason).
² only attaches when the project has an eslint config; expected.
³ ruff also ships an LSP, and `automatic_enable` starts it since the tool is
installed — so Python gets fast ruff diagnostics via LSP *and* pylint/mypy via
nvim-lint. Harmless overlap, ruff is fast.

`harper_ls` (grammar) attaches to every filetype, so it shows up alongside all of
these.

**Java** is new — it previously had *nothing*: no server, formatter, linter,
debugger or parser. The only mention of it anywhere was `auto-pairs.lua:17`
disabling a treesitter check. See `lua/plugins/java.lua`; keymaps are
`<leader>J*`, buffer-local to Java files. Confirmed working locally: jdtls
attaches, 0 diagnostics on clean code, `dap.adapters.java` registers and a main
class is discovered.

> jdtls is excluded from mason-lspconfig's `automatic_enable` and started by
> nvim-jdtls instead, because it needs a per-project workspace dir (or projects
> corrupt each other's index) and because debugging only works when the
> java-debug/java-test jars are passed via `init_options.bundles`. Two starters
> would give two competing clients per buffer.

**Python** was half-wired: pyright and the linters were configured, but the
conform entry was commented out (so format-on-save silently did nothing — pyright
doesn't format) and nothing ever registered a `python` DAP adapter, so debugging
didn't work at all despite debugpy being installed. Both fixed;
`<leader>dPt` / `<leader>dPc` debug the nearest test / test class.

#### Language runtimes are a separate question from Mason

Mason installs the *tooling*; some of that tooling is written in the language it
serves and needs that language's runtime present. Worth knowing which is which,
because a missing runtime looks exactly like a broken config:

| Tool | Written in | Needs on the machine |
|---|---|---|
| gopls, delve, gofumpt, goimports, golangci-lint | Go | Mason builds them with `go install`, so a Go toolchain |
| intelephense, ts_ls, eslint, prettierd, php-debug-adapter, jsonls, dockerls | Node | `node` |
| **phpcs, phpstan, php-cs-fixer** | **PHP** | **a `php` interpreter** |
| **jdtls, google-java-format** | **Java** | **a JDK 21+** to run jdtls (checks: `jdtls.py:39`), plus a JDK per project target — 17/21/26 are installed here |
| debugpy, ruff, mypy, pylint | Python | `python3` (Mason manages a venv) |

So on a machine with no `php`, intelephense still gives you completion and
diagnostics (it's Node), but `phpcs` and `php_cs_fixer` fail with
`exec: php: not found` — format-on-save quietly does nothing for `.php`. That's
the runtime missing, not the config. Same shape for Java without a JDK.

`scripts/remote-bootstrap.sh` installs all five runtimes, which is why remote
hosts get the full set.

> **macOS gotcha, handled in `java.lua`:** Homebrew's `openjdk` formulae are
> keg-only — brew never links them into `/usr/bin` — so `java` on PATH is Apple's
> stub, which only offers to install a JRE. jdtls then dies with
> `Command '['java', '-version']' returned non-zero exit status 1`. `java.lua`
> therefore looks for `/opt/homebrew/opt/openjdk@21|@26|openjdk` and passes it as
> `--java-executable`. `openjdk@17` is not a candidate for *running* jdtls — too
> old — but it is registered as a project `runtime` alongside 21 and 26, because
> the Java projects in `~/Apps` (monolith, mongodb-service-sdk) target Java 17 and
> an unregistered target silently falls back to the API level of jdtls' own JVM.
> On Linux there's no `/opt/homebrew`, so it falls through to `java` on PATH.

#### Java: Lombok, Gradle toolchains, attaching a debugger

Three things the Java repos in `~/Apps` (monolith, rdb-service, mongodb-service,
mongodb-service-sdk — all Gradle, all Lombok) need beyond a plain jdtls:

| | Why | Where |
|---|---|---|
| **Lombok javaagent** | Lombok generates getters/builders/loggers at compile time. Without the agent jdtls flags every `@Data`/`@Builder`/`@Slf4j` member as unresolved — hundreds of phantom errors. Mason has no lombok package, so `java.lua` reuses the newest `lombok-*.jar` Gradle already downloaded into `~/.gradle/caches` and passes `--jvm-arg=-javaagent:`. No jar found (e.g. a fresh remote host) → skipped, no error. | `java.lua`, `lombok_jar()` |
| **Gradle toolchain paths** | Homebrew's keg-only JDKs are invisible to Gradle's toolchain auto-detection, so any `java { toolchain { ... } }` project dies with *"Cannot find a Java installation … matching languageVersion=17"* — from the CLI **and** from jdtls' Gradle import. Fixed once, globally, in `~/.gradle/gradle.properties` via `org.gradle.java.installations.paths`. Not part of this repo. | `~/.gradle/gradle.properties` |
| **`Attach to JVM (jdwp)`** | `jdtls.setup_dap` only discovers *launch* configs for main classes. The Spring Boot services are usually already running, so the useful move is attaching: start with `./gradlew bootRun --debug-jvm` (port 5005) or `-agentlib:jdwp=transport=dt_socket,server=y,suspend=n,address=*:5005`, then `<leader>dc` and pick it. Prompts for host and port, so it works against a remote box too. | `java.lua` |

jdtls also gets `--jvm-arg=-Xmx4g`; monolith (protobuf + shadow) outgrows the
launcher default.

`build.gradle.kts` files are Kotlin — the `kotlin` parser is in both treesitter
lists so the Kotlin-DSL builds highlight.

`google-java-format` runs with `--aosp` (4-space) because all four repos are
4-space and none enforce a formatter in the build; Google's 2-space default would
reindent every file on save. It still reflows over-long lines, so if a review
diff comes back noisy, drop `java` from `formatters_by_ft` and format on demand
with `<leader>mp`.

### Remote profile

The full config is wrong for a remote box: 60-odd plugins, ~38 Mason tools, 30
treesitter parsers, and build steps wanting `cargo`, `yarn`, ImageMagick and
`pngpaste`. Two could never work unattended at all — copilot's
`build = ":Copilot auth"` is interactive and firenvim's drives a local browser.

So `vim.g.nvim_remote` gates a slimmer profile. It's set once in `init.lua`:

```lua
vim.g.nvim_remote = vim.uv.os_uname().sysname ~= "Darwin"   -- NVIM_REMOTE=1/0 overrides
```

> This laptop is macOS and the remote boxes are Linux, so `sysname` is a reliable
> one-liner with no env plumbing. It would misfire if you ran this config on a
> *local* Linux machine — export `NVIM_REMOTE=0` there. Marked with a `ponytail:`
> comment in `init.lua`.

**Plugins switched off remotely** — via a single `defaults.cond` in
`lazy.setup`, lazy's documented hook for exactly this ("globally disable a lot of
plugins... when running inside vscode for example"). A plugin's own `cond` wins
over it (`lazy/core/meta.lua:267-272`). One table in `init.lua`, no per-file edits.

| Disabled | Why |
|---|---|
| `image.nvim` | Cannot render through `--remote-ui`; wants magick + luarocks |
| `diagram.nvim` | Renders via image.nvim |
| `img-clip.nvim` | Clipboard images; wants `pngpaste` |
| `codesnap.nvim` | Code screenshots; Rust build |
| `firenvim` | Browser integration; build drives a local browser |
| `markdown-preview.nvim` | Opens a local browser; yarn build |
| `obsidian.nvim` | Vault lives on the laptop |
That's **7 disabled, 111 enabled** (vs 119 locally), and it removes Rust, yarn,
ImageMagick/luarocks and pngpaste from the remote dependency set entirely — those
plugins were where those toolchains came from.

**Kept remotely, deliberately:** all six working languages (see
[Languages](#languages-remote-parity)) including their debuggers, codecompanion +
mcphub, and the whole git stack (fugitive, gitsigns, octo, diffview) — committing
and pushing from the box you're working on is the point. octo additionally needs
`gh auth login` there.

TS/JS debugging is wanted remotely too, and now costs nothing to provision: it's
Mason's prebuilt `js-debug-adapter` rather than a `microsoft/vscode-js-debug`
source checkout with an `npm i` plus TypeScript compile.

**Trimmed lists** (not disabled — just shorter): Mason drops 25 servers → 14 and
its tool list → 26; treesitter 32 parsers → 25. What's cut is whole languages not
worked on remotely — Ruby, Rust, Puppet, Clojure — plus framework-specific servers
(tailwindcss, svelte, graphql, emmet_ls, prismals) and cmake/harper/markdown_oxide.
That's what keeps the ruby and rust toolchains off the box. `:Mason` and
`:TSInstall <lang>` still work on demand.

### First connect

**1. Provision the host, once:**

```sh
ssh <host> 'bash -s' < scripts/remote-bootstrap.sh
```

Idempotent. Installs `build-essential` (treesitter, telescope-fzf-native, LuaSnip
`jsregexp`), `git`, `curl`, `ripgrep`, `fd-find`, `fzf`, `nodejs`/`npm` (mcphub's
bundled build plus the npm-based LSPs), and Go from tarball — Mason installs the
Go tools with `go install`, and Ubuntu's `golang` package lags far enough behind
to break gopls. It also symlinks Debian's `fdfind` to `fd`, which every plugin
looks for, and appends Go + Mason bin dirs to `~/.profile` — needed because
remote-nvim starts through a login shell and `dap-remote.lua` runs
`bash -lc 'dlv ...'`.

Deliberately a shell script and not Ansible/Puppet: it's one `apt` line and a
tarball for a couple of hosts. Revisit if you're managing enough boxes that drift
matters.

**2. `<leader>Hs`** → pick host → it prompts for the Neovim version. **Pick
0.12.x to match local** — `--remote-ui` isn't compatible across the 0.9.2
boundary.

**3.** First launch runs `:Lazy sync` plus Mason installs — a few minutes.

Remote prerequisites beyond the script: GitHub connectivity (set
`offline_mode.enabled` if that box has no egress).

---

## Treesitter & structural editing

**`nvim-treesitter`** (main branch, new API). Parsers installed for go, json,
js/ts/tsx, yaml, php, html, css, prisma, markdown, svelte, graphql, bash, lua,
vim, dockerfile, gitignore, query, vimdoc, c, rust, puppet, ruby, diff, regex,
http, latex, scss, typst, vue. Highlighting and indentation are wired via
`FileType` autocmds guarded by `pcall`, so a missing parser degrades quietly.

**`nvim-treesitter-textobjects`** (main branch) — structural motions.

| Key | Mode | Selects / moves to |
|---|---|---|
| `af` / `if` | visual, operator | a function / function body |
| `ac` / `ic` | visual, operator | a struct-class / its body |
| `aa` / `ia` | visual, operator | an argument / argument body |
| `a/` | visual, operator | a comment |
| `]f` / `[f` | normal, visual, operator | next / previous function |
| `]c` / `[c` | normal, visual, operator | next / previous struct-class |

So `daf` deletes a whole function, `vic` selects a struct body, `cia` changes
an argument. `lookahead` is on (operating from just before a textobject jumps
into it), and moves push to the jumplist.

**`nvim-origami`** — folding from LSP folding ranges with treesitter fallback.
`<Left>` closes a fold, `<Right>` opens one. Comments and imports auto-fold.
Fold text shows line count, diagnostic count and gitsigns count. Folds pause
during search.

**Other treesitter consumers:** `nvim-ts-autotag` (auto-close HTML/JSX tags),
`nvim-ts-context-commentstring` (correct comment syntax in embedded languages),
`indent-blankline` (`┊` guides), `nvim-autopairs`.

---

## Finding things

**`snacks.nvim`** is the primary picker (fzf-lua and telescope are installed
but only used by specific plugins).

| Key | Picker |
|---|---|
| `<leader>ff` | Files |
| `<leader>fr` | Recent files |
| `<leader>fb` | Buffers |
| `<leader>fs` | Grep (project) |
| `<leader>fw` | Grep word / visual selection |
| `<leader>fl` | Lines in buffer |
| `<leader>fgb` | Grep open buffers |
| `<leader>fgg` | Git files |
| `<leader>fgl` | Git log |
| `<leader>fgs` | Git status |
| `<leader>fd` | Diagnostics |
| `<leader>fc` | Commands |
| `<leader>fk` | Keymaps |
| `<leader>fC` | Config files |
| `<leader>ft` / `<leader>fT` | Todo comments / Todo+Fix+Fixme |

**File trees.** `nvim-tree` on the right, 40 cols: `<leader>ee` toggle,
`<leader>ef` reveal current file, `<leader>ec` collapse, `<leader>er` refresh.
`mini.files` as a floating alternative: `<leader>em`.

**Trouble** — structured diagnostic/symbol lists.

| Key | List |
|---|---|
| `<leader>xx` | Diagnostics |
| `<leader>xX` | Buffer diagnostics |
| `<leader>cs` | Symbols |
| `<leader>cl` | LSP definitions/references, right panel |
| `<leader>xL` | Location list |
| `<leader>xQ` | Quickfix |

`<C-t>` inside a snacks picker sends results to Trouble.

**goto-preview** — peek definitions in a floating window without leaving the
buffer (GoLand's Ctrl+Shift+I). Default mappings under `gp`, stacked previews.

**Other navigation:** `]]` / `[[` jump between references of the symbol under
the cursor (snacks words). `]t` / `[t` jump between todo comments.
`<leader>wo` picks a breadcrumb component (dropbar).

---

## Git

**gitsigns** — signs in the gutter, inline blame always on.

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous hunk |
| `<leader>hs` | Stage hunk (visual: stage selection) |
| `<leader>hr` | Reset hunk (visual: reset selection) |
| `<leader>hS` / `<leader>hR` | Stage / reset whole buffer |
| `<leader>hu` | Undo stage hunk |
| `<leader>hp` | Preview hunk |
| `<leader>hd` / `<leader>hD` | Diff this / diff against `~` |
| `ih` | Hunk textobject (visual, operator) |

**lazygit** (via snacks): `<leader>gg` open · `<leader>gl` log ·
`<leader>gf` current file history.
`<leader>hb` blames the current line. `<leader>gbr` / dashboard `b` open the
repo in a browser.

**fugitive** (`:Git`) + **rhubarb** for `:GBrowse`. `<leader>gbc` in visual
mode copies a GitHub URL to the selected line range.

**octo.nvim** — GitHub issues and PRs in-editor, snacks picker.
`<leader>lh` issues · `<leader>lp` PRs · `<leader>lP` my PRs · `<leader>lH` my
issues, plus ~15 more filter combinations under `<leader>l*`.

---

## UI

- **monokai.nvim** — **the default colorscheme**, set explicitly at
  `priority = 1000`. Also provides `monokai_pro`, `monokai_soda`,
  `monokai_ristretto`.
- **github-theme** — installed and configured, but does **not** set a
  colorscheme; it only registers `<leader>cos`, which cycles the 11 GitHub
  variants (dark, dimmed, high contrast, colorblind, tritanopia, light…).
- **huez** — colorscheme manager: `<leader>cop` picker · `<leader>coi`
  installed · `<leader>cof` favorites · `<leader>col` registry · `<leader>coe` ensured.
  Persists your pick and re-applies it on `UIEnter`, so a theme chosen through
  huez overrides the default above. `fallback = "monokai"` — where huez lands
  when it has no saved theme.

> **Why monokai is declared in a spec file rather than just picked in huez.**
> huez-manager's `import` builds its theme specs from a runtime state file under
> `stdpath("data")/huez`, so a theme picked in the huez UI exists only on the
> machine you picked it on — it lands in `lazy-lock.json` but in none of the
> tracked spec files. On a fresh clone, or on a remote-nvim host (the data dir
> isn't in the [copy allowlist](#remote-development-whole-editor-on-the-remote)),
> the spec wouldn't exist and you'd get Neovim's `default`. `lua/plugins/monokai.lua`
> plus `fallback = "monokai"` makes it reproducible; verified by moving huez's
> state dir aside and still landing on monokai.
- **snacks dashboard** — startup screen with a custom ASCII header.
  Keys: `f` files, `n` new, `g` grep, `r` recent, `c` config, `s` restore
  session, `L` Lazy, `M` Mason, `T` MCP Hub, `b` browse repo, `H` checkhealth, `q` quit.
- **lualine** — mode / branch / filename / encoding+filetype+MCP / progress / location.
- **bufferline** — in `tabs` mode, so it shows tabs rather than buffers.
- **dropbar** — winbar breadcrumbs with lspkind icons.
- **neominimap** — 20-col minimap split on the right, auto-enabled, excluded
  on help/http/bigfile. `<leader>nt` toggle · `<leader>no`/`<leader>nc` on/off ·
  `<leader>nf`/`<leader>nu` focus/unfocus · `<leader>ns` toggle focus ·
  `<leader>nw*` per-window · `<leader>nb*` per-buffer.
- **noice** — replaces cmdline/messages/popupmenu. Bottom search, command
  palette, long messages to a split, bordered LSP docs. Routes away noisy
  `nL, nB` / undo messages.
- **snacks notifier** — 3s toasts, wrapped. `<leader>nn` history · `<leader>un` dismiss all.
- **dressing** — prettier `vim.ui.input` / `vim.ui.select`.
- **neoscroll** — smooth scrolling. Rebinds `<C-u>`/`<C-d>`/`<C-b>`/`<C-f>`,
  `zt`/`zz`/`zb`, and `<C-i>`/`<C-e>` as small nudges.
- **snacks bigfile** — files over 1.5 MB drop treesitter, folds and match-paren.
- **snacks statuscolumn / quickfile / words**.

**Toggles** (snacks, `<leader>u*`): `us` spell · `uw` wrap · `ul` line numbers ·
`uL` relative numbers · `ud` diagnostics · `uc` conceal · `uT` treesitter ·
`ub` background · `uh` **inlay hints**.

---

## Editing helpers

From `lua/keymaps.lua`:

| Key | Action |
|---|---|
| `<leader>nh` | Clear search highlight |
| `<leader>+` / `<leader>-` | Increment / decrement number |
| `<leader>sv` / `<leader>sh` | Split vertical / horizontal |
| `<leader>sn` `<leader>se` `<leader>si` `<leader>so` | Move to left / down / up / right split |
| `<leader>s=` / `<leader>sx` | Equalize / close split |
| `<leader>to` `<leader>tx` `<leader>ta` | New tab / close tab / close others |
| `<leader>tn` / `<leader>tp` | Next / previous tab |
| `<leader>tf` | Current buffer in a new tab |
| `<leader>qq` `<leader>qb` `<leader>qw` | Quit all / close buffer / close all buffers |
| `<leader>qa"` `<leader>qa'` `<leader>qa(` `<leader>qa[` `<leader>qa{` | Surround word |
| `<leader>qc'` / `<leader>qc"` | Change surrounding quotes |
| `<leader>me` / `<leader>mi` | Move line down / up |
| `<leader>ss` / `<leader>SS` | Substitute on line / in file (very magic) |
| `<leader>yf` / `<leader>df` | Yank whole file / delete file content to black hole |
| `<leader>sa` | Select all |
| `<leader>gbc` | (visual) copy GitHub URL for selected lines |

**Plugin-provided:**

- **Comment.nvim** — `gcc` line, `gbc` block, `gc`/`gb` operators,
  `gcO`/`gco`/`gcA` above/below/end-of-line.
- **substitute.nvim** — `s` operator (replace motion with register), `ss` line,
  `S` to end of line, `s` in visual. **This overrides vim's built-in `s`.**
- **undotree** — `<leader>u`.
- **neoclip** — clipboard history (`:Neoclip`), sqlite-backed.
- **auto-save** — installed but **disabled**; `<leader>as` toggles it.
- **auto-session** — auto-restore **off**; `<leader>ws` save, `<leader>wr` restore.
  Suppressed in `~`, Downloads, Documents, Desktop.
- **hardtime** — anti-bad-habit nagging, **disabled** (`enabled = false`).
- **which-key** — pops up pending keybindings after 300 ms (`timeoutlen`).
- **url-open** — `gx` opens the URL under the cursor.
- **tmux navigation** — `<M-Left/Down/Up/Right>` cross tmux panes and nvim
  splits seamlessly; `<M-\>` last active, `<M-Space>` next.
  Requires the tmux config in [README.md](README.md).
- **snacks extras** — `<leader>.` scratch buffer · `<leader>S` select scratch ·
  `<leader>bd` delete buffer · `<leader>cR` rename file · `<leader>tg` terminal ·
  `<leader>R` view repo README in a float.

---

## AI

- **codecompanion.nvim** — chat and inline assist. Adapters cycle through
  xai, anthropic, **openrouter (default)**, ollama_remote, ollama.
  `<leader>zT` shows the current adapter; a global `toggle_adapter()` switches.
  Enabled remotely.
  > `adapter_names` and `current_adapter_index` must stay in sync — the index
  > selects the default by position. It was `4` when `copilot` led the list;
  > removing copilot shifted `openrouter` to `3`.
- **mcphub.nvim** — the real spec lives in `codecompanion.lua`, wired in as a
  codecompanion extension. Prefers a system `mcp-hub` (npm global) and falls back
  to the bundled binary when there isn't one — without that fallback a fresh
  remote gets `cmd = ""` from `exepath` and mcphub never starts, taking
  codecompanion's mcphub extension down with it.
- **supermaven** — installed, inert (see [Completion](#completion)).

**Copilot was removed** — `copilot.lua` is gone, along with codecompanion's
`copilot` adapter. It was only feeding codecompanion, never inline completion,
and its `build = ":Copilot auth"` step is interactive, so it could never
provision unattended on a remote host. The commented-out copilot/copilot-cmp
blocks in `completion.lua` were already dead and are left as-is. The dead
`mcp-hub.lua` (which just returned `{}`) was deleted too.

---

## Language-specific & misc

- **Rust** — `rust.vim` (ft-gated) + `rust_analyzer` + `rustfmt`.
- **Puppet** — `vim-puppet`, `vim-ruby`, `puppet` LSP, `puppet-lint`.
- **Markdown** — `markdown-preview.nvim`, `<leader>sm` toggles the browser preview.
- **Obsidian** — `obsidian.nvim` on markdown, vault at `~/Documents/Obsidian Vault/`,
  daily notes in `notes/dailies` (`%d-%m-%Y`). Needs `pngpaste`.
- **CSV** — `csvview.nvim`: `:CsvViewToggle`, `<Tab>`/`<S-Tab>` between fields,
  `<Enter>`/`<S-Enter>` between rows, `if`/`af` field textobjects.
- **Images** — `image.nvim` (kitty backend, ImageMagick) renders images in
  markdown/neorg/typst. `img-clip.nvim`: `<leader>ip` pastes from the system
  clipboard. `diagram.nvim` renders mermaid/plantuml/d2 blocks.
- **codesnap** — screenshot selected code. Visual mode: `<leader>ci` clipboard,
  `<leader>cs` save to `~/Pictures`, `<leader>cc` ASCII.
- **overseer** + **toggleterm** — task runner. `<leader>or`/`<leader>tr` run ·
  `<leader>oo` toggle · `<leader>ob` build · `<leader>ot` task action ·
  `<leader>oq` quick action. Reads `tasks.json`, patches nvim-dap for
  `preLaunchTask`/`postDebugTask`.
- **firenvim** — Neovim in browser textareas; disables noice and lualine there.
- **vim-css-color** — inline color previews.

---

## Keymap conflicts to know about

Real overlaps that exist by design — worth knowing before you add bindings.

| Keys | Situation |
|---|---|
| `<leader>cc` | LSP code lens (normal) vs codesnap ASCII (**visual only**) — no clash |
| `<leader>ci` | LSP incoming calls (normal) vs codesnap clipboard (**visual only**) — no clash |
| `<leader>cs` | Trouble symbols (normal) vs codesnap save (**visual only**) — no clash |
| `<leader>co*` | huez + github-theme own this prefix. Outgoing calls uses `<leader>cO` for this reason |
| `af` / `if` | treesitter function textobjects, **except** in CSV buffers with CsvView on, where csvview's field textobjects win (buffer-local) |
| `s` / `S` | substitute.nvim replaces vim's built-in `s`/`S` |
| `<C-i>` | neoscroll takes it for a small scroll, so **jumplist-forward is unavailable** in normal mode (`<C-o>` back still works) |
| `<C-e>` | neoscroll in normal/visual, cmp next-item in insert |
| `<leader>u` | undotree. Snacks toggles live under `<leader>u<letter>`, so undotree waits `timeoutlen` before firing |
| `<leader>H*` | remote-nvim sessions. Deliberately has **no** bare `<leader>H` mapping, so the prefix never stalls |

**The rule:** a mapping that is also the prefix of another mapping stalls by
`timeoutlen` (300 ms). Two of these were fixed in this pass — see below.

---

## What changed in the GoLand pass

### Bugs fixed

| File | Bug | Effect |
|---|---|---|
| `debugging.lua` | `dap.adapters.http.php = {...}` — `dap.adapters.http` is `nil` | Indexing nil **threw**, aborting the rest of the config function: the PHP and Lua adapters never registered. Same for `.http.nlua`. Now `dap.adapters.php` / `dap.adapters.nlua`. |
| `mason.lua` | `delve` never installed | `nvim-dap-go` pointed at a `dlv` binary that did not exist — **Go debugging was dead** |
| `mason.lua` | `golangci-lint` binary missing (only the langserver wrapper) | `golangci_lint_ls` had nothing to run |
| `lsp-config.lua` | `capabilities` computed then never passed to any server | gopls ran with default capabilities: no snippet support, no placeholders, degraded completion |
| `lsp-config.lua` | Diagnostic signs set in a `for` loop | Each `vim.diagnostic.config()` call **replaces** the whole `signs` table — only the last icon survived |
| `debugging.lua` | DAP signs defined via `vim.diagnostic.config()` | Wrong API for DAP, and it **wiped the LSP diagnostic icons** the moment dap loaded. Now `vim.fn.sign_define("Dap"..name)` |
| `formatting.lua` | `go = { "golangci-lint", "gofmt", "gofumpt", "gomodifytags" }` | `golangci-lint` is a linter and `gomodifytags` needs args — neither is a conform formatter. Now `{ "goimports", "gofumpt" }` |
| `formatting.lua` | `timeout_ms = 300000` on synchronous format-on-save | A five-minute blocking hang. Now `3000` |
| `linting.lua` | `go = { "golangcilint" }` on `BufReadPost` + `BufWritePost` | Duplicated `golangci_lint_ls`; two full-package runs per save. Removed |
| `lsp-config.lua` | `<leader>d` (line diagnostics) shadowed the `<leader>d*` DAP prefix | 300 ms stall on **every** debug keypress. **Moved to `<leader>cd`** |
| `lsp-config.lua` | `<leader>co` (outgoing calls, added in this pass) would have shadowed the `<leader>co*` colorscheme prefix | Caught before shipping — uses `<leader>cO` |
| `go.lua` | `<leader>Gta!` (added in this pass) would have shadowed `<leader>Gta` | Caught before shipping — renamed `<leader>GtA` |
| `lsp-config.lua` | `vim.lsp.codelens.refresh()` | Deprecated in 0.12 (removal in 0.13). Replaced with `vim.lsp.codelens.enable()`, which owns its own refresh loop — the manual autocmd went away |
| `mason.lua` | `cmake` and `dockerls` listed twice | Cosmetic |

### Added

- **`lua/plugins/go.lua`** — full gopls tuning + go.nvim command toolbox.
- **`lua/plugins/treesitter-textobjects.lua`** — structural motions.
- In `lsp-config.lua`: inlay hints on by default, code lens, call hierarchy,
  signature help, document highlight, workspace symbols, richer diagnostics config.
- In `debugging.lua`: `<leader>dn` / `<leader>dN` bind dap-go's `debug_test()`
  and `debug_last_test()`, which had no keys. Filetype-gated to Go, so they're
  buffer-local and don't occupy `<leader>dn` elsewhere.
- Mason: `delve`, `golangci-lint`, `gotests`, `impl`, `iferr`.

### Changed

- LSP navigation keymaps moved from `<cmd>Telescope ...<CR>` to snacks pickers,
  matching the rest of the config. Telescope stays installed — neoclip,
  obsidian, overseer and goto-preview still depend on it.

### One breaking change

**`<leader>d` → `<leader>cd`** for line diagnostics. This is the only binding
that moved out from under existing muscle memory. It had to: as a complete
mapping it was shadowing the entire `<leader>d*` debug prefix.

---

## What changed in the remote-debugging pass

### Added

- **`lua/plugins/dap-remote.lua`** — remote Go debugging over SSH on
  `<leader>dR`, with an `~/.ssh/config` host picker, three delve targets,
  per-host remote-root caching, plus `:DapRemoteSelfCheck` and
  `:DapRemoteForgetRoot`. No new plugins. See
  [Remote Go debugging over SSH](#remote-go-debugging-over-ssh).
- **`lua/plugins/remote-nvim.lua`** — full remote development on `<leader>Hs`:
  Neovim and this config provisioned on the remote, local TUI attached. One new
  plugin, pinned; its three dependencies were already present. See
  [Remote development](#remote-development-whole-editor-on-the-remote).

### Changed

- `GO-WORKFLOW.md`'s "Attaching to a running process" advice was stale: it told
  you to run `dlv --headless --listen=:2345` on the remote and hand-write a
  matching config into `.vscode/launch.json`. `<leader>dR` now does this, and
  `dlv --headless` was the wrong server for a DAP client anyway.

### Avoided

- Giving `dap-remote.lua` a `config` function. lazy.nvim merges only
  `opts/cmd/event/ft/keys`; a second `config` for `nvim-dap` would have shadowed
  `debugging.lua`'s and silently taken out the DAP signs, dap-go setup and the
  PHP/Lua/JS adapters. Verified after the fact: all four still register.

---

## What changed in the remote-profile pass

### Bugs fixed

| File | Bug | Effect |
|---|---|---|
| `init.lua` | `git`/`checker`/`change_detection` passed as lazy.setup's **second** argument | Silently discarded — `lazy.setup(spec, opts)` drops arg 2 when arg 1 has a `spec` key (`lazy/init.lua:32-38`). Proven at runtime: `checker.enabled` was `false` despite being set `true`. **There was no update checker.** Merged into the first table |
| `remote-nvim.lua` | `copy_dirs.config.dirs = "*"` (default) | Shipped the whole config dir including `.git` — 752K of 1.2M — to every host on every connect. Now an allowlist; payload 1.2M → 336K |
| `codecompanion.lua` | mcphub pinned to `cmd = vim.fn.exepath("mcp-hub")` with `use_bundled_binary = false` | On a host without a system `mcp-hub`, `exepath` returns `""` and mcphub never starts, taking codecompanion's mcphub extension with it. Now falls back to the bundled binary |
| `codecompanion.lua` | `current_adapter_index` is positional | Removing `copilot` from the head of `adapter_names` silently moved the default from openrouter to ollama_remote. Index corrected 4 → 3 |

### Added

- **Remote profile** — `vim.g.nvim_remote` plus one `defaults.cond`; 9 plugins
  off remotely, Mason and treesitter lists trimmed. See
  [Remote profile](#remote-profile).
- **`scripts/remote-bootstrap.sh`** — idempotent Debian/Ubuntu provisioning.

### Removed

- **copilot.lua** — fed codecompanion only, never inline completion, and its
  `build = ":Copilot auth"` can't run unattended.
- **mcp-hub.lua** — dead file, `return {}`; the live spec is in `codecompanion.lua`.
- **`theme_config_module = "modules.themes"`** from `huez.lua` — there is no
  `lua/modules/` directory, so huez logged "directory not found to load themes
  from" and loaded nothing. Invisible because huez defaults
  `suppress_messages = true`, so it was silently dead config.

### Language audit (Go, PHP, TS/JS, Java, Python)

| File | Finding | Effect |
|---|---|---|
| everywhere | **Java had no support at all** | No server, formatter, linter, debugger or parser. Only mention was `auto-pairs.lua:17` disabling a treesitter check. Added `lua/plugins/java.lua` (jdtls + java-debug + java-test), `google-java-format`, and the `java` parser |
| `formatting.lua` | `php = { "php_cs_fixer", "phpstan" }` | phpstan is a static analyser, not a formatter — the identical mistake golangci-lint was making for Go. Moved to nvim-lint |
| `linting.lua` | no `php` entry | `phpcs` and `phpstan` were installed via Mason and **never wired to anything**. `php = { "phpcs" }` added; phpstan left manual because it's slow enough to repeat the golangci-lint problem |
| `formatting.lua` | `python` entry commented out | Python had no formatter, so format-on-save silently did nothing (pyright doesn't format). Now `ruff_organize_imports` + `ruff_format` |
| `debugging.lua` | no `python` adapter | debugpy was installed but nothing registered an adapter, so **Python debugging didn't work at all**. Added nvim-dap-python pointed at Mason's debugpy venv |
| `treesitter.lua` | `java`, `python`, `gomod`, `gosum` missing | No parsers for two of the six working languages, and Go module files were unparsed |
| `mason.lua` | `isort` and `black` listed twice | Duplicates removed |
| `mason.lua` | remote list was Go-only | My earlier remote trim broke PHP, TS/JS and Python entirely. Rebuilt around the six languages |
| `debugging.lua` | `vscode-js-debug` disabled remotely | My earlier change; wrong, since TS/JS debugging is wanted remotely. Re-enabled |
| `java.lua` | jdtls bundles globbed **all** of `java-test/extension/server/*.jar` | That directory holds ~27 junit/jacoco/opentest4j jars — test *runtime* deps, not jdtls OSGi plugins. jdtls tried to start them as bundles and failed: `BundleException: Could not resolve module: com.microsoft.java.test.plugin — Unresolved requirement: Require-Bundle: org.objectweb.asm`. Narrowed to the two `*.plugin-*.jar` files; bundle failures went 1 → 0 |
| `java.lua` | jdtls relied on `java` from PATH | Homebrew's openjdk is keg-only, so PATH `java` is Apple's stub and jdtls never started on macOS. Now resolves a Homebrew JDK and passes `--java-executable`, plus registers project `runtimes` |

### Colorscheme

- **`lua/plugins/monokai.lua`** added — `tanvirtin/monokai.nvim` declared
  explicitly at `priority = 1000` and set as the default, plus
  `fallback = "monokai"` in huez. It was already installed and active locally,
  but only via huez's machine-local state, so a fresh clone or remote host got
  `default`. See [UI](#ui).

---

## Troubleshooting

```vim
:checkhealth              " everything
:Lazy                     " plugin status, update, profile startup
:Mason                    " tool install status
:LspInfo                  " attached servers for this buffer
:LspRestart               " or <leader>rs
:ConformInfo              " which formatter ran, and why
:messages                 " deprecation warnings and errors
```

**Go-specific checks**

```vim
:lua =vim.lsp.get_clients({bufnr=0})[1].settings.gopls   " gopls settings actually in effect
:lua =vim.lsp.inlay_hint.is_enabled({bufnr=0})           " inlay hints on?
:lua =vim.lsp.codelens.get(0)                            " codelenses in this buffer
:lua =vim.fn.exepath('dlv')                              " delve found?
:lua =vim.fn.exepath('golangci-lint')
```

**Per-language checks**

```vim
:lua =vim.fn.exepath('php')      " PHP: phpcs/phpstan/php_cs_fixer need this
:lua =vim.fn.exepath('node')     " intelephense, ts_ls, eslint, prettierd
:lua =vim.fn.exepath('java')     " Java: must be 21+; see the macOS note below
:JdtCompile                      " Java: force a rebuild (jdtls only)
:lua =require('dap').adapters.java  " Java: nil until jdtls attaches
```

**Common situations**

- *No completion placeholders in Go* — `usePlaceholders` needs snippet
  capabilities. Check `vim.lsp.config("*")` in `lsp-config.lua` still passes
  cmp's capabilities.
- *PHP format-on-save does nothing, or `exec: php: not found`* — there's no `php`
  interpreter on this machine. `phpcs`, `phpstan` and `php_cs_fixer` are PHP
  programs; intelephense keeps working because it's Node. Not a config problem —
  see [runtimes](#language-runtimes-are-a-separate-question-from-mason).
- *Java gets no LSP, only harper_ls* — jdtls needs a **JDK 21+**. On macOS,
  Homebrew's openjdk is keg-only so PATH `java` is Apple's stub; `java.lua`
  handles this by locating `/opt/homebrew/opt/openjdk@21|@26` itself. If you have
  no JDK at all: `brew install openjdk@21`. Check `:LspLog` for
  `returned non-zero exit status 1`.
- *`<leader>J*` keymaps missing in a Java file* — they're set in jdtls's
  `on_attach`, so they only exist once jdtls actually attaches. Same root cause as
  above.
- *Java file is full of "cannot resolve method getFoo()/builder()/log"* — Lombok.
  jdtls needs the lombok javaagent; `java.lua` picks the jar out of
  `~/.gradle/caches`, so a project whose deps were never downloaded has none to
  find. Run `./gradlew compileJava` once, then restart jdtls. Confirm with
  `:lua =vim.lsp.get_clients({name="jdtls"})[1].config.cmd` — the
  `--jvm-arg=-javaagent:` entry should be there.
- *"Cannot find a Java installation … matching languageVersion=N"* — Gradle can't
  see Homebrew's keg-only JDKs. `~/.gradle/gradle.properties` sets
  `org.gradle.java.installations.paths`; that file lives outside this repo, so a
  new machine needs it re-created (or `brew install`ed JDKs symlinked into
  `/Library/Java/JavaVirtualMachines`).
- *jdtls attaches but debugging or main-class detection misbehaves* — jdtls needs a
  real project root (`pom.xml`, `build.gradle`, `mvnw`, `gradlew`). A malformed
  `pom.xml` produces `Could not resolve java executable: Index 1 out of bounds`
  from java-debug, which is the project being invalid, not the config.
- *`eslint` doesn't attach to a TS/JS file* — the eslint server only starts when it
  finds an eslint config (`eslint.config.js`, `.eslintrc*`) in the project. Correct
  behaviour, not a failure.
- *Codelens not showing* — gopls emits `test` lenses only in `_test.go`, and
  `tidy` / `upgrade_dependency` only in `go.mod`. An ordinary `.go` file
  legitimately has none.
- *Format on save does nothing* — `:ConformInfo`. If the formatter binary is
  missing, conform silently falls back to the LSP.
- *A key takes ~300 ms to fire* — it's a prefix of another mapping. Check
  `<leader>fk` (keymap picker) and see
  [Keymap conflicts](#keymap-conflicts-to-know-about).
- *Adding a new language server* — add it to `ensure_installed` in
  `mason.lua`; mason-lspconfig auto-enables it. Add a
  `vim.lsp.config("<name>", {...})` block only if you need to tune it.
