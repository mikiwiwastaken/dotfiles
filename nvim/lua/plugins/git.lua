return {
	{
		"lewis6991/gitsigns.nvim",
		opts = {
			on_attach = function(bufnr)
				local gs = require("gitsigns")
				local map = function(keys, fn, desc)
					vim.keymap.set("n", keys, fn, { buffer = bufnr, desc = desc })
				end

				-- Navigate between changed hunks
				map("]h", function()
					gs.nav_hunk("next")
				end, "Next hunk")
				map("[h", function()
					gs.nav_hunk("prev")
				end, "Previous hunk")

				-- Hunk actions
				map("<leader>hs", gs.stage_hunk, "Stage hunk")
				map("<leader>hr", gs.reset_hunk, "Reset hunk")
				map("<leader>hp", gs.preview_hunk, "Preview hunk")
				map("<leader>hb", function()
					gs.blame_line({ full = true })
				end, "Blame line")
				map("<leader>hd", gs.diffthis, "Diff this file")
			end,
		},
	},
}
