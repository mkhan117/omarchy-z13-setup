# ROG Flow Z13 — Key Mapping & Power Profiles

## Physical Keys

| Key | Keysym / Handler | Action |
|-----|-------------------|--------|
| **Side button** | `XF86Launch3` | Toggle gaming mode (enter from Hyprland, exit from gamescope) |
| **Fn+F5** (Armory Crate) | asusd (ACPI, no keysym) | Cycles power profile: Quiet → Balanced → Performance |
| **Fn+F6** (Screenshot) | `Super+Shift+S` (firmware) | Screenshot (`omarchy-capture-screenshot`) |
| **Fn+F11** (Kbd backlight) | `XF86KbdLightOnOff` | Cycle keyboard backlight (handled by omarchy default) |

## Keyboard Shortcuts

Custom shortcuts added by this repo's `dotfiles/hypr/bindings.conf` (Phase 4),
on top of Omarchy's own defaults. For window tiling / focus / hy3 group
keybindings, see [docs/z13flow/hy3.md](z13flow/hy3.md) instead.

| Shortcut | Action |
|----------|--------|
| Click the Waybar power-profile module | Cycle Quiet → Balanced → Performance → Ultra (Performance Plus) |
| `Super+Shift+S` | Screenshot (firmware Fn+F6 also sends this) |
| `Super+Shift+R` | ROG Control Center |
| `Super+V` | Toggle virtual keyboard (tablet mode) |

### Apps & launching

| Shortcut | Action |
|----------|--------|
| `Super+Alt+Return` | Terminal, opened as a tmux session |
| `Super+Shift+Return` | Browser |
| `Super+Shift+B` | Browser, new blank window |
| `Super+Shift+Alt+B` | Browser, private window |
| `Alt+Shift+XF86TouchpadOff` (Copilot key) | Wayscriber |

### Window & workspace

| Shortcut | Action |
|----------|--------|
| `Super+Shift+Space` | Toggle window mode: tile / float / sticky |
| `Super+F` | Toggle fullscreen |
| `Super+Shift+F` | Toggle Waybar (top bar) |
| `Super+Equal` / `Super+Minus` | Grow / shrink active window |
| `Super+F2` | Rename current workspace (empty input reverts to number) |
| `Super+F3` | Swap current workspace's position |
| `XF86Launch3` (side button) | Toggle monitor mode (Double/External) — outside gaming mode |

### Screenshots & recording

| Shortcut | Action |
|----------|--------|
| `Alt+Shift+S` | Screenshot |
| `Alt+Shift+Ctrl+S` | Screen recording |

### Zoom (accessibility)

| Shortcut | Action |
|----------|--------|
| `Super+Alt+Equal` / `Super+Ctrl+W` | Zoom in (+0.5 / +1.0 step) |
| `Super+Alt+Minus` / `Super+Ctrl+S` | Zoom out (-0.5 / -1.0 step) |
| `Super+Alt+0` / `Super+Ctrl+F` | Reset zoom |

### Voice & brightness/volume

| Shortcut | Action |
|----------|--------|
| `Super+D` | Toggle voice dictation |
| `Super+Up` / `Super+Down` | Increase / decrease brightness |
| `Super+Ctrl+Up` / `Super+Ctrl+Down` | Increase / decrease volume |
| `XF86KbdLightOnOff` (Fn+F11) | Cycle keyboard backlight |

### Gaming

| Shortcut | Action |
|----------|--------|
| `Super+Shift+F5` | Enter Gaming Mode (Gamescope/Steam session handoff) |
| `Super+F5` | Steam Big Picture — 2560×1600 @ 180Hz |
| `Super+F6` | Steam Big Picture — 2560×1440 @ 239.96Hz |
| `Super+F7` | Steam Big Picture — 3840×2160 @ 60Hz |
| `Super+Shift+Delete` | Toggle LSFG (frame gen) config overlay |

## Power Profiles (Performance Plus)

Power management is handled entirely by **Performance Plus** (phase 5) — see
[docs/z13flow/performance-plus.md](z13flow/performance-plus.md) for the full
design. The Waybar module cycles `Q -> B -> P -> U -> Q`, applying explicit
`ryzenadj` PPT limits and a Curve Optimizer undervolt per profile, on top of
`power-profiles-daemon`.

| Profile | Sustained (STAPM) | Burst (PPT fast) | Undervolt |
|---------|-------------------|-------------------|-----------|
| Quiet (`Q`) | 28W | 35W | -20 |
| Balanced (`B`) | 45W | 55W | -20 |
| Performance (`P`) | 65W | 85W | -20 |
| Ultra (`U`) | 120W | 120W | -15 (milder, for stability at high wattage) |

The Armory Crate key (Fn+F5) also cycles the ACPI platform profile directly
via asusd, independent of the Waybar module; `~/.local/bin/rog-profile-notify.sh`
shows a notification on each change and clears Ultra's state file if it fires
while Ultra is active, so Waybar doesn't keep showing "Ultra" after you've
manually switched away via the hardware key.

### Check current profile

```bash
cat /sys/firmware/acpi/platform_profile
# or
asusctl profile get
# or, for live PPT/undervolt values:
~/.local/bin/ryzenadj -i
```

> **Do not** install a second tool that sets TDP/PPT limits directly (a raw
> `asus-nb-wmi` sysfs writer, a Decky TDP plugin like SimpleDeckyTDP, etc.)
> alongside Performance Plus — concurrent writers to the same power-limit
> registers is what caused the instability this system was built to fix.

## Known Issues

### Keyboard backlight not persisting across reboots

The Z13 has two USB aura devices (`0b05:1a30` keyboard, `0b05:18c6` N-KEY) that
both bind to the same `asus::kbd_backlight` sysfs node. asusd registers them as
separate LED controllers and restores brightness per-device on boot. If the N-KEY
config (`/etc/asusd/aura_18c6.ron`) has `brightness: Off`, it overrides the
keyboard brightness on boot. The install script (phase 2) fixes this by setting
both configs to `brightness: High`.

### `asusctl leds next` fails with "Multiple asusd interfaces devices found"

Same root cause as above — asusd exposes two dbus interfaces for the same
backlight device. The CLI refuses to act when it finds multiple interfaces.
Keyboard backlight cycling works via the hardware Fn key because omarchy handles
`XF86KbdLightOnOff` using `brightnessctl` directly (`omarchy-brightness-keyboard`).
