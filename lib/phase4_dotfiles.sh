#!/bin/bash
# Phase 4: Desktop Dotfiles (Hyprland, EasyEffects)
#
# Deploys dotfiles/{hypr,easyeffects} — Z13-tuned Hyprland config (dwindle
# tiling, tablet/stylus mapping, brightness/kbd-backlight scripts) as Lua
# modules under Omarchy's `require("hypr.*")` config system, and EasyEffects
# speaker/headphone/mic presets. The Performance Plus power-profile bar
# widget is deployed by phase 5, not here.
#
# This REPLACES ~/.config/hypr/* wholesale, backing up any existing config
# first (this also protects Omarchy's own ~/.config/hypr/hyprland.lua and
# friends, which this repo never overwrites — only bindings.lua/input.lua/
# looknfeel.lua/monitors.lua/autostart.lua, the files Omarchy's hyprland.lua
# `require()`s). If you've hand-edited your Hyprland config, check the
# backup after running this.
#
# NOTE: this repo targets Omarchy 4.0.4+, which replaced both raw
# hyprland.conf sourcing (now Lua modules) and Waybar (now its own
# Quickshell-based bar). There is no hy3 support here either — hy3 isn't
# installed on 4.0.4 (hyprpm is gone), so tiling binds target dwindle.

HYPR_DIR="$HOME/.config/hypr"
EASYEFFECTS_DIR="$HOME/.local/share/easyeffects"
NOTIFY_SCRIPT="$HOME/.local/bin/rog-profile-notify.sh"
SYSTEM_SLEEP_HOOK="/usr/lib/systemd/system-sleep/99-asus-z13-touchpad-reset"

phase4_check() {
    file_contains "$HYPR_DIR/bindings.lua" "wvkbd-deskintl" \
        && [[ -x "$NOTIFY_SCRIPT" ]] \
        && [[ -x "$SYSTEM_SLEEP_HOOK" ]]
}

phase4_run() {
    local backup_dir="$HOME/.config/z13-setup-backup.$(date +%s)"

    info "Deploying Hyprland + EasyEffects dotfiles..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would back up existing ~/.config/hypr to $backup_dir"
        info "[DRY-RUN] would copy dotfiles/hypr -> $HYPR_DIR, dotfiles/easyeffects -> $EASYEFFECTS_DIR"
    else
        mkdir -p "$backup_dir"
        [[ -d "$HYPR_DIR" ]] && cp -r "$HYPR_DIR" "$backup_dir/hypr"

        mkdir -p "$HYPR_DIR" "$EASYEFFECTS_DIR"/{input,output,irs}
        cp -r "$SCRIPT_DIR/dotfiles/hypr/." "$HYPR_DIR/"
        cp "$SCRIPT_DIR/dotfiles/easyeffects/output/"*.json "$EASYEFFECTS_DIR/output/"
        cp "$SCRIPT_DIR/dotfiles/easyeffects/input/"*.json "$EASYEFFECTS_DIR/input/"
        cp "$SCRIPT_DIR/dotfiles/easyeffects/irs/"*.irs "$EASYEFFECTS_DIR/irs/"
        chmod +x "$HYPR_DIR/scripts/"*.sh 2>/dev/null || true

        info "Previous config backed up to $backup_dir"
    fi
    success "Dotfiles deployed."

    info "Installing platform-profile notification script..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would install rog-profile-notify.sh to $NOTIFY_SCRIPT"
    else
        mkdir -p "$HOME/.local/bin"
        cp "$SCRIPT_DIR/templates/rog-profile-notify.sh" "$NOTIFY_SCRIPT"
        chmod +x "$NOTIFY_SCRIPT"
    fi
    success "Notification script installed."

    # Install systemd sleep hook to reset USB keyboard dock after resume.
    # The AMD xHCI controller intermittently crashes during resume, causing
    # the ELAN touchpad firmware to re-enumerate with corrupted multi-touch
    # state (gestures require +1 finger). This forces a clean reinitialization.
    info "Installing systemd sleep hook for touchpad resume fix..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would install $SYSTEM_SLEEP_HOOK"
    else
        run_sudo cp "$SCRIPT_DIR/templates/system-sleep-touchpad-reset.sh" "$SYSTEM_SLEEP_HOOK"
        run_sudo chmod +x "$SYSTEM_SLEEP_HOOK"
    fi
    success "Sleep hook installed."

    if [[ $DRY_RUN -ne 1 ]]; then
        info "Run 'hyprctl reload' to pick up the new Lua config (or log out/in)."
    fi
}
