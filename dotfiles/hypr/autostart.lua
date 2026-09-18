-- Z13-specific autostart/env on top of Omarchy's own defaults (Phase 4).

-- Force Chromium-based browsers (Chrome, Brave, Edge, etc.) to use Wayland native scaling
hl.env("ELECTRON_OZONE_PLATFORM_HINT", "auto")
hl.env("CHROMIUM_OZONE_PLATFORM_HINT", "auto")

-- Silence fcitx5 Wayland diagnose warning (gaming-mode installer)
hl.env("FCITX_NO_WAYLAND_DIAGNOSE", "1")

-- ASUS ROG Flow Z13: notification on Fn+F5 (Armory Crate key) platform-profile cycling
o.launch_on_start("~/.local/bin/rog-profile-notify.sh")
