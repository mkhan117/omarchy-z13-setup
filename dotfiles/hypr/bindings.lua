-- Z13-specific keybindings on top of Omarchy's own defaults (Phase 4).
-- See docs/rog-keys.md for the human-readable table.
--
-- hy3 is not installed on this Omarchy version (hyprpm itself is gone) —
-- tiling runs on Omarchy's default dwindle layout, so hy3-only dispatchers
-- (hy3:makegroup / hy3:changegroup / hy3:changefocus) and the old
-- `plugin { hy3 { ... } }` block have no equivalent here and were dropped.
-- Binds that duplicated an Omarchy 4.0.4 default on the exact same key
-- (workspace 1-10, SUPER+F fullscreen, SUPER+EQUAL/MINUS resize, mouse
-- drag/resize, arrow-key window swap, plain Terminal/Browser) were also
-- dropped rather than double-bound.

-- Omarchy 4.0.4 already binds SUPER+ALT+RETURN to its own Tmux terminal by
-- default (bindings/applications.lua) — no need to re-add it.

o.bind("SUPER + F1", "Show key bindings", "omarchy-menu-keybindings")

o.bind("ALT + SHIFT + XF86TouchpadOff", "Wayscriber (Copilot key)", "wayscriber")

-- Omarchy binds SUPER+SHIFT+F to "File manager" and the same toggle-bar
-- action to SUPER+SHIFT+SPACE by default; move it to our preferred key.
hl.unbind("SUPER + SHIFT + F")
o.bind_toggle("SUPER + SHIFT + F", "Toggle top bar", "bar")

-- Omarchy already binds SUPER+SHIFT+B to its own browser launch by default;
-- replace it with a truly blank new window instead.
hl.unbind("SUPER + SHIFT + B")
o.bind("SUPER + SHIFT + B", "Browser (blank window)", 'google-chrome-stable --new-window "about:blank"')

-- Nice bindings that can be rebound (all disabled by default):
-- o.bind("SUPER + SHIFT + M", "Music", { launch = "spotify", focus = "spotify" })
-- o.bind("SUPER + SHIFT + N", "Editor", { omarchy = "editor" })
-- o.bind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
-- o.bind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
-- o.bind("SUPER + SHIFT + G", "Signal", { launch = "uwsm-app -- signal-desktop", focus = "signal" })
-- o.bind("SUPER + SHIFT + O", "Obsidian", { launch = "uwsm-app -- obsidian -disable-gpu --enable-wayland-ime", focus = "^obsidian$" })
-- o.bind("SUPER + SHIFT + SLASH", "Passwords", { launch = "1password" })
-- o.bind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
-- o.bind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
-- o.bind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
-- o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
-- o.bind("SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
-- o.bind("SUPER + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
-- o.bind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
-- o.bind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })

-- Allow custom keybinding (default: show key bindings)
hl.unbind("SUPER + K")
-- Prevent SUPER+X from sending CTRL+X (allow s-x in Emacs)
hl.unbind("SUPER + X")
hl.unbind("SUPER + CTRL + S") -- share menu
hl.unbind("SUPER + CTRL + W") -- wifi
hl.unbind("SUPER + CTRL + B") -- useless battery thing
hl.unbind("SUPER + CTRL + N") -- nightlight thing i don't want

-- Window management. Omarchy's default SUPER+SHIFT+SPACE ("Toggle top
-- bar") is redundant now that Toggle top bar lives on SUPER+SHIFT+F above.
hl.unbind("SUPER + SHIFT + SPACE")
o.bind("SUPER + SHIFT + SPACE", "Toggle window mode (tile/float/sticky)", "~/.config/hypr/scripts/toggle-window-mode.sh")
o.bind("SUPER + Q", "Close window", hl.dsp.window.close())

-- jkl; directional focus/move (one key right of true vim hjkl). Overrides
-- Omarchy's default SUPER+J ("Toggle window split") and SUPER+L ("Toggle
-- workspace layout") — SUPER+SEMICOLON and SUPER+K have no default here.
hl.unbind("SUPER + J")
hl.unbind("SUPER + L")
o.bind("SUPER + J", "Focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + K", "Focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + SEMICOLON", "Focus right", hl.dsp.focus({ direction = "r" }))

