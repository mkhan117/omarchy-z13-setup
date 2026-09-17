# Omarchy ROG Z13 Setup

Post-install setup for the ASUS ROG Flow Z13 (2025, AMD Strix Halo) running
[Omarchy](https://github.com/basecamp/omarchy) / Hyprland on Arch Linux.

This is a merge of two previously separate community projects for the same
hardware:

- **[Cliffback/omarchy-rog-z13-setup](https://github.com/Cliffback/omarchy-rog-z13-setup)**
  — the phased, idempotent `install.sh` installer (kernel/drivers, firmware,
  Thunderbolt, hibernate, gaming tools, 3D-printing/UE app scaling fixes, etc.)
- **[Naomarik/Z13-StrixHalo-Omarchy](https://github.com/Naomarik/Z13-StrixHalo-Omarchy)**
  — the Hyprland/Waybar/EasyEffects dotfiles and **Performance Plus**, a far
  more battle-tested `ryzenadj`-based power management system.

Both repos shipped their own, incompatible power-management mechanism for the
same hardware. This repo keeps **only Performance Plus** (see
[Why one power system](#why-one-power-system) below) and combines everything
else, with all cross-references updated so the combined result installs
cleanly with no two phases fighting over the same file, keybind, or hardware
register.

## Usage

```bash
git clone https://github.com/<your-username>/omarchy-z13-setup.git
cd omarchy-z13-setup
./install.sh
```

The script prompts with y/n before each phase. If a phase has already been
completed, it is automatically skipped, so it's safe to re-run at any point.

After Phase 1 (kernel installation), the script offers to reboot. Re-run the
script after rebooting to continue with the remaining phases.

### Dry-run mode

```bash
./install.sh --dry-run
```

All prompts auto-answer yes and commands are printed instead of executed.

## Why one power system

Both source repos independently discovered that this hardware's SMU mailbox
and platform-profile/fan-curve stack are fragile: concurrent power-limit
writers, rapid re-application, or aggressive undervolts can hang or crash the
machine. Performance Plus (from Naomarik's repo) has the deeper documented
track record fixing these failure modes — a global `ryzenadj` rate-limiting
wrapper, click-debounced profile switching, and specific undervolt values
tuned after real instability incidents (see
[docs/z13flow/performance-plus.md](docs/z13flow/performance-plus.md)).

So this repo drops Cliffback's reactive AC-triggered profile auto-switcher and
its raw-sysfs `rog-quick.sh` TDP menu entirely, rather than trying to run both
mechanisms side by side. **Do not** add a second tool that writes TDP/PPT
limits directly (e.g. a Decky Loader TDP plugin like SimpleDeckyTDP) — see the
warning in [docs/rog-keys.md](docs/rog-keys.md).

The kernel choice was adjusted for the same reason: this repo installs
`linux-g14` (Naomarik's tested baseline) instead of Cliffback's CachyOS
kernel, since Performance Plus was validated against `linux-g14`'s
ASUS-specific fan-curve and platform-profile patches.

## What it does

The script runs eighteen phases in order:

**Phase 0 - System update**

Updates keyrings and system packages via pacman.

**Phase 1 - linux-g14 kernel and ASUS drivers**

Adds the G14 (asus-linux.org) repository to pacman.conf, installs the
`linux-g14` kernel and headers, and installs asusctl and rog-control-center.

**Phase 2 - asusd service fix**

Creates a systemd drop-in to add the missing `[Install]` section to
asusd.service, then enables and starts it. Also fixes the N-KEY device
(`aura_18c6.ron`) overriding keyboard backlight to Off on boot.

**Phase 3 - Hardware support**

Installs split firmware packages and marks them explicit (protects from
Omarchy's orphan cleanup). Installs AUR packages for tablet support
(`iio-hyprland-git`, `wvkbd-deskintl`) and `rofi-wayland`. Applies a Wi-Fi
stability fix for the MT7925E adapter, removes Omarchy's `soft-mixer`
WirePlumber config (breaks headphone/speaker jack switching), initializes the
speaker amp mixer, and enables HDMI audio auto-profile.

**Phase 4 - Desktop dotfiles (Hyprland / Waybar / EasyEffects)**

Deploys [`dotfiles/`](dotfiles/) — Z13-tuned Hyprland config (hy3 tiling,
tablet/stylus mapping, brightness/backlight scripts, dictation, gaming
keybinds), Waybar modules (profile switching, live PPT watts, thermals, idle
lock, notifications, refresh-rate toggle — including the Performance Plus
power modules wired up by Phase 5), and EasyEffects speaker/headphone/mic
presets. This replaces `~/.config/hypr/*` and `~/.config/waybar/*` wholesale
(backing up any existing config first — see the phase's output for the backup
path), matching upstream z13flow's own install method. Also installs a
systemd sleep hook that resets the ELAN touchpad after resume (fixes
corrupted multi-touch state from an xHCI resume glitch), and a notification
script for Fn+F5 platform-profile cycling.

> `dotfiles/hypr/monitors.conf` ships with a generic single-panel default
> (`monitor=eDP-1,preferred,auto,2`). If you use an external monitor, edit it
> to match your own setup — the original z13flow author's specific external
> display modes are preserved as commented examples, not applied by default.

**Phase 5 - Performance Plus (Power Management)**

Installs `ryzenadj` from the AUR, a global rate-limiting wrapper at
`~/.local/bin/ryzenadj` (shadows the real binary — see
[docs/z13flow/performance-plus.md](docs/z13flow/performance-plus.md) for why
calling `ryzenadj` too rapidly can hang the machine), a suspend/resume hook, an
AC-plug hook, the supporting udev rule and `tmpfiles.d` provisioning, and a
sudoers rule for passwordless operation from Waybar/systemd/udev. The Waybar
module deployed in Phase 4 cycles Quiet → Balanced → Performance → Ultra.

**Phase 6 - Gaming Mode + Tools (optional)**

Installs Gaming Mode — a Gamescope/Steam Big Picture session handoff bound to
`Super+Shift+F5` — via `scripts/gaming-mode-install.sh`. Optionally installs
Decky Loader, Heroic Games Launcher (+ a Gamescope compatibility patch), and
EmuDeck. **SimpleDeckyTDP is intentionally not offered** — see
[Why one power system](#why-one-power-system).

**Phase 7 - CachyOS Mirror Optimization (optional)**

Installs `cachyos-rate-mirrors` and ranks mirrors for optimal download
speeds. (Independent of the kernel choice in Phase 1 — this is just a mirror
ranking tool.)

**Phase 8 - Ollama GPU Setup (optional)**

Installs `ollama-vulkan` for GPU-accelerated LLM inference (AMD RDNA 3.5).
Configures Ollama as a systemd service: flash attention, 256k context, 24h
keep-alive, up to 3 concurrent models. For 30B+ models, set iGPU memory to
96GB in BIOS.

**Phase 9 - Audio Amplifier Gain (optional)**

Increases the CS35L41 speaker amplifier gain from 15.5dB to 19.5dB via
firmware bincfg symlinks — a hardware-level fix, independent of and
complementary to the EasyEffects software presets in Phase 4. Requires a
reboot. Very high volume (>~80%) may cause minor bass distortion, which is
normal for laptop speakers at full power.

**Phase 10 - Thunderbolt Dock Fix (optional)**

Installs udev rules to prevent the Alpine Ridge Thunderbolt controller from
entering D3 sleep (buggy ACPI `_PS3` breaks the PCIe tunnel to a dock) and to
rescan the PCI bus on dock replug.

**Phase 11 - Controller Gaming Mode Trigger (optional)**

Installs a background service watching for a Guide/PS button + Start combo on
any gamepad to auto-switch to Gaming Mode. Uses `python-evdev`, runs as a
systemd user service, inactive inside Gamescope sessions.

**Phase 12 - Audio Sink Routing**

Configures WirePlumber priority-based sink switching: Bluetooth > HDMI >
Internal speakers, disabling saved-default restoration so priority always
wins.

**Phase 13 - Hibernate Wake Fix (optional)**

Adds a kernel parameter (via `limine-entry-tool`) to ignore AMD GPIO
controller interrupt pins 2/3, preventing spurious hibernate wakes on
Ryzen 7000+/Strix Halo. Requires a reboot.

**Phase 14-16 - Slicer DPI scaling (optional)**

Lychee Slicer, Orca Bambu Studio, and Bambu Studio all render oversized on
Wayland; each phase installs the app from the AUR with a launcher wrapper
that corrects the scale factor.

**Phase 17 - Unreal Engine 5 (optional)**

Installs UE5 binary releases with Wayland/X11 fixes, HiDPI scaling, and
bidirectional Neovim integration (open a C++ class in UE → opens in nvim;
`:UnrealEngine open` from nvim → launches UE). See
[docs/unreal-engine-neovim-integration.md](docs/unreal-engine-neovim-integration.md).

**Phase 18 - Perforce (optional)**

Installs `p4` and `p4v`. See [docs/perforce-setup.md](docs/perforce-setup.md).

## Custom Hyprland keybindings

Phase 4 adds Z13-specific keybindings on top of Omarchy/z13flow's defaults —
see [docs/rog-keys.md](docs/rog-keys.md) for the full list and the power
profile / Performance Plus breakdown.

## File structure

```text
install.sh                Main entry point
lib/
  common.sh               Shared utilities (logging, prompts, checks, dry-run wrappers)
  phase0_update.sh         System update
  phase1_kernel.sh         G14 repo, linux-g14 kernel, ASUS tools
  phase2_asusd.sh          asusd service fix
  phase3_hardware.sh       Firmware, tablet utilities, Wi-Fi fix, audio fixes
  phase4_dotfiles.sh       Hyprland/Waybar/EasyEffects dotfiles deployment
  phase5_performance_plus.sh  Performance Plus power management install
  phase6_gaming.sh         Gaming Mode + optional tools
  phase7_mirrors.sh        CachyOS mirror optimization
  phase8_ollama.sh         Ollama GPU setup (Vulkan)
  phase9_audio_eq.sh       Audio amplifier gain (CS35L41 bincfg)
  phase10_thunderbolt_dock.sh  Thunderbolt dock D3 sleep fix
  phase11_controller_gaming.sh Controller gaming mode trigger
  phase12_audio_routing.sh     Audio sink priority routing
  phase13_hibernate_wake.sh    Hibernate wake fix (GPIO workaround)
  phase14_lychee_scaling.sh    Lychee Slicer DPI scaling fix
  phase15_orca_scaling.sh      Orca Bambu Studio DPI scaling fix
  phase16_bambu_scaling.sh     Bambu Studio DPI scaling fix
  phase17_unreal_engine.sh     Unreal Engine 5 installer + Neovim integration
  phase18_perforce.sh          Perforce (p4 + p4v) installer
dotfiles/
  hypr/                    Hyprland config deployed wholesale in Phase 4
  waybar/                  Waybar config + scripts deployed wholesale in Phase 4
  easyeffects/             Speaker/headphone/mic EasyEffects presets
performance-plus/
  ryzenadj-wrapper         Rate-limiting wrapper installed to ~/.local/bin/ryzenadj
  performance-plus-sleep-hook  Suspend/resume hook (reasserts limits — __HOME__ templated)
  performance-plus-ac-hook     AC-plug hook (reasserts Ultra limits — __HOME__ templated)
  99-performance-plus-ac.rules udev rule triggering the AC hook
  ryzenadj.tmpfiles.conf   Provisions /run/ryzenadj/ at boot
  sudoers.performance-plus.template  Passwordless sudo rule (__USER__ templated)
templates/
  rog-profile-notify.sh    Platform profile change notification (Fn+F5), syncs Ultra state
  system-sleep-touchpad-reset.sh  Sleep hook for Phase 4
  99-thunderbolt-no-d3.rules  Thunderbolt dock udev rules for Phase 10
  controller-gaming-trigger.py   Gamepad combo listener for Phase 11
  controller-gaming-trigger.service  Systemd user service for Phase 11
  hibernate-wake-fix.sh    Standalone hibernate wake fix script
  patch-heroic-gamescope.sh    Heroic Gamescope compatibility patch
  unreal-engine/
    nvim-wrapper.sh        Smart nvim wrapper for UE integration
    fake_dpi.c             HiDPI interceptor for UE on HiDPI displays
    *.png                  Application icons
    unreal-engine.xml      MIME type for .uproject files
scripts/
  gaming-mode-install.sh   Gaming Mode (Gamescope session handoff) installer for Phase 6
  fix-webcam.sh            Standalone webcam suspend/resume fix — see docs/z13flow/webcam.md
  install-unreal-engine.sh    Standalone UE5 binary installer
  setup-ue-neovim.sh          Neovim/LazyVim UE integration setup
docs/
  rog-keys.md              Keybindings and Performance Plus profile reference
  unreal-engine-neovim-integration.md  Full UE+nvim integration guide
  perforce-setup.md         Perforce setup guide
  z13flow/                  Docs carried over from Naomarik/Z13-StrixHalo-Omarchy
    performance-plus.md     Full Performance Plus design + tuning rationale
    bluetooth.md             MT7925 boot workaround
    webcam.md                 Webcam suspend/resume fix
    hy3.md                    hy3 tiling reference
    kernel-and-asus-stack.md  linux-g14 setup/rollback guide
    pacman-build-config.md    makepkg/pacman build performance tuning
    swayosd.md                 SwayOSD crash fix
    easyeffects-mic-setup.md  Mic preset validation
patches/
  fix-kbd-backlight-resume.sh
utils/
  fix-gtk-dark-mode.sh
```

## Disclaimer

This script modifies system packages, kernel, pacman repositories, systemd
services, sudoers, and configuration files. It is provided as-is with no
warranty. Review the source and use `--dry-run` before running it on your
system. The authors are not responsible for any damage or data loss that may
result from using this script.

## Credits

This repo is a merge of, and would not exist without:

- [Cliffback/omarchy-rog-z13-setup](https://github.com/Cliffback/omarchy-rog-z13-setup)
- [Naomarik/Z13-StrixHalo-Omarchy](https://github.com/Naomarik/Z13-StrixHalo-Omarchy)

Both are, in turn, built on
[ib99/ASUS-ROG-Flow-Z13-2025-Linux-Guide-Omarchy-CachyOS-Kernel](https://github.com/ib99/ASUS-ROG-Flow-Z13-2025-Linux-Guide-Omarchy-CachyOS-Kernel),
[Omarchy](https://github.com/basecamp/omarchy), and
[asus-linux.org](https://asus-linux.org).

## License

MIT
