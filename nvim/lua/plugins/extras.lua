return {
	-- Show CSS colors inline (hex, rgb, hsl)
	{
		"catgoose/nvim-colorizer.lua",
		event = "BufReadPost",
		opts = {
			user_default_options = {
				mode = "virtualtext", -- small marker instead of a colored background
				virtualtext = "■",
			},
		},
	},

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
			})

			-- Subtle background taken from the catppuccin palette
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
						-- Fallback for other colorschemes
						vim.api.nvim_set_hl(0, group, { link = "CursorLine" })
					end
				end
			end

			set_illuminate_hl()
			-- Re-apply whenever the colorscheme changes
			vim.api.nvim_create_autocmd("ColorScheme", { callback = set_illuminate_hl })
		end,
	},
}
