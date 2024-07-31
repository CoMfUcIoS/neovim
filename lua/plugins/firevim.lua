local spec = {
	"glacambre/firenvim",
	-- lazy = not vim.g.started_by_firenvim,
	build = ":call firenvim#install(0)",
	module = false, -- prevent other code to require("firenvim")
	lazy = true, -- never load, except when lazy.nvim is building the plugin
}
if vim.g.started_by_firenvim == true then -- set by the browser addon
	spec = {
		{ "noice.nvim", cond = false }, -- can't work with gui having ext_cmdline
		{ "lualine.spec", cond = false }, -- not useful in the browser
		vim.tbl_extend("force", spec, {
			lazy = false, -- must load at start in browser
		}),
	}
end

return spec
