-- Z13-specific monitor config on top of Omarchy's own defaults (Phase 4).
-- List current monitors and resolutions possible: hyprctl monitors

-- Generic Z13 default: named eDP-1 (required for iio-hyprland auto-rotation
-- and Omarchy's scaling cycle) at the panel's preferred mode, 2x scale.
-- Replace this with an explicit mode (see the commented examples below) if
-- `hyprctl monitors` shows you need one.
hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = 2 })
o.exec_on_start("iio-hyprland")

-- Optimized for retina-class 2x displays, like 13" 2.8K, 27" 5K, 32" 6K.
hl.env("GDK_SCALE", "2")
-- hl.monitor({ output = "eDP-1", mode = "2880x1800@180", position = "0x0", scale = 2 })

-- Example fixed-mode + external monitor setup (adjust to your own panel and
-- any external display before uncommenting — these modes are author-specific
-- from the upstream z13flow dotfiles, not generic Z13 defaults):
-- hl.monitor({ output = "eDP-1", mode = "2560x1600@180", position = "384x1152", scale = 2 })
-- hl.monitor({ output = "DP-1", mode = "2560x1440@239.96", position = "0x0", scale = 1.25 })

-- External-only (disable internal panel):
-- hl.monitor({ output = "eDP-1", enabled = false })
-- hl.monitor({ output = "DP-1", mode = "2560x1440@239.96", position = "0x0", scale = 1.25 })

-- Good compromise for 27" or 32" 4K monitors (but fractional!):
-- hl.env("GDK_SCALE", "1.75")
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1.666667 })

-- Straight 1x setup for low-resolution displays like 1080p or 1440p:
-- hl.env("GDK_SCALE", "1")
-- hl.monitor({ output = "", mode = "preferred", position = "auto", scale = 1 })
