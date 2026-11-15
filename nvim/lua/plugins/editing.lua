return {
	-- Auto close brackets and quotes: ( ) [ ] { } " ' `
	{
		"windwp/nvim-autopairs",
		event = "InsertEnter",
		opts = {
			check_ts = true, -- use treesitter to avoid pairing inside strings/comments
		},
	},

	-- Auto close HTML/JSX tags and auto rename the paired tag
	{
		"windwp/nvim-ts-autotag",
		event = "InsertEnter",
		opts = {
			opts = {
				enable_close = true, -- <div> -> <div></div>
				enable_rename = true, -- edit one tag name, the other follows
				enable_close_on_slash = false, -- set true to close when typing "</"
			},
		},
	},

	-- Add/change/delete surrounding pairs: ysiw" / cs"' / ds"
	{ "kylechui/nvim-surround", version = "*", event = "VeryLazy", opts = {} },
}
