# Go Engineering Workflow

How to actually do Go work in this Neovim setup — writing, reading, refactoring,
testing, debugging, troubleshooting, shipping.

Organized by **what you're trying to do**, not by which plugin does it.
For the plugin-by-plugin reference see [CONFIG.md](CONFIG.md).

> Leader is `<Space>`. Splits navigate with `n/e/i/o` (ColemakDH), not `h/j/k/l`.

**Contents**

- [The twelve keys](#the-twelve-keys)
- [Opening a Go project](#opening-a-go-project)
- [Writing code](#writing-code)
- [Reading code you didn't write](#reading-code-you-didnt-write)
- [Refactoring](#refactoring)
- [Testing](#testing)
- [Debugging](#debugging)
- [Troubleshooting and diagnostics](#troubleshooting-and-diagnostics)
- [Running and building](#running-and-building)
- [Dependencies and modules](#dependencies-and-modules)
- [Git and code review](#git-and-code-review)
- [End-to-end recipes](#end-to-end-recipes)
- [Full Go key reference](#full-go-key-reference)
- [Gotchas](#gotchas)

---

## The twelve keys

If you learn nothing else, learn these. They cover ~90% of a Go day.

| Key | Does |
|---|---|
| `gd` | Go to definition |
| `gR` | Find all references |
| `K` | Show docs for the symbol under cursor |
| `<leader>ca` | **Code actions** — the entry point to every refactor and quick-fix |
| `<leader>rn` | Rename symbol across the project |
| `<leader>ff` | Find file |
| `<leader>fs` | Grep the project |
| `<leader>ttn` | Run the test under the cursor |
| `<leader>db` | Toggle breakpoint |
| `<leader>dc` | Start / continue debugging |
| `<leader>xx` | Show all diagnostics |
| `<leader>Ga` | Jump between a file and its test |

`<leader>ca` is the one people underuse. In Go it's where extract-function,
inline, invert-if, fill-struct, implement-interface and every staticcheck
quick-fix live.

---

## Opening a Go project

```bash
cd ~/code/my-service && nvim .
```

What happens automatically, no action needed:

1. **gopls starts** (rooted at `go.mod` / `.git`) and indexes the module.
2. **golangci_lint_ls starts** alongside it for the wider lint set.
3. **Inlay hints turn on** — parameter names and inferred types appear inline.
4. **Codelenses render** — `run test` above test functions, `go mod tidy` in `go.mod`.
5. **Imports auto-fold**, along with comments.
6. **Gitsigns** decorates the gutter and turns on inline blame.
7. **Minimap** opens on the right.

First-open on a large module takes a few seconds while gopls indexes.
Completion and diagnostics will be thin until it finishes — `:LspInfo` tells
you what's attached.

**Session handling.** Auto-restore is off by default. `<leader>ws` saves the
session for this directory, `<leader>wr` restores it. The dashboard's `s` key
restores too.

---

## Writing code

### Completion

Type, and completion appears automatically. `nvim_lsp` (gopls) is the primary
source, with buffer, path and snippet sources behind it.

| Key | Mode | Action |
|---|---|---|
| `<C-e>` | insert | Next candidate |
| `<C-i>` | insert | Previous candidate |
| `<CR>` | insert | Confirm |
| `<Tab>` | insert | Expand/jump snippet, else confirm |
| `<C-x>` | insert | Dismiss |
| `<C-k>` | insert/normal | Signature help — which parameter am I on |

Two gopls settings make this feel like an IDE:

- **`completeUnimported`** — type `ctx.` or `errors.Is` for a package you
  haven't imported and gopls completes it *and adds the import*. You almost
  never write import lines by hand.
- **`usePlaceholders`** — confirming a function completion fills in its
  parameters as tab-stops. `<Tab>` walks them.

Autopairs closes brackets and adds `()` after function completions.

### Imports

You mostly don't manage them. `goimports` runs on every save (adding what's
used, removing what isn't). To do it explicitly, `<leader>ca` →
**Organize Imports**.

### Struct tags

Cursor on a struct, then:

| Key | Action |
|---|---|
| `<leader>Gta` | Add tags (json by default) |
| `<leader>Gtr` | Remove tags |
| `<leader>Gtc` | Clear all tags |

```go
type User struct {          →    type User struct {
	Name string                       Name string `json:"name,omitempty"`
	Age  int                          Age  int    `json:"age,omitempty"`
}                                }
```

For a non-json tag, run the command form: `:GoAddTag yaml` or `:GoAddTag db`.

### Error handling boilerplate

With the cursor on a line returning an error, `<leader>Ge` expands the
`if err != nil { return ... }` block with the correct zero values for the
enclosing function's return signature. This is GoLand's `err` live template.

### Filling in structs and switches

- `<leader>Gf` — **fill struct**: turns `User{}` into every field with zero values.
- `<leader>Gs` — **fill switch**: expands a switch over a type or enum into all cases.

Both are also available through `<leader>ca` (gopls
`refactor.rewrite.fillStruct` / `fillSwitch`), which is worth preferring since
it works on the exact cursor range.

### Implementing an interface

Two routes:

1. **`<leader>ca` → Implement Interface** (gopls
   `refactor.rewrite.implementInterface`) — cursor on a type that's being used
   where an interface is expected; gopls stubs the missing methods.
2. **`<leader>Gi`** (`impl`) — prompts for a receiver and interface name.
   Better when you want to stub an interface the type doesn't reference yet.

There's also a quick-fix path: when a type fails to satisfy an interface,
gopls raises a diagnostic and `<leader>ca` on it offers **Declare missing methods**.

### Generating tests

| Key | Generates |
|---|---|
| `<leader>Gtt` | Table-driven test for the function under the cursor |
| `<leader>GtT` | Tests for every exported function in the file |
| `<leader>GtA` | Tests for every function in the file |

Output lands in `<file>_test.go`, table-driven, ready to fill in cases.

### Comments and docs

`<leader>ca` → **Add documentation** (gopls `source.doc`) writes a doc comment
stub. `:GoCmt` does the same via go.nvim.

Comment toggling: `gcc` line, `gc` operator (`gcap` comments a paragraph),
`gb` block, `gco`/`gcO` open a comment below/above.

### Formatting

Automatic on save: `goimports` then `gofumpt` (stricter gofmt — no empty
lines after `{`, no redundant parens, sorted imports in one block).
`<leader>mp` formats manually; works on a visual selection.

Save takes >3s? conform gives up (`timeout_ms = 3000`) and the file saves
unformatted. That usually means a huge file or a stalled binary.

---

## Reading code you didn't write

This is where an editor earns its keep. Go's indirection — interfaces,
embedded types, generated code — makes navigation the core skill.

### Jumping

| Key | Goes to |
|---|---|
| `gd` | Definition |
| `gD` | Declaration |
| `gR` | **All references** (picker) |
| `gi` | Implementations — every type satisfying this interface |
| `gt` | Type definition — from a variable to its type |
| `<C-o>` | Back where you came from |
| `<C-t>` | Back up the tag stack |

`gi` on an interface method is the Go-specific superpower: it lists every
concrete implementation, which is the thing plain grep can't do.

> **`<C-i>` does not jump forward.** neoscroll owns it for scrolling. `<C-o>`
> back works normally; to go forward use the jumplist picker or retrace.

### Peeking without leaving

`goto-preview` opens a definition in a floating window over your current
buffer — you read it and dismiss without losing your place. Default `gp`
mappings; previews stack, so you can peek from inside a peek.

Use this when you want to check a type's shape mid-thought. Use `gd` when
you're actually going there.

### Call hierarchy

| Key | Shows |
|---|---|
| `<leader>ci` | **Incoming** — who calls this function |
| `<leader>cO` | **Outgoing** — what this function calls |

Incoming calls is the fastest way to answer "is this safe to change" and
"how does execution reach here".

### Symbols and structure

| Key | Shows |
|---|---|
| `<leader>cS` | Document symbols (picker) — this file's outline |
| `<leader>cs` | Symbols in Trouble — persistent side panel |
| `<leader>cw` | **Workspace symbols** — fuzzy search every symbol in the module |
| `<leader>wo` | Pick a breadcrumb component (dropbar) |

`<leader>cw` is how you find `func (s *Server) handleFoo` when you only
remember "handleFoo". Faster than grep and type-aware.

The **winbar breadcrumbs** (dropbar) always show where you are:
`package › type › method`. Click or `<leader>wo` to jump up a level.

### Reading dense functions

- **Folding** — `<Left>` closes, `<Right>` opens. Imports and comments are
  pre-folded. Fold text shows line count plus diagnostic and git counts.
- **`]f` / `[f`** — jump to the next/previous function.
- **`]c` / `[c`** — jump between type declarations.
- **`]]` / `[[`** — jump between references of the symbol under the cursor,
  right there in the buffer. Excellent for tracing a variable through a long function.
- **`vaf`** — visually select the whole enclosing function to see its extent.

### Searching

| Key | Searches |
|---|---|
| `<leader>fs` | Grep the project |
| `<leader>fw` | Grep the word under cursor (or visual selection) |
| `<leader>fl` | Lines in the current buffer |
| `<leader>fgb` | Grep only open buffers |
| `<leader>ff` | Find file by name |
| `<leader>fr` | Recent files |

Prefer `gR` / `<leader>cw` over grep for anything gopls understands — grep
finds string matches, gopls finds *the actual symbol*.

### Reading the assembly

`<leader>ca` → **source.assembly** — gopls will show the compiled assembly for
a function. Useful when you're chasing an optimization or wondering whether
something inlined.

---

## Refactoring

Everything below is one keystroke: **`<leader>ca`** with the cursor on the
relevant code (or a visual selection). This is the full verified list gopls
advertises in this setup.

### Extract

| Action | Use |
|---|---|
| Extract function | Select statements → new function, params inferred |
| Extract method | Same, as a method on the enclosing receiver |
| Extract variable | Select an expression → named local |
| Extract constant | Select a literal → named constant |
| Extract variable (all occurrences) | Replaces every identical expression in scope |
| Extract constant (all occurrences) | Same, for constants |
| Extract to new file | Move the declaration under the cursor into its own file |

Select the statements in visual mode first, then `<leader>ca`. gopls works out
which variables must become parameters and which become return values.

### Inline

| Action | Use |
|---|---|
| Inline call | Replace a call with the function's body |
| Inline variable | Replace a variable with its value |

The inverse of extract — useful for collapsing an indirection that no longer
earns its place.

### Rewrite

| Action | Use |
|---|---|
| Invert if | Flip a condition and swap the branches — the standard early-return cleanup |
| Fill struct | Every field, zero-valued |
| Fill switch | Every case of a type switch or enum |
| Implement interface | Stub the missing methods |
| Remove unused parameter | Deletes the param **and fixes every call site** |
| Split lines / Join lines | Reflow multi-element expressions |
| Change quote | Interpreted ↔ raw string literal |
| Move type | Move a type declaration to another file |
| Split package | Break a package apart |

**Invert if** and **remove unused parameter** are the two that save the most
time. Removing a parameter by hand means finding every caller; gopls does the
whole edit atomically.

### Rename

`<leader>rn` — type the new name, `<CR>`. Renames across the entire module,
including comments and doc references where they match. This is a real
type-aware rename, not search-and-replace.

### Fix everything fixable

`<leader>ca` → **source.fixAll** applies every auto-fixable diagnostic in the
file at once. Good before committing.

### Free symbols

`<leader>ca` → **source.freesymbols** highlights which identifiers in a
selection come from outside it. Use it before extracting a big block to see
what the new function will need as parameters.

---

## Testing

Two systems, deliberately. Use **neotest** for the interactive loop and
**codelens** for a one-off run.

### The loop

| Key | Runs |
|---|---|
| `<leader>ttn` | The test under the cursor |
| `<leader>ttf` | Every test in this file |
| `<leader>tta` | Every test in the project |
| `<leader>ttl` | Whatever you ran last |
| `<leader>ttx` | Stop the running test |
| `<leader>tts` | Toggle the summary panel |
| `<leader>tto` | Toggle the output panel |

Typical rhythm: `<leader>ttn` to run the one you're working on, `<leader>ttl`
to re-run it after each edit, `<leader>ttf` before you commit.

### Reading results

Failures appear three ways at once:

- **Diagnostics** on the failing line (ERROR severity) — so `]d` walks to them
- **Virtual text and signs** inline: `✔` passed, `✖` failed, `⟳` running, `➜` skipped
- **Quickfix**, populated and opened automatically

`<leader>tto` opens the raw `go test` output when the diagnostic isn't enough.

### The summary panel

`<leader>tts` opens a tree of all tests. Inside it:

| Key | Action |
|---|---|
| `r` | Run this test / subtree |
| `d` | Debug this test |
| `w` | **Watch** — re-run automatically on save |
| `m` then `R` | Mark several tests, then run all marked |
| `m` then `D` | Debug all marked |
| `n` / `p` | Jump to next / previous failure |
| `o` | Show output |
| `zo` / `zO` | Expand / expand all |
| `a` | Attach to a running test |

**Watch mode (`w`)** is the closest thing to a real feedback loop: mark the
package you're working on and every save re-runs it.

### Codelens runs

On any `_test.go`, gopls renders `run test` above each test function.
`<leader>cc` runs the one under the cursor. Lighter than neotest for a quick check.

### Table-driven tests

Generate with `<leader>Gtt`, fill in the cases. neotest understands Go
subtests, so each `t.Run` case appears as its own node in the summary and can
be run individually with `<leader>ttn` from inside it.

### Coverage

| Key | Action |
|---|---|
| `<leader>Gc` | Run tests with coverage, show gutter marks |
| `<leader>GC` | Toggle the gutter marks |

Covered lines mark green, uncovered red — GoLand's coverage view.

### Jumping to and from tests

`<leader>Ga` toggles between `foo.go` and `foo_test.go`, creating the test
file if it doesn't exist. `<leader>GA` opens it in a vertical split, which is
the better default when you're writing tests against the implementation.

---

## Debugging

Delve via nvim-dap. Installed at `~/.local/share/nvim/mason/bin/dlv`.

### Breakpoints

| Key | Action |
|---|---|
| `<leader>db` | Toggle breakpoint |
| `<leader>dB` | **Conditional** breakpoint — prompts for an expression |
| `<leader>dq` | Clear all breakpoints |

Conditional breakpoints take Go expressions: `i > 100`, `user.ID == "abc"`,
`err != nil`. Essential for breaking inside a loop on iteration 5000.

### Starting a session

`<leader>dc` starts or continues. You'll be asked which configuration:

| Configuration | Use |
|---|---|
| **Debug** | Debug the current file's package |
| **Debug (Arguments)** | Same, prompts for CLI args |
| **Debug (Arguments & Build Flags)** | Also prompts for build flags (`-tags=integration`) |
| **Debug Package** | Debug a package you pick |
| **Attach** | Attach to an already-running process |
| **Debug test** | Debug the test package |
| **Debug test (go.mod)** | Debug tests rooted at the module |

`<leader>da` skips the menu and goes straight to run-with-args.
`.vscode/launch.json` is read automatically when present, so configs shared
with VSCode teammates just work.

### Stepping

| Key | Action |
|---|---|
| `<leader>dc` | Continue |
| `<leader>do` | Step **over** |
| `<leader>di` | Step **into** |
| `<leader>dO` | Step **out** |
| `<leader>dC` | Run to cursor |
| `<leader>dg` | Move the instruction pointer here without executing |
| `<leader>dp` | Pause |
| `<leader>dt` | Terminate |
| `<leader>dl` | Re-run the last session |

### Inspecting state

The DAP UI opens automatically: scopes, breakpoints, stacks and watches in a
left panel, console at the bottom.

| Key | Action |
|---|---|
| `<leader>de` | **Evaluate** — expression under cursor, or visual selection |
| `<leader>dh` | Hover widget for the symbol under cursor |
| `<leader>dr` | Toggle the REPL |
| `<leader>du` | Toggle the whole UI |
| `<leader>ds` | Session info |
| `<leader>dj` / `<leader>dk` | Move down / up the call stack |

**Variable values also appear inline** next to each declaration as you step
(`nvim-dap-virtual-text`) — usually you don't need to open scopes at all.

`<leader>de` on a visual selection evaluates arbitrary expressions:
select `len(users) > 0 && users[0].Active` and evaluate it in the live frame.

Moving up the stack with `<leader>dk` re-scopes evaluation to that frame —
that's how you inspect a caller's locals.

### Debugging tests

Four ways, pick by context:

| Key | Route |
|---|---|
| `<leader>ttdn` | Through **neotest** — best default, integrates with the summary panel |
| Summary panel → `d` | Debug a test you've navigated to in the tree |
| `<leader>dn` | **dap-go direct** — delve driven straight off the test function under the cursor |
| `<leader>dN` | dap-go: re-debug the last test |

Set your breakpoint first, then run — the debugger stops there.

**Why two routes?** neotest discovers tests through its adapter, which
occasionally misses things — files behind build tags, generated tests, unusual
layouts. `<leader>dn` skips discovery entirely: dap-go reads the test function
under the cursor and builds the delve invocation from it. When `<leader>ttdn`
says it can't find a test but you're clearly sitting in one, `<leader>dn` is
the fallback.

`<leader>dn` and `<leader>dN` only exist in Go buffers.

### Attaching to a running process

Pick the **Attach** configuration at `<leader>dc` and choose the process.
Works for a server you started outside Neovim. For containers or remote hosts,
run `dlv --headless --listen=:2345` there and add a matching remote config to
`.vscode/launch.json`.

> `:GoDebug` does **not** exist here — go.nvim's debug module is deliberately
> disabled so it can't conflict with nvim-dap-go. Use `<leader>d*`.

---

## Troubleshooting and diagnostics

### Where problems show up

Three independent analyzers run:

| Source | Catches |
|---|---|
| **gopls + staticcheck** | Type errors, `nilness`, `shadow`, `unusedparams`, `unusedwrite`, `unusedvariable`, `useany`, plus the whole staticcheck set |
| **golangci_lint_ls** | Your repo's `.golangci.yml` — whatever the team configured |
| **neotest** | Test failures, as diagnostics |

### Working through them

| Key | Action |
|---|---|
| `<leader>cd` | Show the full diagnostic under the cursor (float) |
| `]d` / `[d` | Next / previous diagnostic, with a float |
| `<leader>D` | This buffer's diagnostics (picker) |
| `<leader>fd` | All diagnostics (picker) |
| `<leader>xx` | **All diagnostics in Trouble** — the panel to work from |
| `<leader>xX` | This buffer only, in Trouble |
| `<leader>ca` | Quick-fix the one under the cursor |

Workflow: `<leader>xx` to see everything, `<CR>` to jump to one, `<leader>ca`
to fix it, repeat. `<leader>ca` → **source.fixAll** clears every auto-fixable
one in the file in a single step.

Truncated messages: `<leader>cd` shows the full text. Long staticcheck
explanations often don't fit as virtual text.

### Vulnerability scanning

`<leader>Gv` runs `govulncheck` against your dependency tree and reports known
CVEs that your code actually reaches. Also available as a gopls codelens in
`go.mod` via `<leader>cc`.

### When gopls misbehaves

Symptoms: stale diagnostics, completions from deleted code, "no definition found"
on something that clearly exists.

```vim
<leader>rs        " restart LSP — fixes most of it
:LspInfo          " what's attached, and its root directory
:checkhealth vim.lsp
```

Root directory is the usual culprit. gopls roots at `go.mod`; opening a file
from a different module in the same session can attach it to the wrong root.

For a genuinely corrupt cache:

```bash
rm -rf ~/Library/Caches/gopls    # macOS
```

### When lint results look wrong

`golangci_lint_ls` runs the `golangci-lint` binary against your repo config.
Check they agree:

```vim
:lua =vim.fn.exepath('golangci-lint')
```

```bash
golangci-lint run ./...          # same result in the terminal?
```

If the terminal disagrees with the editor, it's usually a version skew between
Mason's binary and the one CI uses.

### Chasing a panic

1. Copy the panic's file:line.
2. `<leader>ff` to that file, `:<line>` to jump.
3. `<leader>ci` (incoming calls) to see how execution reached there.
4. Set a conditional breakpoint (`<leader>dB`) on the panicking condition.
5. `<leader>dc` → reproduce → inspect with `<leader>de`.

---

## Running and building

| Key / command | Action |
|---|---|
| `<leader>tg` | Toggle a terminal |
| `<leader>or` or `<leader>tr` | Overseer: run a task |
| `<leader>oo` | Toggle the task list |
| `<leader>ob` | Build a task interactively |
| `<leader>ot` / `<leader>oq` | Task action / quick action |
| `:GoRun` | `go run` the current package |
| `:GoBuild` | `go build` |
| `:GoTest` | `go test` (plain — neotest is usually nicer) |
| `:GoGenerate` or `<leader>Gg` | `go generate` |

Overseer reads `tasks.json`, so VSCode task definitions work. It also patches
nvim-dap to honor `preLaunchTask` / `postDebugTask` — a build step can run
automatically before each debug session.

---

## Dependencies and modules

| Key | Action |
|---|---|
| `<leader>Gm` | `go mod tidy` |
| `<leader>cc` in `go.mod` | Run the codelens under the cursor |

Open `go.mod` and gopls renders codelenses for **tidy**, **upgrade dependency**
and **run govulncheck**. `<leader>cc` on the line runs it — this is the
easiest way to bump a single dependency.

`K` on a `require` line shows the module's documentation.

---

## Git and code review

### While writing

| Key | Action |
|---|---|
| `]h` / `[h` | Next / previous hunk |
| `<leader>hp` | Preview the hunk |
| `<leader>hs` / `<leader>hr` | Stage / reset the hunk (works on a visual range) |
| `<leader>hS` / `<leader>hR` | Stage / reset the whole buffer |
| `<leader>hu` | Undo a stage |
| `<leader>hd` / `<leader>hD` | Diff this file / against `~` |
| `<leader>hb` | Blame this line |
| `ih` | Hunk textobject — `vih`, `dih` |

Inline blame is always on, so you can see who last touched each line.

### Committing

`<leader>gg` opens lazygit — stage, commit, push, rebase, resolve. It's a full
TUI and generally faster than doing it through Neovim.

`<leader>gl` repo log · `<leader>gf` current file's history ·
`<leader>fgs` git status picker · `<leader>fgl` git log picker.

### Reviewing PRs

octo.nvim brings GitHub in-editor:

| Key | Action |
|---|---|
| `<leader>lp` | List PRs |
| `<leader>lP` | My PRs |
| `<leader>lh` | List issues |
| `<leader>lH` | My issues |
| `<leader>lR` | Review-requested |

Open a PR and you get the diff, threads and review actions in normal buffers —
so `gd`, `gR` and `<leader>ca` all work while reviewing. That's the real
advantage over the web UI: you can navigate the code you're reviewing.

`<leader>gbr` opens the current file on GitHub. In visual mode, `<leader>gbc`
copies a permalink to the selected lines — handy for pasting into a review.

---

## End-to-end recipes

### Adding an endpoint to a service

```
<leader>cw  handleUser        → find a similar existing handler
<leader>Ga                    → check its test to learn the pattern
gd / gR                       → trace how it's registered
<Space>                       → write the handler; completeUnimported adds imports
<leader>Ge                    → error boilerplate as you go
<leader>Gta                   → tag the request/response structs
<leader>Gtt                   → generate the test
<leader>ttf                   → run the file's tests
<leader>tts → w               → watch mode while you iterate
<leader>ca → source.fixAll    → clear lint before committing
<leader>gg                    → commit
```

### A test just started failing

```
<leader>tta          → run everything, confirm the blast radius
<leader>tts          → summary panel, n / p to walk failures
<leader>tto          → raw output if the diagnostic is too terse
<leader>db           → breakpoint at the suspect line
<leader>ttdn         → debug the failing test  (<leader>dn if neotest can't find it)
<leader>do / <leader>di   → step until it diverges
<leader>de           → evaluate the expression that's wrong
<leader>dk           → move up the stack to check the caller's state
```

### Understanding an unfamiliar package

```
<leader>ff  <pkg>/           → open the package
<leader>cS                   → outline of this file
<leader>cw                   → search symbols across the module
gi                           → on an interface: every implementation
<leader>ci                   → on a function: who calls it
]f / [f                      → skim function to function
gp                           → peek definitions without losing your place
<leader>Ga                   → read the tests; they document intent
```

### Cleaning up a long function

```
vaf                          → select the whole function, see its size
<leader>ca → free symbols    → what does this block depend on?
V<motion> then <leader>ca    → extract function / extract method
<leader>ca → invert if       → flatten nesting into early returns
<leader>ca → remove unused parameter   → fixes all call sites too
<leader>rn                   → rename anything now poorly named
<leader>ttf                  → prove you didn't break it
```

### Bumping a dependency

```
<leader>ff go.mod
<leader>cc                   → codelens: upgrade dependency
<leader>Gm                   → go mod tidy
<leader>Gv                   → govulncheck
<leader>tta                  → full test run
```

---

## Full Go key reference

### LSP

| Key | Action |
|---|---|
| `gd` / `gD` | Definition / declaration |
| `gR` | References |
| `gi` | Implementations |
| `gt` | Type definition |
| `K` | Hover docs |
| `<C-k>` | Signature help |
| `<leader>ca` | Code actions |
| `<leader>rn` | Rename |
| `<leader>rs` | Restart LSP |
| `<leader>ci` / `<leader>cO` | Incoming / outgoing calls |
| `<leader>cS` / `<leader>cw` | Document / workspace symbols |
| `<leader>cc` | Run codelens |
| `<leader>cd` | Line diagnostics |
| `<leader>D` | Buffer diagnostics |
| `[d` / `]d` | Prev / next diagnostic |
| `<leader>uh` | Toggle inlay hints |
| `<leader>mp` | Format |

### Go tools

| Key | Action |
|---|---|
| `<leader>Gta` / `<leader>Gtr` / `<leader>Gtc` | Add / remove / clear struct tags |
| `<leader>Gtt` / `<leader>GtT` / `<leader>GtA` | Generate test / exported tests / all tests |
| `<leader>Ge` | `if err != nil` |
| `<leader>Gf` / `<leader>Gs` | Fill struct / fill switch |
| `<leader>Gi` | Implement interface |
| `<leader>Gc` / `<leader>GC` | Coverage / toggle coverage |
| `<leader>Gm` | `go mod tidy` |
| `<leader>Gg` | `go generate` |
| `<leader>Gv` | `govulncheck` |
| `<leader>Ga` / `<leader>GA` | Alternate file / in vsplit |

### Testing

| Key | Action |
|---|---|
| `<leader>ttn` / `<leader>ttf` / `<leader>tta` | Run nearest / file / all |
| `<leader>ttl` / `<leader>ttx` | Run last / stop |
| `<leader>ttdn` | Debug nearest |
| `<leader>tts` / `<leader>tto` | Summary / output panel |

### Debugging

| Key | Action |
|---|---|
| `<leader>db` / `<leader>dB` / `<leader>dq` | Breakpoint / conditional / clear all |
| `<leader>dc` / `<leader>da` | Continue / run with args |
| `<leader>dn` / `<leader>dN` | Debug nearest / last Go test via delve (Go buffers only) |
| `<leader>di` / `<leader>do` / `<leader>dO` | Step into / over / out |
| `<leader>dC` / `<leader>dg` | Run to cursor / go to line |
| `<leader>dj` / `<leader>dk` | Stack down / up |
| `<leader>de` / `<leader>dh` | Evaluate / hover |
| `<leader>dr` / `<leader>du` | REPL / UI |
| `<leader>dp` / `<leader>dt` / `<leader>dl` | Pause / terminate / run last |
| `<leader>ds` | Session info |

### Motions

| Key | Action |
|---|---|
| `af` / `if` | A function / function body |
| `ac` / `ic` | A type / type body |
| `aa` / `ia` | An argument |
| `]f` / `[f` | Next / previous function |
| `]c` / `[c` | Next / previous type |
| `]]` / `[[` | Next / previous reference of symbol under cursor |
| `<Left>` / `<Right>` | Close / open fold |

---

## Gotchas

**`<C-i>` doesn't jump forward.** neoscroll took it for scrolling. `<C-o>`
back still works.

**`s` isn't vim's `s`.** substitute.nvim rebinds it: `s` + motion replaces
that text with your register. Use `cl` for the old behavior.

**`<leader>u` waits 300 ms.** It's undotree, but it's also the prefix of the
`<leader>u*` toggles, so vim waits to see if more is coming.

**Inlay hints are real text-width, not real text.** They shift things visually.
`<leader>uh` turns them off when you're aligning something by eye.

**gopls needs `go.mod`.** Open the module root, not a stray file from
elsewhere, or you'll get a wrong root and confusing results. `:LspInfo` shows
the root it picked.

**`fieldalignment` is off.** It fires on nearly every struct. Turn it on in
`lua/plugins/go.lua` deliberately when doing memory-layout work.

**Codelenses are context-dependent.** `run test` appears only in `_test.go`;
`tidy` and `upgrade dependency` only in `go.mod`. A plain `.go` file having
none is correct, not broken.

**Format-on-save gives up after 3 s.** A very large file may save unformatted.
`<leader>mp` retries manually.

**Go uses tabs; the config sets `shiftwidth=2`.** gofumpt normalizes on save,
so this only affects how things look while typing.

**`:GoDebug` doesn't exist.** go.nvim's debug module is disabled on purpose.
Use `<leader>d*`.

**Supermaven is installed but inert.** AI completion is off by default. Live
in `lua/plugins/completion.lua` if you want it.
