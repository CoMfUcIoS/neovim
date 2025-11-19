return {
	"comfucios/console-inline.nvim",
	-- dir = "/Users/i.karasavvaidis/Apps/console-inline.nvim",
	version = "*",
	event = "VimEnter",
	opts = {
		-- Server settings
		host = "127.0.0.1",
		port = 36123,

		-- Behavior
		autostart = true, -- Start on VimEnter
		autostart_relay = true, -- Auto-start WebSocket relay for browsers
		open_missing_files = false, -- Don't auto-open files (can be disruptive)
		replay_persisted_logs = false, -- Don't replay old logs on buffer open

		-- Performance & placement
		use_index = true, -- Enable fast buffer indexing (critical)
		use_treesitter = true, -- Enable Tree-sitter for accurate placement
		max_tokens_per_line = 120, -- Cap tokens per line (prevents minified file bloat)
		skip_long_lines_len = 4000, -- Skip indexing very long lines (likely bundled)
		incremental_index = true, -- Build large file indexes in batches (smooth UI)
		index_batch_size = 900, -- Lines per incremental batch (balanced responsiveness)
		treesitter_debounce_ms = 120, -- Debounce Tree-sitter rebuilds (avoid edit churn)
		prefer_original_source = true, -- Trust source maps (TypeScript/JSX locations)
		resolve_source_maps = true, -- Enable source map resolution
		benchmark_enabled = false, -- Disable benchmark overhead

		-- Display
		throttle_ms = 30, -- Debounce rapid updates
		max_len = 160, -- Truncate long messages
		suppress_css_color_conflicts = true, -- Prevent css-color plugin crashes

		-- Filtering
		severity_filter = {
			log = true,
			info = true,
			warn = true,
			error = true,
		},

		-- History
		history_size = 200, -- Keep 200 entries for Telescope picker

		-- Hover popups (auto-show on CursorHold)
		hover = {
			enabled = true,
			events = { "CursorHold" },
			hide_events = { "CursorMoved", "CursorMovedI", "InsertEnter", "BufLeave" },
			border = "rounded",
			focusable = false,
			relative = "cursor",
			row = 1,
			col = 0,
		},

		-- Optional: Customize pattern highlighting
		-- pattern_overrides = {
		--   { pattern = 'CRITICAL', icon = '💥', highlight = 'ErrorMsg' },
		-- },

		-- Optional: Filter by path/message
		-- filters = {
		--   deny = {
		--     paths = { '**/node_modules/**' },
		--     messages = { { pattern = 'DEBUG', plain = true } },
		--   },
		-- },
	},
}
