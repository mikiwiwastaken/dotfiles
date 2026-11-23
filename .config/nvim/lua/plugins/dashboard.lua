local function icon(codepoint)
	return vim.fn.nr2char(codepoint) .. "  "
end

return {
	{
		"nvimdev/dashboard-nvim",
		event = "VimEnter",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			vim.opt.fillchars:append({ eob = " " })

			local function set_highlights()
				local ok, palettes = pcall(require, "catppuccin.palettes")
				if not ok then
					return
				end
				local c = palettes.get_palette()
				local set = vim.api.nvim_set_hl

				set(0, "DashboardHeader", { fg = c.mauve })
				set(0, "DashboardDesc", { fg = c.text })
				set(0, "DashboardKey", { fg = c.peach, bold = true })
				set(0, "DashboardFooter", { fg = c.overlay1, italic = true })

				set(0, "DashIconFind", { fg = c.blue })
				set(0, "DashIconNew", { fg = c.green })
				set(0, "DashIconRecent", { fg = c.teal })
				set(0, "DashIconGrep", { fg = c.yellow })
				set(0, "DashIconConfig", { fg = c.peach })
				set(0, "DashIconLazy", { fg = c.mauve })
				set(0, "DashIconQuit", { fg = c.red })
			end

			set_highlights()
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = set_highlights,
			})

			local header = {
				"",
				"",
				"⣿⠛⠛⠛⠛⠻⡆⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
				"⠛⢛⣿⠋⢀⡾⠃⠀⠀⠀⠀⢀⣤⣤⠤⠤⣤⣤⣀⣀⣀⣠⠶⡶⣤⣀⣠⠾⡷⣦⣀⣤⣤⡤⠤⠦⢤⣤⣄⡀⠀⢠⡶⢶⡄⠀⠀",
				"⢠⡟⠁⣴⣿⢤⡄⣴⢶⠶⡆⠈⢷⡀⠀⠀⠀⠀⢀⣭⣫⠵⠥⠽⣄⣝⠵⢍⣘⣄⠳⣤⣀⠀⠀⢀⡤⠊⣽⠁⠀⠸⣇⠀⢿⠀⠀",
				"⠸⢷⣴⣤⡤⠾⠇⣽⠋⠼⣷⠀⠈⢷⡄⢀⣤⡶⠋⠀⣀⡄⠤⠀⡲⡆⠀⠀⠈⠙⡄⠘⢮⢳⡴⠯⣀⢠⡏⠀⠀⠀⢻⠀⢸⠇⠀",
				"⠀⠀⠀⠀⠀⠀⠀⠙⠛⠋⠉⢀⣴⠟⠉⢯⡞⡠⢲⠉⣼⠀⠀⡰⠁⡇⢀⢷⠀⣄⢵⠀⠈⡟⢄⠀⠀⠙⢷⣤⣤⣤⡿⢢⡿⠀⠀",
				"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⣠⠟⠑⠊⠁⡼⣌⢠⢿⢸⢸⡀⢰⠁⡸⡇⡸⣸⢰⢈⠘⡄⠀⢸⠀⢣⡀⠀⠈⢮⢢⣏⣤⡾⠃⠀⠀",
				"⠀⠀⠀⠀⠀⠀⠀⠀⠀⢰⣯⣴⠞⡠⣼⠁⡘⣾⠏⣿⢇⣳⣸⣞⣀⢱⣧⣋⣞⡜⢳⡇⠀⢸⠀⢆⢧⠀⠰⣄⢏⢧⣾⠁⠀⠀⠀",
				"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠈⢹⡏⢰⠁⡻⠀⡟⡏⠉⠀⣀⠀⠀⠀⠀⣀⠁⠀⠉⠛⢽⠇⠀⣼⡆⠈⡆⠃⠀⡏⠻⣾⣽⣇⡀⠀⠀",
				"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⠁⡇⠀⡇⡄⣿⠷⠿⠿⠛⠀⠀⠀⠀⠛⠻⠿⠿⠿⡜⢀⡴⡟⢸⣸⡼⠀⠀⡇⠀⡞⡆⢻⠙⢦⠀",
				"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⢸⡶⢀⣼⣿⣬⣽⠧⠬⠇⠀⠀⠀⠀⠀⠀⢞⣯⣭⢺⣔⣪⣾⣤⠺⡇⢳⠀⢠⣧⡾⠛⠛⠻⠶⠞⠁",
				"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠷⢿⠟⠉⡀⠈⢦⡀⠀⠀⣠⠖⠒⠒⢤⡀⠀⢀⡼⠿⢇⡣⢬⣶⠷⢿⣤⡾⠁⠀⠀⠀⠀⠀⠀⠀",
				"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠘⠷⠾⠷⠖⠛⠛⠲⠶⠿⠤⣤⠤⠤⢷⣶⠋⠀⠀⠀⣱⠞⠁⠀⠈⠉⠀⠀⠀⠀⠀⠀⠀⠀⠀",
				"⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠉⠛⠓⠒⠚⠋⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀",
				"",
			}

			local GAP = 12

			local entries = {
				{ ic = 0xF002, hl = "DashIconFind", desc = "Find file", key = "f", action = "Telescope find_files" },
				{ ic = 0xF15B, hl = "DashIconNew", desc = "New file", key = "n", action = "enew" },
				{ ic = 0xF1DA, hl = "DashIconRecent", desc = "Recent files", key = "r", action = "Telescope oldfiles" },
				{ ic = 0xF15C, hl = "DashIconGrep", desc = "Find text", key = "g", action = "Telescope live_grep" },
				{
					ic = 0xF013,
					hl = "DashIconConfig",
					desc = "Config",
					key = "c",
					action = function()
						require("oil").open(vim.fn.stdpath("config"))
					end,
				},
				{ ic = 0xF04B2, hl = "DashIconLazy", desc = "Lazy", key = "l", action = "Lazy" },
				{ ic = 0xF011, hl = "DashIconQuit", desc = "Quit", key = "q", action = "qa" },
			}

			local max_desc = 0
			for _, e in ipairs(entries) do
				max_desc = math.max(max_desc, vim.fn.strdisplaywidth(e.desc))
			end

			local center = {}
			for _, e in ipairs(entries) do
				local pad = string.rep(" ", max_desc - vim.fn.strdisplaywidth(e.desc) + GAP)
				table.insert(center, {
					icon = icon(e.ic),
					icon_hl = e.hl,
					desc = e.desc .. pad,
					desc_hl = "DashboardDesc",
					key = e.key,
					key_hl = "DashboardKey",
					key_format = "[%s]",
					action = e.action,
				})
			end

			require("dashboard").setup({
				theme = "doom",
				hide = {
					statusline = true,
					tabline = true,
					winbar = true,
				},
				config = {
					header = header,
					vertical_center = true,
					center = center,
					footer = function()
						local v = vim.version()
						local ok, lazy = pcall(require, "lazy")
						local plugins = ok and lazy.stats().count or 0
						return {
							"",
							string.format("Neovim v%d.%d.%d  |  %d plugins", v.major, v.minor, v.patch, plugins),
						}
					end,
				},
			})
		end,
	},
}
