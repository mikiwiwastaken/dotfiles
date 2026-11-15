return {
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			{ "mason-org/mason.nvim", opts = {} },
			"mason-org/mason-lspconfig.nvim",
			"saghen/blink.cmp",
		},
		config = function()
			-- Install servers via Mason and auto-enable them
			require("mason-lspconfig").setup({
				ensure_installed = {
					"lua_ls",
					"ts_ls",
					"html",
					"cssls",
					"jsonls",
					"pyright",
					"ruff",
					"eslint",
					"emmet_language_server",
				},
				automatic_enable = true,
			})

			-- Let pyright own hover; ruff only reports lint errors
			vim.lsp.config("ruff", {
				on_attach = function(client)
					client.server_capabilities.hoverProvider = false
				end,
			})

			-- Teach lua_ls about the `vim` global
			vim.lsp.config("lua_ls", {
				settings = { Lua = { diagnostics = { globals = { "vim" } } } },
			})

			-- Buffer-local keymaps when a server attaches
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

			vim.api.nvim_create_autocmd("BufWritePre", {
				pattern = { "*.js", "*.jsx", "*.ts", "*.tsx" },
				command = "silent! LspEslintFixAll",
			})

			vim.diagnostic.config({
				virtual_text = false,
				underline = true,
				signs = true,
				severity_sort = true,
				float = { border = "rounded", source = true },
			})

			-- Show the error in a floating window only when the cursor rests on it
			vim.api.nvim_create_autocmd("CursorHold", {
				callback = function()
					vim.diagnostic.open_float(nil, { focus = false, scope = "cursor" })
				end,
			})
		end,
	},
}
