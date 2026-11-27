return {
	-- Indent guides
	{ "lukas-reineke/indent-blankline.nvim", main = "ibl", event = "BufReadPost", opts = {} },

	-- Highlight other uses of the word under the cursor
	{
		"RRethy/vim-illuminate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("illuminate").configure({
				providers = { "lsp", "treesitter", "regex" },
				delay = 200,
				filetypes_denylist = { "oil", "lazy", "mason" },
				modes_denylist = { "v", "V", "\22" },
			})

			local function set_illuminate_hl()
				local ok, palettes = pcall(require, "catppuccin.palettes")
				for _, group in ipairs({
					"IlluminatedWordText",
					"IlluminatedWordRead",
					"IlluminatedWordWrite",
				}) do
					if ok then
						local c = palettes.get_palette()
						vim.api.nvim_set_hl(0, group, { bg = c.surface1 })
					else
						vim.api.nvim_set_hl(0, group, { link = "CursorLine" })
					end
				end
			end

			set_illuminate_hl()
			vim.api.nvim_create_autocmd("ColorScheme", { callback = set_illuminate_hl })
		end,
	},
}
