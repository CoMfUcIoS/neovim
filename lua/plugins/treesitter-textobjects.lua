-- Structural motions/textobjects: `daf` deletes a function, `vic` selects a
-- class body, `]f`/`[f` jump between functions (GoLand's Alt+Down/Up).
-- Uses the `main` branch API to match nvim-treesitter's main branch.
local function sel(obj)
	return function()
		require("nvim-treesitter-textobjects.select").select_textobject(obj, "textobjects")
	end
end

local function move(fn, obj)
	return function()
		require("nvim-treesitter-textobjects.move")[fn](obj, "textobjects")
	end
end

return {
	"nvim-treesitter/nvim-treesitter-textobjects",
	branch = "main",
	dependencies = { "nvim-treesitter/nvim-treesitter" },
	event = { "BufReadPost", "BufNewFile" },
	opts = {
		select = { lookahead = true },
		move = { set_jumps = true }, -- keep the jumplist honest
	},
	keys = {
		{ "af", sel("@function.outer"), mode = { "x", "o" }, desc = "a function" },
		{ "if", sel("@function.inner"), mode = { "x", "o" }, desc = "inner function" },
		{ "ac", sel("@class.outer"), mode = { "x", "o" }, desc = "a class/struct" },
		{ "ic", sel("@class.inner"), mode = { "x", "o" }, desc = "inner class/struct" },
		{ "aa", sel("@parameter.outer"), mode = { "x", "o" }, desc = "an argument" },
		{ "ia", sel("@parameter.inner"), mode = { "x", "o" }, desc = "inner argument" },
		{ "a/", sel("@comment.outer"), mode = { "x", "o" }, desc = "a comment" },

		{ "]f", move("goto_next_start", "@function.outer"), mode = { "n", "x", "o" }, desc = "Next function" },
		{ "[f", move("goto_previous_start", "@function.outer"), mode = { "n", "x", "o" }, desc = "Prev function" },
		{ "]c", move("goto_next_start", "@class.outer"), mode = { "n", "x", "o" }, desc = "Next class/struct" },
		{ "[c", move("goto_previous_start", "@class.outer"), mode = { "n", "x", "o" }, desc = "Prev class/struct" },
	},
}
