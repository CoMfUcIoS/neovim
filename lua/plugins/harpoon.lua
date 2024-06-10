return {
	"ThePrimeagen/harpoon",
	branch = "harpoon2",
	dependencies = { "nvim-lua/plenary.nvim" },
	config = function()
		local harpoon = require("harpoon")

		harpoon.setup({})

		local conf = require("telescope.config").values
		local function toggle_telescope(harpoon_files)
			local file_paths = {}
			for _, item in ipairs(harpoon_files.items) do
				table.insert(file_paths, item.value)
			end

			require("telescope.pickers")
				.new({}, {
					prompt_title = "Harpoon",
					finder = require("telescope.finders").new_table({
						results = file_paths,
					}),
					previewer = conf.file_previewer({}),
					sorter = conf.generic_sorter({}),
				})
				:find()
		end

		vim.keymap.set("n", "<leader>ah", function()
			toggle_telescope(harpoon:list())
		end, { desc = "Open harpoon window" })
		vim.keymap.set("n", "<leader>aa", function()
			harpoon:list():add()
		end, { desc = "Harpoon file" })

		vim.keymap.set("n", "<leader>an", function()
			harpoon:list():select(1)
		end, { desc = "Show haprooned file 1" })
		vim.keymap.set("n", "<leader>ae", function()
			harpoon:list():select(2)
		end, { desc = "Show haprooned file 2" })
		vim.keymap.set("n", "<leader>ai", function()
			harpoon:list():select(3)
		end, { desc = "Show harpooned file 3" })
		vim.keymap.set("n", "<leader>ao", function()
			harpoon:list():select(4)
		end, { desc = "Show harpooned file 4" })

		-- Toggle previous & next buffers stored within Harpoon list
		vim.keymap.set("n", "<leader>ar", function()
			harpoon:list():prev()
		end, { desc = "Show previous haprooned file" })
		vim.keymap.set("n", "<leader>af", function()
			harpoon:list():next()
		end, { desc = "Show next harpooned file" })
	end,
}
