return {
	{
		"github/copilot.vim",
		cmd = "Copilot",
		init = function()
			vim.g.copilot_no_tab_map = true

			vim.g.copilot_filetypes = { markdown = false }
		end,
		config = function()
			vim.keymap.set("i", "<C-l>", 'copilot#Accept("\\<CR>")', {
				expr = true,
				replace_keycodes = false,
				desc = "Copilot accept",
			})
			vim.keymap.set("i", "<M-l>", "<Plug>(copilot-accept-word)", { desc = "Copilot accept word" })
		end,
	},
}
