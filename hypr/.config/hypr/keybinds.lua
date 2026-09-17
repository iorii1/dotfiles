-- See https://wiki.hypr.land/Configuring/Basics/Binds/

hl.bind("SUPER + Q", hl.dsp.window.close())
hl.bind("SUPER + RETURN", hl.dsp.exec_cmd("kitty"))
hl.bind("SUPER + M", hl.dsp.exit())
hl.bind("SUPER + R", hl.dsp.exec_cmd("hyprctl reload"))
hl.bind("SUPER + SHIFT + E", hl.dsp.exit())

hl.bind("SUPER + SPACE", hl.dsp.exec_cmd("qs ipc call launcher toggle"))
hl.bind("SUPER + V", hl.dsp.exec_cmd("qs ipc call clipboard toggle"))
hl.bind("SUPER + N", hl.dsp.exec_cmd("qs ipc call notifications toggle"))
hl.bind("SUPER + TAB", hl.dsp.exec_cmd("qs ipc call overview toggle"))
hl.bind(
	"SUPER + W",
	hl.dsp.exec_cmd(
		"QS_WALLPAPER_DIR=$HOME/Pictures/Wallpapers ~/.local/share/qs-wallpaper-picker/scripts/open_picker.sh"
	)
)

-- SUPER+L (and SUPER+SHIFT+L) are taken by the vim-style movefocus/
-- swapwindow binds below, so lock lives on SUPER+Escape instead
hl.bind("SUPER + Escape", hl.dsp.exec_cmd("loginctl lock-session"))

hl.bind("SUPER + F", hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" }))
hl.bind("SUPER + SHIFT + space", hl.dsp.window.float({ action = "toggle" }))

-- Next/prev workspace (mango's "skip empty tags" has no direct Hyprland
-- equivalent, so this is a plain relative move instead)
hl.bind("SUPER + Page_Down", hl.dsp.focus({ workspace = "+1" }))
hl.bind("SUPER + Page_Up", hl.dsp.focus({ workspace = "-1" }))
hl.bind("SUPER + SHIFT + Page_Down", hl.dsp.window.move({ workspace = "+1" }))
hl.bind("SUPER + SHIFT + Page_Up", hl.dsp.window.move({ workspace = "-1" }))

hl.bind("SUPER + left", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + right", hl.dsp.focus({ direction = "right" }))
hl.bind("SUPER + up", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + down", hl.dsp.focus({ direction = "down" }))

hl.bind("SUPER + h", hl.dsp.focus({ direction = "left" }))
hl.bind("SUPER + j", hl.dsp.focus({ direction = "down" }))
hl.bind("SUPER + k", hl.dsp.focus({ direction = "up" }))
hl.bind("SUPER + l", hl.dsp.focus({ direction = "right" }))

hl.bind("SUPER + SHIFT + left", hl.dsp.window.swap({ direction = "left" }))
hl.bind("SUPER + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind("SUPER + SHIFT + up", hl.dsp.window.swap({ direction = "up" }))
hl.bind("SUPER + SHIFT + down", hl.dsp.window.swap({ direction = "down" }))

hl.bind("SUPER + SHIFT + h", hl.dsp.window.swap({ direction = "left" }))
hl.bind("SUPER + SHIFT + j", hl.dsp.window.swap({ direction = "down" }))
hl.bind("SUPER + SHIFT + k", hl.dsp.window.swap({ direction = "up" }))
hl.bind("SUPER + SHIFT + l", hl.dsp.window.swap({ direction = "right" }))

-- Resize the focused window (h/l = width, j/k = height) — animates here,
-- unlike mango, since resizeactive isn't hardcoded to skip tiled clients
hl.bind("SUPER + CTRL + h", hl.dsp.window.resize({ x = -50, y = 0 }))
hl.bind("SUPER + CTRL + l", hl.dsp.window.resize({ x = 50, y = 0 }))
hl.bind("SUPER + CTRL + j", hl.dsp.window.resize({ x = 0, y = 50 }))
hl.bind("SUPER + CTRL + k", hl.dsp.window.resize({ x = 0, y = -50 }))

hl.bind("SUPER + CTRL + left", hl.dsp.window.resize({ x = -50, y = 0 }))
hl.bind("SUPER + CTRL + right", hl.dsp.window.resize({ x = 50, y = 0 }))
hl.bind("SUPER + CTRL + down", hl.dsp.window.resize({ x = 0, y = 50 }))
hl.bind("SUPER + CTRL + up", hl.dsp.window.resize({ x = 0, y = -50 }))

hl.bind("SUPER + mouse:272", hl.dsp.window.drag(), { mouse = true })
hl.bind("SUPER + mouse:273", hl.dsp.window.resize(), { mouse = true })
hl.bind("SUPER + CTRL + mouse:273", hl.dsp.window.close())

-- Touchpad gestures — syntax not yet verified live, check once Hyprland
-- is actually running and adjust (see PR notes). "workspace" is a built-in
-- gesture action; there's no built-in "focus" action, so the 2-finger
-- swipes dispatch through a Lua closure instead.
hl.gesture({ fingers = 3, direction = "horizontal", action = "workspace" })

hl.gesture({
	fingers = 2,
	direction = "left",
	action = function()
		hl.dispatch(hl.dsp.focus({ direction = "left" }))
	end,
})
hl.gesture({
	fingers = 2,
	direction = "right",
	action = function()
		hl.dispatch(hl.dsp.focus({ direction = "right" }))
	end,
})
hl.gesture({
	fingers = 2,
	direction = "up",
	action = function()
		hl.dispatch(hl.dsp.focus({ direction = "up" }))
	end,
})
hl.gesture({
	fingers = 2,
	direction = "down",
	action = function()
		hl.dispatch(hl.dsp.focus({ direction = "down" }))
	end,
})

for i = 1, 9 do
	hl.bind("SUPER + " .. i, hl.dsp.focus({ workspace = i }))
	hl.bind("SUPER + SHIFT + " .. i, hl.dsp.window.move({ workspace = i }))
end

hl.bind(
	"XF86AudioRaiseVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%+ && qs ipc call osd volume"),
	{ locked = true }
)
hl.bind(
	"XF86AudioLowerVolume",
	hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_SINK@ 5%- && qs ipc call osd volume"),
	{ locked = true }
)
hl.bind(
	"XF86AudioMute",
	hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SINK@ toggle && qs ipc call osd volume"),
	{ locked = true }
)
hl.bind("SHIFT + XF86AudioMute", hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_SOURCE@ toggle"), { locked = true })

hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"), { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"), { locked = true })
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })

hl.bind("XF86MonBrightnessUp", hl.dsp.exec_cmd("brightnessctl s +2% && qs ipc call osd brightness"), { locked = true })
hl.bind(
	"SHIFT + XF86MonBrightnessUp",
	hl.dsp.exec_cmd("brightnessctl s 100% && qs ipc call osd brightness"),
	{ locked = true }
)
hl.bind(
	"XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl s 2%- && qs ipc call osd brightness"),
	{ locked = true }
)
hl.bind(
	"SHIFT + XF86MonBrightnessDown",
	hl.dsp.exec_cmd("brightnessctl s 1% && qs ipc call osd brightness"),
	{ locked = true }
)

hl.bind("Print", hl.dsp.exec_cmd("~/.local/bin/take-screenshot full"))
hl.bind("SHIFT + Print", hl.dsp.exec_cmd("~/.local/bin/take-screenshot region-clip"))
hl.bind("SUPER + SHIFT + s", hl.dsp.exec_cmd("~/.local/bin/take-screenshot region-save"))
