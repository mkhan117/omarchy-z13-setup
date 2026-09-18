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
BAR_SCRIPTS_DIR="$HOME/.config/omarchy/bar/scripts"
SHELL_JSON="$HOME/.config/omarchy/shell.json"

phase4_check() {
    file_contains "$HYPR_DIR/bindings.lua" "wvkbd-deskintl" \
        && [[ -x "$NOTIFY_SCRIPT" ]] \
        && [[ -x "$SYSTEM_SLEEP_HOOK" ]] \
        && [[ -x "$BAR_SCRIPTS_DIR/cpu-status.sh" ]] \
        && [[ -f "$SHELL_JSON" ]] \
        && jq -e '.bar.layout.left[]? | select(.id == "cpu")' "$SHELL_JSON" >/dev/null 2>&1
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

    # System-stats bar widgets (cpu/memory/power-draw/temperature/screen
    # refresh-rate toggle, and a status indicator for this repo's own
    # Super+D dictate.sh — distinct from Omarchy's built-in voxtype
    # dictation, which the default omarchy.indicators widget already
    # tracks). `type: "command"` modules registered into shell.json; no
    # Waybar, no QML needed. Omarchy's own defaults already cover
    # network/audio/bluetooth/battery/clock/tray/workspaces/updates and the
    # dictation/screen-recording/idle-lock/do-not-disturb indicators, so
    # those aren't re-added here.
    info "Installing system-stats bar widgets..."
    if [[ $DRY_RUN -eq 1 ]]; then
        info "[DRY-RUN] would install scripts to $BAR_SCRIPTS_DIR and register"
        info "[DRY-RUN] cpu/memory/power-draw/temperature/screen/dictation widgets in $SHELL_JSON"
    else
        mkdir -p "$BAR_SCRIPTS_DIR"
        for script in cpu-status memory-status power-draw temperatures screen-status toggle-refresh-rate dictation-status; do
            cp "$SCRIPT_DIR/dotfiles/omarchy-bar/scripts/$script.sh" "$BAR_SCRIPTS_DIR/"
        done
        chmod +x "$BAR_SCRIPTS_DIR/"*.sh

        mkdir -p "$(dirname "$SHELL_JSON")"
        [[ -f "$SHELL_JSON" ]] || echo '{"version":1}' > "$SHELL_JSON"

        local managed_ids='["memory","cpu","power-draw","temperature","screen","dictation"]'
        local new_widgets
        new_widgets=$(jq -n --arg dir "$BAR_SCRIPTS_DIR" '
            [
                {id: "memory", type: "command", exec: ($dir + "/memory-status.sh"), interval: 5, onClick: "xdg-terminal-exec btop"},
                {id: "cpu", type: "command", exec: ($dir + "/cpu-status.sh"), interval: 5, onClick: "xdg-terminal-exec btop"},
                {id: "power-draw", type: "command", exec: ($dir + "/power-draw.sh"), interval: 10, onClick: "xdg-terminal-exec btop"},
                {id: "temperature", type: "command", exec: ($dir + "/temperatures.sh"), interval: 10, onClick: "xdg-terminal-exec btop"},
                {id: "screen", type: "command", exec: ($dir + "/screen-status.sh"), interval: 5, onClick: ($dir + "/toggle-refresh-rate.sh")},
                {id: "dictation", type: "command", exec: ($dir + "/dictation-status.sh"), interval: 2, onClick: "~/.config/hypr/scripts/dictate.sh"}
            ]')

        # Placed in the LEFT section, not right: the bar's center content
        # (clock etc.) is anchored to the true horizontal center of the
        # whole bar and doesn't shrink to make room, so adding this many
        # widgets to the right section overlaps the clock. Left has plenty
        # of free space (just the menu + workspaces by default).
        local tmpfile
        tmpfile=$(mktemp)
        jq --argjson new "$new_widgets" --argjson ids "$managed_ids" '
            .bar //= {} | .bar.layout //= {} | .bar.layout.left //= [] | .bar.layout.right //= [] |
            .bar.layout.left = ([.bar.layout.left[] | select(.id as $i | ($ids | index($i)) | not)] + $new) |
            .bar.layout.right = [.bar.layout.right[] | select(.id as $i | ($ids | index($i)) | not)]
        ' "$SHELL_JSON" > "$tmpfile" && mv "$tmpfile" "$SHELL_JSON"
    fi
    success "System-stats bar widgets installed."

    if [[ $DRY_RUN -ne 1 ]]; then
        info "Run 'hyprctl reload' to pick up the new Lua config, and"
        info "'omarchy restart shell' to pick up the new bar widgets."
    fi
}
