return {
	{
		"mfussenegger/nvim-lint",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			local lint = require("lint")

			lint.linters_by_ft = {
				dockerfile = { "hadolint" },
				sh = { "shellcheck" },
				bash = { "shellcheck" },
				yaml = { "yamllint" },
				terraform = { "tflint" },
				tf = { "tflint" },
				sql = { "sqlfluff" },
			}

			vim.api.nvim_create_autocmd({ "BufEnter", "BufWritePost", "InsertLeave" }, {
				callback = function()
					lint.try_lint()
				end,
			})
		end,
	},
}
