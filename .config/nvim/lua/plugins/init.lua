return {
	-- Colorscheme
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000,
		config = function()
			vim.cmd.colorscheme("catppuccin")
		end,
	},

	-- Fuzzy finder
	{
		"nvim-telescope/telescope.nvim",
		dependencies = { "nvim-lua/plenary.nvim" },
		cmd = "Telescope",
		keys = {
			{ "<leader>ff", "<cmd>Telescope find_files<CR>", desc = "Find files" },
			{ "<leader>fg", "<cmd>Telescope live_grep<CR>", desc = "Grep" },
			{ "<leader>fb", "<cmd>Telescope buffers<CR>", desc = "Buffers" },
		},
	},

	-- Syntax highlighting
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.config").setup({
				ensure_installed = { "lua", "bash", "html", "css", "javascript", "typescript", "json", "python" },
				highlight = { enable = true },
			})
		end,
	},

	-- File explorer as a buffer
	{
		"stevearc/oil.nvim",
		opts = {
			default_file_explorer = true,
			view_options = { show_hidden = true },
			skip_confirm_for_simple_edits = true,
			keymaps = {
				["<C-h>"] = false,
				["<C-l>"] = false,
				["<C-x>"] = { "actions.select", opts = { horizontal = true } },
				["<C-r>"] = "actions.refresh",
			},
		},
		keys = { { "-", "<cmd>Oil<CR>", desc = "Open parent dir" } },
	},

	-- Statusline
	{
		"nvim-lualine/lualine.nvim",
		opts = function(_, opts)
			opts.options = opts.options or {}
			opts.options.disabled_filetypes = opts.options.disabled_filetypes or {}
			opts.options.disabled_filetypes.statusline =
				vim.list_extend(opts.options.disabled_filetypes.statusline or {}, { "dashboard" })
		end,
	},
}
