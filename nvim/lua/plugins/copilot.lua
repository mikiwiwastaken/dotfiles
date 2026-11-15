return {
	{
		"github/copilot.vim",
		cmd = "Copilot",
		-- event = "InsertEnter",
		init = function()
			-- Must be set before the plugin loads: free Tab for blink.cmp snippets
			vim.g.copilot_no_tab_map = true

			-- Disable Copilot for some filetypes
			vim.g.copilot_filetypes = { markdown = false }
		end,
		config = function()
			-- Accept the whole suggestion with Ctrl-l (insert mode)
			vim.keymap.set("i", "<C-l>", 'copilot#Accept("\\<CR>")', {
				expr = true,
				replace_keycodes = false,
				desc = "Copilot accept",
			})
			-- Accept only the next word
			vim.keymap.set("i", "<M-l>", "<Plug>(copilot-accept-word)", { desc = "Copilot accept word" })
		end,
	},
}
