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
 └─ lazy.setup{ import = "plugins" }   ← every lua/plugins/*.lua
```

`init.lua` short-circuits when `vim.g.vscode` is set (VSCode Neovim extension)
— options and keymaps load, no plugins. It also resolves the Python provider
from `$PYTHON3_HOST_PROG`, falling back to `~/.pyenv/versions/neovim3/bin/python`.

Each file in `lua/plugins/` returns a lazy.nvim spec. Files returning `{}`
(`plugins.lua`, `rest.lua`, `mcp-hub.lua`, `console-inline.lua`) are disabled
placeholders — harmless, kept for easy re-enabling.

`lazy.nvim` is set to auto-check for updates silently (`checker.enabled`,
`notify = false`) and not to nag on config changes (`change_detection.notify = false`).

**Order matters in exactly two places:** plugin `init` functions run at
startup before anything loads (this is where gopls settings are registered),
and `priority = 1000` plugins (`github-theme`, `snacks`) load first.

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

`lua/plugins/debugging.lua` — nvim-dap.

**Adapters:** Go (`nvim-dap-go` → delve), Node/Chrome/Edge (`vscode-js-debug`),
PHP (Xdebug), Lua (`one-small-step-for-vimkind`).

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

DAP UI opens automatically on session start: scopes, breakpoints, stacks and
watches in a 30-col left panel; console in a 10-row bottom panel.
`nvim-dap-virtual-text` shows variable values inline as you step.

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

- **github-theme** — default colorscheme. `<leader>cos` cycles the 11 GitHub
  variants (dark, dimmed, high contrast, colorblind, tritanopia, light…).
- **huez** — colorscheme manager: `<leader>cop` picker · `<leader>coi`
  installed · `<leader>cof` favorites · `<leader>col` registry · `<leader>coe` ensured.
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
  copilot, xai, anthropic, **openrouter (default)**, ollama_remote, ollama.
  `<leader>zT` shows the current adapter; a global `toggle_adapter()` switches.
- **mcp-hub** — spec file is currently empty (`return {}`), but codecompanion
  still references the `mcp-hub` binary and lualine shows its status component.
- **copilot.lua** — `:Copilot`, suggestions and panel disabled (it feeds
  codecompanion, not inline completion).
- **supermaven** — installed, inert (see [Completion](#completion)).

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

**Common situations**

- *No completion placeholders in Go* — `usePlaceholders` needs snippet
  capabilities. Check `vim.lsp.config("*")` in `lsp-config.lua` still passes
  cmp's capabilities.
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
