#!/bin/bash
# Migration: clean up artifacts from a previous install of the pre-merge
# omarchy-rog-z13-setup (Cliffback) script. These reactively auto-switch
# power-profiles-daemon on AC events and/or write raw TDP values directly —
# both would conflict with Performance Plus (phase 5) if left in place.
# Always runs first, before Phase 0, and is a no-op if nothing legacy is found.

LEGACY_DEBOUNCE_SCRIPT="$HOME/.local/share/omarchy/bin/omarchy-powerprofiles-set-debounced"
LEGACY_DEBOUNCE_RULE="/etc/udev/rules.d/99-power-profile.rules"
LEGACY_DEBOUNCE_HOOK="$HOME/.config/omarchy/hooks/post-update.d/z13-power-profile-debounce-hook.sh"
LEGACY_ROG_QUICK="$HOME/.local/bin/rog-quick.sh"

migrate_check() {
    [[ ! -f "$LEGACY_DEBOUNCE_SCRIPT" ]] \
        && [[ ! -f "$LEGACY_DEBOUNCE_HOOK" ]] \
        && [[ ! -f "$LEGACY_ROG_QUICK" ]] \
        && { [[ ! -f "$LEGACY_DEBOUNCE_RULE" ]] || ! grep -q 'debounced' "$LEGACY_DEBOUNCE_RULE" 2>/dev/null; }
}

migrate_run() {
    warn "Found leftovers from a previous omarchy-rog-z13-setup install:"
    warn "a udev rule that auto-switches power-profiles-daemon on AC events,"
    warn "and/or a raw-sysfs TDP menu. Both conflict with Performance Plus"
    warn "(phase 5), which expects to be the only thing setting power limits."

    if [[ -f "$LEGACY_DEBOUNCE_RULE" ]] && grep -q 'debounced' "$LEGACY_DEBOUNCE_RULE" 2>/dev/null; then
        info "Removing legacy debounced power-profile udev rule..."
        run_sudo rm -f "$LEGACY_DEBOUNCE_RULE"
        run_sudo udevadm control --reload-rules
        success "Legacy udev rule removed (Omarchy's stock rule is restored)."
    fi

    if [[ -f "$LEGACY_DEBOUNCE_SCRIPT" ]]; then
        info "Removing legacy debounce script..."
        run_cmd rm -f "$LEGACY_DEBOUNCE_SCRIPT"
    fi

    if [[ -f "$LEGACY_DEBOUNCE_HOOK" ]]; then
        info "Removing legacy post-update hook..."
        run_cmd rm -f "$LEGACY_DEBOUNCE_HOOK"
    fi

    if [[ -f "$LEGACY_ROG_QUICK" ]]; then
        info "Removing legacy rog-quick.sh TDP menu..."
        run_cmd rm -f "$LEGACY_ROG_QUICK"
    fi

    success "Legacy artifacts cleaned up."
}
