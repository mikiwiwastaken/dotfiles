return {
	{
		"saghen/blink.cmp",
		version = "v1",
		opts = {
			keymap = { preset = "default" },
			sources = {
				default = { "lsp", "path", "snippets", "buffer" },
			},
			completion = {
				documentation = { auto_show = true },
			},
		},
	},
}
