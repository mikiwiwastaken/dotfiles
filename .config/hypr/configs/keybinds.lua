local mainMod = "SUPER"

-------------------------------------------------------------------- independent keybinds
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind(mainMod .. " + E", hl.dsp.exec_cmd("kitty -e yazi"))
hl.bind(mainMod .. " + Escape", hl.dsp.exec_cmd("kitty -e btop"))
hl.bind(mainMod .. " + SUPER_L", hl.dsp.exec_cmd("qs ipc call launcher toggle"), { release = true })
hl.bind(mainMod .. " + Backspace", hl.dsp.exec_cmd("qs ipc call power toggle"), { release = true })
hl.bind(mainMod .. " + V", hl.dsp.exec_cmd("qs ipc call launcher clipboard"))
hl.bind(mainMod .. " + N", hl.dsp.exec_cmd("qs ipc call dnd toggle"))

hl.bind("CTRL + ALT + L", hl.dsp.exec_cmd("hyprlock"))
hl.bind(mainMod .. " + SHIFT + C", hl.dsp.exec_cmd("hyprpicker -a -n"))

hl.bind("Print", hl.dsp.exec_cmd("~/.local/bin/screenshot full"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.local/bin/screenshot region"))
hl.bind("CTRL + Print", hl.dsp.exec_cmd("~/.local/bin/screenshot window"))

hl.bind(mainMod .. " + R", hl.dsp.exec_cmd("~/.local/bin/record full"))
hl.bind(mainMod .. " + SHIFT + R", hl.dsp.exec_cmd("~/.local/bin/record region"))
hl.bind(mainMod .. " + CTRL + R", hl.dsp.exec_cmd("~/.local/bin/record window"))

hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("qs ipc call osd volumeUp"), { repeating = true, locked = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("qs ipc call osd volumeDown"), { repeating = true, locked = true })
hl.bind("XF86AudioMute", hl.dsp.exec_cmd("qs ipc call osd volumeMute"), { locked = true })
hl.bind("XF86AudioMicMute", hl.dsp.exec_cmd("qs ipc call osd micMute"), { locked = true })
hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("qs ipc call osd brightnessUp"), { repeating = true, locked = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("qs ipc call osd brightnessDown"), { repeating = true, locked = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPause", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })

-------------------------------------------------------------------- hyprland keybinds
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind(mainMod .. " + D", hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" }))
hl.bind(mainMod .. " + C", hl.dsp.window.center())
hl.bind(mainMod .. " + P", hl.dsp.window.pin())
hl.bind(mainMod .. " + Q", hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.window.kill())

hl.bind(mainMod .. " + ALT + R", hl.dsp.reload_config())

hl.bind(mainMod .. " + SHIFT + Space", function()
	local win = hl.get_active_window()
	local mon = hl.get_active_monitor()
	if win == nil or mon == nil then
		return
	end

	if win.floating then
		-- Floating -> tiled: just toggle back
		hl.dispatch(hl.dsp.window.float({ action = "disable", window = win }))
		return
	end

	-- Tiled -> floating: enable float, then set the size and center it
	local w = mon.width * 0.5
	local h = mon.height * 0.5

	hl.dispatch(hl.dsp.window.float({ action = "enable", window = win }))
	hl.dispatch(hl.dsp.window.resize({ x = w, y = h, relative = false, window = win }))
	hl.dispatch(hl.dsp.window.move({
		x = mon.width * 0.25,
		y = mon.height * 0.25,
		relative = false,
		window = win,
	}))
	hl.dispatch(hl.dsp.window.center({ window = win }))
end)

-------------------------------------------------------------------- focus/swap
hl.bind(mainMod .. " + H", hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + L", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + K", hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + J", hl.dsp.focus({ direction = "down" }))

hl.bind(mainMod .. " + CTRL + right", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + CTRL + left", hl.dsp.focus({ workspace = "e-1" }))
hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up", hl.dsp.focus({ workspace = "e-1" }))

hl.bind(mainMod .. " + Tab", hl.dsp.focus({ last = true }))

hl.bind(mainMod .. " + ALT + H", hl.dsp.focus({ monitor = "l" }))
hl.bind(mainMod .. " + ALT + L", hl.dsp.focus({ monitor = "r" }))

hl.bind(mainMod .. " + SHIFT + H", hl.dsp.window.move({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + L", hl.dsp.window.move({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + K", hl.dsp.window.move({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + J", hl.dsp.window.move({ direction = "down" }))

hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(), { mouse = true })

for i = 1, 10 do
	local key = i % 10
	hl.bind(mainMod .. " + " .. key, hl.dsp.focus({ workspace = i }))
	hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))

-------------------------------------------------------------------- move/resize
hl.bind(mainMod .. " + CTRL + H", hl.dsp.window.resize({ x = -20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + L", hl.dsp.window.resize({ x = 20, y = 0, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + K", hl.dsp.window.resize({ x = 0, y = -20, relative = true }), { repeating = true })
hl.bind(mainMod .. " + CTRL + J", hl.dsp.window.resize({ x = 0, y = 20, relative = true }), { repeating = true })

hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })

-------------------------------------------------------------------- gestures
hl.gesture({
	fingers = 3,
	direction = "horizontal",
	action = "workspace",
})

hl.gesture({
	fingers = 3,
	direction = "swipe",
	mods = "CTRL",
	action = "move",
})

hl.gesture({
	fingers = 3,
	direction = "swipe",
	mods = "ALT",
	action = "resize",
})
