# ROG Flow Z13 — Key Mapping & Power Profiles

## Physical Keys

| Key | Keysym / Handler | Action |
|-----|-------------------|--------|
| **Side button** | `XF86Launch3` | Toggle gaming mode (enter from Hyprland, exit from gamescope) |
| **Fn+F5** (Armory Crate) | asusd (ACPI, no keysym) | Cycles power profile: Quiet → Balanced → Performance |
| **Fn+F6** (Screenshot) | `Super+Shift+S` (firmware) | Screenshot (`omarchy-capture-screenshot`) |
| **Fn+F11** (Kbd backlight) | `XF86KbdLightOnOff` | Cycle keyboard backlight (handled by omarchy default) |

## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| Click the Waybar power-profile module | Cycle Quiet → Balanced → Performance → Ultra (Performance Plus) |
| `Super+Shift+S` | Screenshot |
| `Super+Shift+R` | ROG Control Center |
| `Super+V` | Virtual keyboard (tablet mode) |

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
