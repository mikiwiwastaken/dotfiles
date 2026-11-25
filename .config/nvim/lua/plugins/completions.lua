return {
	{
		"saghen/blink.cmp",
		version = "v1",
		opts = {
			keymap = {
				preset = "default",
			},

			sources = {
				default = {
					"lsp",
					"path",
					"snippets",
					"buffer",
				},
			},

			completion = {
				trigger = {
					show_on_insert = true,
				},

				menu = {
					auto_show = true,
				},

				documentation = {
					auto_show = true,
					auto_show_delay_ms = 300,
				},

				ghost_text = {
					enabled = true,
				},
			},
		},
	},
}
