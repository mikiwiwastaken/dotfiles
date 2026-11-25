return {
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		keys = {
			{
				"<leader>cf",
				function()
					require("conform").format({ async = true, lsp_format = "fallback" })
				end,
				desc = "Format buffer",
			},
		},
		opts = {
			formatters_by_ft = {
				lua = { "stylua" },
				python = { "ruff_format", "ruff_organize_imports" },
				go = { "goimports" },
				sh = { "shfmt" },
				bash = { "shfmt" },
				yaml = { "yamlfmt" },
				json = { "prettier" },
				jsonc = { "prettier" },
				markdown = { "prettier" },
				toml = { "taplo" },
				terraform = { "terraform_fmt" },
				tf = { "terraform_fmt" },
				hcl = { "packer_fmt" },
				sql = { "sqlfluff" },
			},
			format_on_save = { timeout_ms = 500, lsp_format = "fallback" },
		},
	},
}
