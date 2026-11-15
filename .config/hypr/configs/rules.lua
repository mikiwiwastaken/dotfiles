hl.window_rule({
	name = "suppress-maximize-events",
	match = { class = ".*" },

	suppress_event = "maximize",
})

hl.window_rule({
	name = "fix-xwayland-drags",
	match = {
		class = "^$",
		title = "^$",
		xwayland = true,
		float = true,
		fullscreen = false,
		pin = false,
	},

	no_focus = true,
})

hl.window_rule({
	match = { class = "kitty" },
	opacity = "0.92 override 0.92 override 1.0 override",
})

hl.layer_rule({
	match = { namespace = "^(waybar|wofi|swaync-control-center|swaync-notification-window|swayosd|logout_dialog)$" },
	blur = true,
	blur_popups = true,
	ignore_alpha = 0,
})

hl.layer_rule({
	match = { namespace = "wofi" },
	animation = "popin 95%",
})

hl.layer_rule({
	match = { namespace = "swaync-control-center" },
	animation = "slide right",
})

hl.layer_rule({
	match = { namespace = "logout_dialog" },
	animation = "fade",
})

hl.layer_rule({
	match = { namespace = "^(hyprpicker|selection)$" },
	no_anim = true,
})