o.bind("SUPER + SHIFT + J", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + SHIFT + L", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + SHIFT + SEMICOLON", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- jkl; already covers directional focus, so arrow-key focus (Omarchy's
-- default on SUPER+UP/DOWN) is freed up for brightness here.
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")
o.bind("SUPER + DOWN", "Decrease brightness", "~/.config/hypr/scripts/brightness-change.sh -5")
o.bind("SUPER + UP", "Increase brightness", "~/.config/hypr/scripts/brightness-change.sh +5")

o.bind("SUPER + CTRL + DOWN", "Decrease volume", "swayosd-client --output-volume lower")
o.bind("SUPER + CTRL + UP", "Increase volume", "swayosd-client --output-volume raise")

-- Overrides Omarchy's default XF86KbdLightOnOff handler: the Z13 has two
-- aura USB devices exposing separate asusd dbus interfaces for the same
-- backlight node (see docs/rog-keys.md Known Issues), so the stock
-- brightnessctl-based cycle doesn't work reliably here.
hl.unbind("XF86KbdLightOnOff")
o.bind("XF86KbdLightOnOff", "Toggle keyboard brightness", "~/.config/hypr/scripts/toggle-kbd-backlight.sh")
o.bind("XF86Launch3", "Toggle monitor mode (Double/External)", "~/.config/hypr/scripts/toggle-monitors.sh")

-- Zoom (accessibility) — macOS-style system-wide zoom. `hyprctl keyword`
-- doesn't work on this Hyprland version's Lua-native config parser, so the
-- actual zoom_factor math/eval lives in scripts/zoom.sh (hyprctl eval).
o.bind("SUPER + ALT + EQUAL", "Zoom in", "~/.config/hypr/scripts/zoom.sh in 0.5 3.0")
o.bind("SUPER + ALT + MINUS", "Zoom out", "~/.config/hypr/scripts/zoom.sh out 0.5 1.0")
o.bind("SUPER + ALT + 0", "Reset zoom", "~/.config/hypr/scripts/zoom.sh reset")

o.bind("SUPER + CTRL + W", "Zoom in", "~/.config/hypr/scripts/zoom.sh in 1.0 6.0")
o.bind("SUPER + CTRL + S", "Zoom out", "~/.config/hypr/scripts/zoom.sh out 1.0 1.0")
-- Overrides Omarchy's default SUPER+CTRL+F ("Tiled full screen").
hl.unbind("SUPER + CTRL + F")
o.bind("SUPER + CTRL + F", "Reset zoom", "~/.config/hypr/scripts/zoom.sh reset")

-- Voice dictation - Super+D for live streaming
o.bind("SUPER + D", "Voice dictation (toggle)", "~/.config/hypr/scripts/dictate.sh")

-- Screenshot
o.bind("ALT + SHIFT + S", "Screenshot", "omarchy-cmd-screenshot")
o.bind("ALT + SHIFT + CTRL + S", "Screen recording", "omarchy-cmd-screenrecord")

-- Workspace rename/swap (empty input reverts to number)
o.bind("SUPER + F2", "Rename workspace", "~/.config/hypr/scripts/rename-workspace.sh")
o.bind("SUPER + F3", "Swap workspace position", "~/.config/hypr/scripts/swap-workspace.sh")

-- Gaming
o.bind(
  "SUPER + F5",
  "Steam Big Picture",
  '[workspace 5] bash -c \'env MANGOHUD=1 gamescope -W 2560 -H 1600 -r 180 --adaptive-sync --steam --force-grab-cursor -f -- steam -gamepadui; pkill -f "Decky Loader" 2>/dev/null; sudo -n rm -f /run/systemd/system/{suspend,sleep,hibernate,hybrid-sleep}.target; sudo -n systemctl daemon-reload\''
)
o.bind(
  "SUPER + F6",
  "Steam Big Picture",
  '[workspace 5] bash -c \'env MANGOHUD=1 gamescope -W 2560 -H 1440 -r 239.96 --adaptive-sync --steam --force-grab-cursor -f -- steam -gamepadui; pkill -f "Decky Loader" 2>/dev/null; sudo -n rm -f /run/systemd/system/{suspend,sleep,hibernate,hybrid-sleep}.target; sudo -n systemctl daemon-reload\''
)
o.bind(
  "SUPER + F7",
  "Steam Big Picture",
  '[workspace 5] bash -c \'env MANGOHUD=1 gamescope -W 3840 -H 2160 -r 60 --adaptive-sync --steam --force-grab-cursor -f -- steam -gamepadui; pkill -f "Decky Loader" 2>/dev/null; sudo -n rm -f /run/systemd/system/{suspend,sleep,hibernate,hybrid-sleep}.target; sudo -n systemctl daemon-reload\''
)

o.bind("SUPER + SHIFT + DELETE", "LSFG Config (Frame Gen)", "~/.config/hypr/scripts/toggle-lsfg-overlay.sh")

-- ASUS ROG Flow Z13 hardware. Overrides Omarchy's default SUPER+V
-- ("Universal paste" — clipboard history is still reachable another way).
hl.unbind("SUPER + V")
o.bind("SUPER + V", "Toggle virtual keyboard", "pkill wvkbd-deskintl || wvkbd-deskintl -L 300")
o.bind("SUPER + SHIFT + F5", "Gaming Mode", "/usr/local/bin/switch-to-gaming")
o.bind("SUPER + SHIFT + R", "ROG Control Center", "rog-control-center")
