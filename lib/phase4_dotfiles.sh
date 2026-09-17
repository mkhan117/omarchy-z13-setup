#!/bin/bash
# Phase 4: Desktop Dotfiles (Hyprland, Waybar, EasyEffects)
#
# Deploys dotfiles/{hypr,waybar,easyeffects} — Z13-tuned Hyprland config
# (hy3 tiling, tablet/stylus mapping, brightness/kbd-backlight scripts),
# Waybar modules (including the Performance Plus power-profile/power-draw
# modules wired up in phase5), and EasyEffects speaker/headphone/mic presets.
#
# This REPLACES ~/.config/hypr/* and ~/.config/waybar/* wholesale (matching
# upstream z13flow's own install method), backing up any existing config
# first. If you've hand-edited your Hyprland/Waybar config, check the backup
# after running this.

HYPR_DIR="$HOME/.config/hypr"
WAYBAR_DIR="$HOME/.config/waybar"
EASYEFFECTS_DIR="$HOME/.local/share/easyeffects"
NOTIFY_SCRIPT="$HOME/.local/bin/rog-profile-notify.sh"
SYSTEM_SLEEP_HOOK="/usr/lib/systemd/system-sleep/99-asus-z13-touchpad-reset"

phase4_check() {
    file_contains "$HYPR_DIR/bindings.conf" "wvkbd-deskintl" \
        && [[ -f "$WAYBAR_DIR/scripts/power-profile-toggle.sh" ]] \
        && [[ -x "$NOTIFY_SCRIPT" ]] \
        && [[ -x "$SYSTEM_SLEEP_HOOK" ]]
}

phase4_run() {
    local backup_dir="$HOME/.config/z13-setup-backup.$(date +%s)"

    info "Deploying Hyprland + Waybar + EasyEffects dotfiles..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would back up existing ~/.config/hypr and ~/.config/waybar to $backup_dir"
        info "[DRY-RUN] would copy dotfiles/hypr -> $HYPR_DIR, dotfiles/waybar -> $WAYBAR_DIR, dotfiles/easyeffects -> $EASYEFFECTS_DIR"
    else
        mkdir -p "$backup_dir"
        [[ -d "$HYPR_DIR" ]] && cp -r "$HYPR_DIR" "$backup_dir/hypr"
        [[ -d "$WAYBAR_DIR" ]] && cp -r "$WAYBAR_DIR" "$backup_dir/waybar"

        mkdir -p "$HYPR_DIR" "$WAYBAR_DIR" "$EASYEFFECTS_DIR"/{input,output,irs}
        cp -r "$SCRIPT_DIR/dotfiles/hypr/." "$HYPR_DIR/"
        cp -r "$SCRIPT_DIR/dotfiles/waybar/." "$WAYBAR_DIR/"
        cp "$SCRIPT_DIR/dotfiles/easyeffects/output/"*.json "$EASYEFFECTS_DIR/output/"
        cp "$SCRIPT_DIR/dotfiles/easyeffects/input/"*.json "$EASYEFFECTS_DIR/input/"
        cp "$SCRIPT_DIR/dotfiles/easyeffects/irs/"*.irs "$EASYEFFECTS_DIR/irs/"
        chmod +x "$HYPR_DIR/scripts/"*.sh "$WAYBAR_DIR/scripts/"* 2>/dev/null || true

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
        info "Restart Hyprland (or log out/in) and Waybar to pick up the new config:"
        info "  pkill waybar; hyprctl dispatch exec waybar"
    fi
}
