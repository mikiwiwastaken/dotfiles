return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"WhoIsSethDaniel/mason-tool-installer.nvim",
			"saghen/blink.cmp",
			"b0o/SchemaStore.nvim",
		},
		config = function()
			require("mason-lspconfig").setup({
				ensure_installed = {
					"bashls",
					"yamlls",
					"jsonls",
					"taplo",
					"terraformls",
					"dockerls",
					"docker_compose_language_service",
					"pyright",
					"ruff",
					"lua_ls",
					"marksman",
					"sqlls",
				},
				automatic_enable = true,
			})

			require("mason-tool-installer").setup({
				ensure_installed = {
					"stylua",
					"shfmt",
					"yamlfmt",
					"prettier",
					"sqlfluff",
					"hadolint",
					"shellcheck",
					"yamllint",
					"tflint",
				},
			})

			vim.lsp.config("yamlls", {
				settings = {
					yaml = {
						schemaStore = { enable = false, url = "" },
						schemas = require("schemastore").yaml.schemas(),
					},
				},
			})

			vim.lsp.config("jsonls", {
				settings = {
					json = {
						schemas = require("schemastore").json.schemas(),
						validate = { enable = true },
					},
				},
			})

			vim.lsp.config("ruff", {
				on_attach = function(client)
					client.server_capabilities.hoverProvider = false
				end,
			})

			vim.lsp.config("lua_ls", {
				settings = { Lua = { diagnostics = { globals = { "vim" } } } },
			})

			vim.api.nvim_create_autocmd("LspAttach", {
				callback = function(ev)
					local map = function(keys, fn, desc)
						vim.keymap.set("n", keys, fn, { buffer = ev.buf, desc = desc })
					end
					map("gd", vim.lsp.buf.definition, "Go to definition")
					map("<leader>rn", vim.lsp.buf.rename, "Rename symbol")
					map("<leader>ca", vim.lsp.buf.code_action, "Code action")
					map("<leader>e", vim.diagnostic.open_float, "Show diagnostic")
					map("<leader>dl", vim.diagnostic.setloclist, "Diagnostics to location list")
				end,
			})

			vim.diagnostic.config({
				virtual_text = false,
				underline = true,
				signs = true,
				severity_sort = true,
				float = { border = "rounded", source = true },
			})

			vim.api.nvim_create_autocmd("CursorHold", {
				callback = function()
					vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
				end,
			})
		end,
	},
}
