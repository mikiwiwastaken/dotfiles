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
	match = {
		namespace = "qs-bar",
	},
	no_anim = true,
	blur = true,
	blur_popups = true,
	ignore_alpha = 0.2,
})

hl.layer_rule({
	match = {
		namespace = "qs-osd",
	},
	no_anim = true,
	blur = true,
	ignore_alpha = 0.2,
})

hl.layer_rule({
	match = { namespace = "^(qs-launcher|qs-power)$" },
	blur = true,
	ignore_alpha = 0.5,
	no_anim = true,
})

hl.layer_rule({
	match = { namespace = "^(hyprpicker|selection)$" },
	no_anim = true,
})
