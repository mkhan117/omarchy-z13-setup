#!/bin/bash
# Phase 2: asusd N-KEY Backlight Fix
#
# asusd no longer needs a systemd [Install] drop-in: asusctl 6.5 ships
# 99-asusd.rules, which starts asusd.service via udev (SYSTEMD_WANTS) on ROG
# machines.

AURA_NKEY="/etc/asusd/aura_18c6.ron"

phase2_check() {
    grep -q 'brightness: High' "$AURA_NKEY" 2>/dev/null
}

phase2_run() {
    if [[ ! -f "$AURA_NKEY" ]]; then
        warn "$AURA_NKEY not found — has asusd run yet? Skipping."
        return
    fi

    # Fix N-KEY device (18c6) overriding keyboard brightness to Off on boot.
    # The Z13 has two aura USB devices (keyboard 1a30 + N-KEY 18c6) that both
    # bind to the same asus::kbd_backlight sysfs node. asusd restores brightness
    # per-device on boot, and the N-KEY defaults to Off, killing the backlight.
    info "Fixing N-KEY device brightness (aura_18c6.ron → High)..."
    run_sudo sed -i 's/brightness: \(Off\|Low\|Med\)/brightness: High/' "$AURA_NKEY"
    success "N-KEY brightness set to High — backlight will persist across reboots."
}
