return {
	{
		"eandrju/cellular-automaton.nvim",
		cmd = "CellularAutomaton",
    -- stylua: ignore
    keys = {
      { '<leader>Ag', '<Cmd>CellularAutomaton game_of_life<CR>', desc = 'automaton: game of life', },
      { '<leader>Am', '<Cmd>CellularAutomaton make_it_rain<CR>', desc = 'automaton: make it rain', },
    },
	},
}
