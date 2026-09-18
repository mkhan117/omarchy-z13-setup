-- Z13-specific input config on top of Omarchy's own defaults (Phase 4).

hl.config({
  input = {
    kb_layout = "us",
    -- Original: ctrl:nocaps - changed to caps:ctrl_modifier for better modifier combo support
    kb_options = "caps:ctrl_modifier,altwin:swap_alt_win",

    repeat_rate = 80,
    repeat_delay = 175,

    numlock_by_default = true,

    touchpad = {
      -- Use two-finger clicks for right-click instead of lower-right corner
      clickfinger_behavior = true,

      -- Control the speed of your scrolling
      scroll_factor = 0.15,

      -- Disable tap-and-drag
      tap_and_drag = false,
    },
  },
})

-- Device-specific: Trackpad (asustek-computer-inc.-gz302ea-keyboard-touchpad)
hl.device({
  name = "asustek-computer-inc.-gz302ea-keyboard-touchpad",
  -- accel-curve.js 6 8 2, FROM ACCELSCRIPT
  accel_profile = "custom 0.316 0.000 0.174 0.429 0.726 1.055 1.410 1.676 1.733 1.862 2.062 2.334 2.677 3.092 3.579 4.137 4.766 5.467 6.240 7.084 8.000",
})

-- Device-specific: Mouse (logitech-usb-receiver)
hl.device({
  name = "logitech-usb-receiver",
  sensitivity = -0.90,
  accel_profile = "adaptive",
})

-- Scroll nicely in the terminal
o.window("(Alacritty|kitty)", { scroll_touchpad = 2.5 })
o.window("com.mitchellh.ghostty", { scroll_touchpad = 0.2 })

-- Tablet/Stylus configuration - map to laptop screen
hl.device({ name = "elan9008:00-04f3:43c7-stylus", output = "eDP-1" })
hl.device({ name = "elan9008:00-04f3:43c7", output = "eDP-1" })
