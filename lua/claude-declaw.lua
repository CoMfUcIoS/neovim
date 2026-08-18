-- Strip Claude's watermark on every write: the visible self-attribution lines,
-- plus the invisible-unicode "Layer A" set (zero-width chars, unicode tag
-- chars, bidi controls, exotic spaces) that github.com/guillaumemeyer/
-- watermarks-remover targets.
--
-- NOT covered, because it cannot be: Claude's real text watermark is a
-- statistical bias in token choice, not hidden characters. Nothing to strip and
-- nothing to highlight — only rewriting the prose removes that.
--
-- ponytail: plain lowercase substring match for the visible lines, not patterns
-- — the watermark is a fixed set of strings Claude emits, and lowercasing
-- covers the Co-Authored-By/Co-authored-by wobble. Add a string below if a new
-- one shows up.
local M = {}

local marks = {}

-- {first, last, action}. "delete" has no legitimate use in code or prose;
-- "space" carries real spacing so it degrades to a plain space. Anything absent
-- is left alone — notably ZWJ (U+200D) and the variation selectors, which are
-- load-bearing inside emoji sequences.
local invisible = {
	{ 0x200B, 0x200C, "delete" }, -- zero-width space, zero-width non-joiner
	{ 0x2060, 0x2064, "delete" }, -- word joiner + invisible math operators
	{ 0xFEFF, 0xFEFF, "delete" }, -- BOM used mid-text as zero-width no-break space
	{ 0x00AD, 0x00AD, "delete" }, -- soft hyphen
	{ 0x034F, 0x034F, "delete" }, -- combining grapheme joiner
	{ 0x180E, 0x180E, "delete" }, -- Mongolian vowel separator
	{ 0x115F, 0x1160, "delete" }, -- Hangul choseong/jungseong fillers
	{ 0x3164, 0x3164, "delete" }, -- Hangul filler
	{ 0x061C, 0x061C, "delete" }, -- Arabic letter mark
	{ 0x200E, 0x200F, "delete" }, -- LRM/RLM
	{ 0x202A, 0x202E, "delete" }, -- bidi embedding/override controls
	{ 0x2066, 0x2069, "delete" }, -- bidi isolates
	{ 0xE0000, 0xE007F, "delete" }, -- unicode tag chars: the steganography carrier
	{ 0x00A0, 0x00A0, "space" }, -- no-break space
	{ 0x1680, 0x1680, "space" }, -- Ogham space mark
	{ 0x2000, 0x200A, "space" }, -- en/em/thin/hair space family
	{ 0x202F, 0x202F, "space" }, -- narrow no-break space
	{ 0x205F, 0x205F, "space" }, -- medium mathematical space
	{ 0x3000, 0x3000, "space" }, -- ideographic space
}

local function action(cp)
	for _, r in ipairs(invisible) do
		if cp >= r[1] and cp <= r[2] then
			return r[3]
		end
	end
end

-- ponytail: char2nr per multibyte char is a vimscript call, so the ASCII
-- fast-path below is what keeps a whole-file save cheap. Fine until someone
-- saves a megabyte of CJK.
local function clean(line)
	if not line:find("[\194-\244]") then
		return line, 0
	end
	local hits = 0
	local out = line:gsub("[\194-\244][\128-\191]*", function(c)
		local act = action(vim.fn.char2nr(c))
		if act == "delete" then
			hits = hits + 1
			return ""
		elseif act == "space" then
			hits = hits + 1
			return " "
		end
		return c
	end)
	return out, hits
end

local function is_watermark(line)
	local low = line:lower()
	for _, mark in ipairs(marks) do
		if low:find(mark, 1, true) then
			return true
		end
	end
	return false
end

-- Returns cleaned lines and {lines = n, chars = n}, or nil when nothing matched.
function M.strip(lines)
	local out = {}
	local stats = { lines = 0, chars = 0 }
	for _, line in ipairs(lines) do
		if is_watermark(line) then
			stats.lines = stats.lines + 1
		else
			local cleaned, hits = clean(line)
			stats.chars = stats.chars + hits
			out[#out + 1] = cleaned
		end
	end
	if stats.lines == 0 and stats.chars == 0 then
		return nil
	end
	-- the attribution block is normally preceded by a blank separator line; drop
	-- the trailing blanks it leaves behind
	while #out > 0 and out[#out]:match("^%s*$") do
		out[#out] = nil
	end
	return out, stats
end

-- Strip buf in place. Returns the stats, or nil if it was already clean.
function M.declaw(buf)
	buf = buf or 0
	if vim.bo[buf].buftype ~= "" or not vim.bo[buf].modifiable then
		return
	end
	local cleaned, stats = M.strip(vim.api.nvim_buf_get_lines(buf, 0, -1, false))
	if not cleaned then
		return
	end
	vim.api.nvim_buf_set_lines(buf, 0, -1, false, cleaned)
	return stats
end

function M.setup()
	vim.api.nvim_create_autocmd("BufWritePre", {
		group = vim.api.nvim_create_augroup("claude-declaw", { clear = true }),
		callback = function(args)
			local stats = M.declaw(args.buf)
			-- invisible chars are worth knowing about; a stripped attribution
			-- line is not worth a message on every commit
			if stats and stats.chars > 0 then
				vim.notify(("declawed %d invisible char(s)"):format(stats.chars), vim.log.levels.INFO)
			end
		end,
	})

	vim.api.nvim_create_user_command("ClaudeDeclaw", function()
		local stats = M.declaw(0)
		vim.notify(
			stats and ("declawed %d line(s), %d invisible char(s)"):format(stats.lines, stats.chars) or "already clean"
		)
	end, { desc = "Strip Claude's watermark from this buffer now" })
end

return M
