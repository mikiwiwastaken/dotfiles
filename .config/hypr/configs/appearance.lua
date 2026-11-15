hl.config({
	general = {
		gaps_in = 5,
		gaps_out = 10,

		border_size = 2,

		col = {
			active_border = { colors = { "rgba(89b4faee)", "rgba(cba6f7ee)" }, angle = 45 },
			inactive_border = "rgba(45475aaa)",
		},

		resize_on_border = true,

		allow_tearing = false,

		layout = "dwindle",

		snap = {
			enabled = true,
		},
	},

	decoration = {
		rounding = 10,
		rounding_power = 2,

		active_opacity = 1.0,
		inactive_opacity = 1.0,

		shadow = {
			enabled = true,
			range = 4,
			render_power = 3,
			color = 0xee1a1a1a,
		},

		blur = {
			enabled = true,
			size = 8,
			passes = 3,
			vibrancy = 0.1696,
		},
	},

	animations = {
		enabled = true,
	},

	misc = {
		disable_hyprland_logo = true,
		disable_splash_rendering = true,
		key_press_enables_dpms = true,
		mouse_move_enables_dpms = true,
		font_family = "JetBrainsMono Nerd Font",
		bell_sound = "none",
	},

	ecosystem = {
		no_donation_nag = true,
		no_update_news = true,
	},

	dwindle = {
		preserve_split = true,
	},
})
