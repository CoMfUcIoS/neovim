return {
	"Isrothy/neominimap.nvim",
	enabled = true,
	lazy = false, -- NOTE: NO NEED to Lazy load
	-- Optional
	keys = {
		{ "<leader>nt", "<cmd>Neominimap toggle<cr>", desc = "Toggle minimap" },
		{ "<leader>no", "<cmd>Neominimap on<cr>", desc = "Enable minimap" },
		{ "<leader>nc", "<cmd>Neominimap off<cr>", desc = "Disable minimap" },
		{ "<leader>nf", "<cmd>Neominimap focus<cr>", desc = "Focus on minimap" },
		{ "<leader>nu", "<cmd>Neominimap unfocus<cr>", desc = "Unfocus minimap" },
		{ "<leader>ns", "<cmd>Neominimap toggleFocus<cr>", desc = "Toggle focus on minimap" },
		{ "<leader>nwt", "<cmd>Neominimap winToggle<cr>", desc = "Toggle minimap for current window" },
		{ "<leader>nwr", "<cmd>Neominimap winRefresh<cr>", desc = "Refresh minimap for current window" },
		{ "<leader>nwo", "<cmd>Neominimap winOn<cr>", desc = "Enable minimap for current window" },
		{ "<leader>nwc", "<cmd>Neominimap winOff<cr>", desc = "Disable minimap for current window" },
		{ "<leader>nbt", "<cmd>Neominimap bufToggle<cr>", desc = "Toggle minimap for current buffer" },
		{ "<leader>nbr", "<cmd>Neominimap bufRefresh<cr>", desc = "Refresh minimap for current buffer" },
		{ "<leader>nbo", "<cmd>Neominimap bufOn<cr>", desc = "Enable minimap for current buffer" },
		{ "<leader>nbc", "<cmd>Neominimap bufOff<cr>", desc = "Disable minimap for current buffer" },
	},
	init = function()
		vim.opt.wrap = false -- Recommended
		vim.opt.sidescrolloff = 36 -- It's recommended to set a large value
		---@type Neominimap.UserConfig
		vim.g.neominimap = {
			auto_enable = true,

			-- Minimap will not be created for buffers of these types
			---@type string[]
			exclude_filetypes = {
				"help",
				"http",
				"bigfile",
			},
			-- Minimap will not be created for buffers of these types
			---@type string[]
			exclude_buftypes = {
				"nofile",
				"nowrite",
				"quickfix",
				"terminal",
				"prompt",
			},
			-- When false is returned, the minimap will not be created for this buffer
			---@type fun(bufnr: integer): boolean
			buf_filter = function()
				-- if filetype is "http" then dont create a minimap
				if vim.bo.filetype == "http" then
					return false
				end
				return true
			end,
			-- When false is returned, the minimap will not be created for this window
			---@type fun(winid: integer): boolean
			win_filter = function()
				-- if filetype is "http" then dont create a minimap
				if vim.bo.filetype == "http" then
					return false
				end
				return true
			end,
			-- How many columns a dot should span
			x_multiplier = 4, ---@type integer

			-- How many rows a dot should span
			y_multiplier = 1, ---@type integer
			-- How the minimap places the current line vertically.
			-- `"center"`  -> pins the line to the viewport middle (window-relative).
			-- `"percent"` -> maps line index / total lines to minimap height (file-relative).
			-- Note: here "center" means the middle of the **minimap window**, not "center of the file".
			current_line_position = "center", ---@type Neominimap.Config.CurrentLinePosition

			--- Either `split` or `float`
			--- When layout is set to `float`, minimaps will be created in floating windows attached to all suitable windows.
			--- When layout is set to `split`, the minimap will be created in one split window per tab.
			layout = "split", ---@type Neominimap.Config.LayoutType

			--- Used when `layout` is set to `split`
			split = {
				minimap_width = 20, ---@type integer

				-- Always fix the width of the split window
				fix_width = false, ---@type boolean

				---@alias Neominimap.Config.SplitDirection "left" | "right" | "topleft" | "botright" | "aboveleft" | "rightbelow"
				direction = "right", ---@type Neominimap.Config.SplitDirection

				--- Automatically close the split window when it is the last window.
				close_if_last_window = true, ---@type boolean

				--- When true, the split window will be recreated when you close it.
				--- When false, the minimap will be disabled for the current tab when you close the minimap window.
				persist = true, ---@type boolean
			},
		}
	end,
}
