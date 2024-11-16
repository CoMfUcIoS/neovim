local M = {}

local defaults = {
	notify = true, -- show notification when big file detected
	size = 1.5 * 1024 * 1024, -- 1.5MB
	setup = function(ctx)
		vim.b.minianimate_disable = true
		vim.schedule(function()
			vim.bo[ctx.buf].syntax = ctx.ft
		end)
	end,
}

function M.setup(passed_opts)
	local opts = vim.tbl_deep_extend("force", defaults, passed_opts or {})

	vim.filetype.add({
		pattern = {
			[".*"] = {
				function(path, buf)
					return vim.bo[buf]
							and vim.bo[buf].filetype ~= "bigfile"
							and path
							and vim.fn.getfsize(path) > opts.size
							and "bigfile"
						or nil
				end,
			},
		},
	})

	vim.api.nvim_create_autocmd({ "BufReadPost" }, {
		group = vim.api.nvim_create_augroup("bigfile_group", { clear = true }),
		callback = function(ev)
			local path = vim.fn.fnamemodify(vim.api.nvim_buf_get_name(ev.buf), ":p:~:.")
			if vim.bo[ev.buf].filetype == "bigfile" then
				if opts.notify then
					vim.notify(
						("Big file detected `%s`. Some Neovim features have been **disabled**."):format(path),
						vim.log.levels.WARN,
						{ title = "Big File" }
					)
				end
				vim.api.nvim_buf_call(ev.buf, function()
					opts.setup({
						buf = ev.buf,
						ft = vim.filetype.match({ buf = ev.buf }) or "",
					})
				end)
			end
		end,
	})
end

return M
