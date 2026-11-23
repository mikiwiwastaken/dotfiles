return {
	-- Auto close brackets and quotes: ( ) [ ] { } " ' `
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts = true,
		},
	},

	-- Add/change/delete surrounding pairs: ysiw" / cs"' / ds"
	{ "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },
}
