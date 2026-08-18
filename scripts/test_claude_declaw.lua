-- nvim -l scripts/test_claude_declaw.lua
package.path = "lua/?.lua;" .. package.path
local declaw = require("claude-declaw")
local u = vim.fn.nr2char

assert(declaw.strip({ "keep", "me" }) == nil, "untouched buffer must report no change")
assert(declaw.strip({ "emoji 👍🏽 and ❤️ survive" }) == nil, "emoji joiners/selectors must not count as a change")

local out, stats = declaw.strip({
	"fix: thing",
	"",
	"🤖 Generated with [Claude Code](https://claude.com/claude-code)",
	"",
	"Co-Authored-By: Claude <noreply@anthropic.com>",
})
assert(#out == 1 and out[1] == "fix: thing", vim.inspect(out))
assert(stats.lines == 2 and stats.chars == 0, vim.inspect(stats))

out = declaw.strip({ "-- co-authored-by: claude", "code()" })
assert(#out == 1 and out[1] == "code()", vim.inspect(out))

-- zero-width space, tag chars (the stego carrier), BOM, soft hyphen, bidi
-- override: gone. no-break/exotic spaces: plain space. emoji: untouched.
out, stats = declaw.strip({
	"he" .. u(0x200B) .. "llo" .. u(0xE0041) .. u(0xE0042),
	"a" .. u(0x00A0) .. "b" .. u(0x202F) .. "c" .. u(0x2009) .. "d",
	u(0xFEFF) .. "x" .. u(0x00AD) .. "y" .. u(0x202E) .. "z",
	"👨‍👩‍👧 ❤️",
})
assert(out[1] == "hello", vim.inspect(out[1]))
assert(out[2] == "a b c d", vim.inspect(out[2]))
assert(out[3] == "xyz", vim.inspect(out[3]))
assert(out[4] == "👨‍👩‍👧 ❤️", "emoji ZWJ/variation selectors must survive")
assert(stats.lines == 0 and stats.chars == 9, vim.inspect(stats))

print("ok")
