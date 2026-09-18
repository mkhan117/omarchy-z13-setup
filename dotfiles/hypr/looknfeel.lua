-- Z13-specific look'n'feel on top of Omarchy's own defaults (Phase 4).

hl.config({
  general = {
    -- No gaps between windows or borders
    gaps_in = 0,
    gaps_out = 0,
    border_size = 1,
  },

  cursor = {
    -- Enable cursor warping when focus changes
    no_warps = false,
  },

  animations = {
    enabled = false,
  },

  -- Enable VRR (Variable Refresh Rate) - Only in fullscreen (0=off, 1=always, 2=fullscreen only)
  misc = {
    vrr = 2,
  },
})

-- Remove transparency
o.window(".*", { opacity = "1.0 1.0" })

-- No border when only one window on the workspace
o.window({ class = ".*", workspace = "w[1]" }, { border_size = 0 })

-- LSFG Overlay
o.window(
  { class = "lsfg-overlay" },
  { name = "lsfg-overlay", float = true, center = true, size = { 900, 700 }, animation = "slide", opacity = "0.95" }
)
