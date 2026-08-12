return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
	},
	config = function()
		local keymap = vim.keymap

		-- Advertise nvim-cmp's capabilities (snippets, resolve support,
		-- completion item defaults) to every server. Without this gopls falls
		-- back to plain-text completions with no placeholders.
		local capabilities = require("cmp_nvim_lsp").default_capabilities()
		capabilities.workspace = capabilities.workspace or {}
		capabilities.workspace.didChangeWatchedFiles = { dynamicRegistration = true }
		vim.lsp.config("*", { capabilities = capabilities })

		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				local opts = { buffer = ev.buf, silent = true }
				local client = vim.lsp.get_client_by_id(ev.data.client_id)

				-- navigation (snacks picker, matching the rest of the config)
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", function()
					Snacks.picker.lsp_references()
				end, opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", function()
					Snacks.picker.lsp_definitions()
				end, opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", function()
					Snacks.picker.lsp_implementations()
				end, opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", function()
					Snacks.picker.lsp_type_definitions()
				end, opts)

				-- GoLand's Ctrl+Alt+H / Ctrl+Alt+Shift+H
				opts.desc = "Incoming calls (call hierarchy)"
				keymap.set("n", "<leader>ci", vim.lsp.buf.incoming_calls, opts)

				-- <leader>cO not <leader>co: huez + github-theme own the
				-- <leader>co* colorscheme prefix, and a bare <leader>co would
				-- stall every one of them by timeoutlen.
				opts.desc = "Outgoing calls (call hierarchy)"
				keymap.set("n", "<leader>cO", vim.lsp.buf.outgoing_calls, opts)

				opts.desc = "Document symbols (outline)"
				keymap.set("n", "<leader>cS", function()
					Snacks.picker.lsp_symbols()
				end, opts)

				opts.desc = "Workspace symbols"
				keymap.set("n", "<leader>cw", function()
					Snacks.picker.lsp_workspace_symbols()
				end, opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", vim.lsp.buf.rename, opts)

				opts.desc = "Signature help"
				keymap.set({ "n", "i" }, "<C-k>", vim.lsp.buf.signature_help, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", function()
					Snacks.picker.diagnostics_buffer()
				end, opts)

				-- was <leader>d, which shadowed the entire <leader>d* DAP prefix
				-- and added a timeoutlen stall to every debug keypress.
				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>cd", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", function()
					vim.diagnostic.jump({ count = -1, float = true })
				end, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", function()
					vim.diagnostic.jump({ count = 1, float = true })
				end, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", "<cmd>LspRestart<CR>", opts)

				-- Inlay hints: param names and inferred types inline, on by
				-- default like GoLand. Toggle with <leader>uh (snacks).
				if client and client:supports_method("textDocument/inlayHint") then
					vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
				end

				-- Codelens: gopls' "run test" / "go mod tidy" gutter actions.
				if client and client:supports_method("textDocument/codeLens") then
					opts.desc = "Run code lens"
					keymap.set("n", "<leader>cc", vim.lsp.codelens.run, opts)
					-- enable() owns the refresh loop; codelens.refresh() is
					-- deprecated as of 0.12.
					vim.lsp.codelens.enable(true, { bufnr = ev.buf })
				end

				-- Highlight other occurrences of the symbol under the cursor.
				if client and client:supports_method("textDocument/documentHighlight") then
					local hl_group = vim.api.nvim_create_augroup("LspDocHighlight" .. ev.buf, { clear = true })
					vim.api.nvim_create_autocmd({ "CursorHold", "CursorHoldI" }, {
						buffer = ev.buf,
						group = hl_group,
						callback = vim.lsp.buf.document_highlight,
					})
					vim.api.nvim_create_autocmd({ "CursorMoved", "CursorMovedI" }, {
						buffer = ev.buf,
						group = hl_group,
						callback = vim.lsp.buf.clear_references,
					})
				end
			end,
		})

		-- configure pullminder lsp (custom registration) using new vim.lsp.config API
		vim.lsp.config.pullminder_lsp = {
			cmd = { "pullminder", "lsp" },
			filetypes = {
				"yaml",
				"json",
				"markdown",
				"go",
				"typescript",
				"javascript",
				"python",
				"dockerfile",
				"terraform",
				"sh",
				"bash",
				"zsh",
			},
			root_markers = { ".git" },
		}
		vim.lsp.enable("pullminder_lsp")

		-- One call: each vim.diagnostic.config() replaces the whole `signs`
		-- table, so the old per-severity loop only ever kept the last icon.
		vim.diagnostic.config({
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
			virtual_text = { spacing = 2, source = "if_many" },
			severity_sort = true,
			float = { border = "rounded", source = "if_many" },
			update_in_insert = false,
		})
	end,
}
