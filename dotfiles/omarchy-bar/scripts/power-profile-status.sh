#!/bin/bash
#
# Power Profile Status Script for the Omarchy bar (type: "command" module)
# Returns JSON with current power profile icon and tooltip
#

STATE_FILE="/var/lib/performance-plus/active"
PENDING="${XDG_RUNTIME_DIR:-/tmp}/power-profile-toggle/pending-profile"
CACHE_FILE="${XDG_RUNTIME_DIR:-/tmp}/power-profile-toggle/cached-profile"
CACHE_TTL=15  # seconds; avoids hitting powerprofilesctl (python3.14/PyGObject,
              # prone to a rare upstream GDBus shutdown-race segfault) on every
              # 1s bar tick when only this script's own toggle ever changes it

power_profile_get() {
    powerprofilesctl get 2>/dev/null
}

cached_profile_get() {
    if [[ -s "$CACHE_FILE" ]] && (( $(date +%s) - $(stat -c %Y "$CACHE_FILE" 2>/dev/null || echo 0) < CACHE_TTL )); then
        cat "$CACHE_FILE"
    else
        local profile
        profile=$(power_profile_get || echo "balanced")
        mkdir -p "$(dirname "$CACHE_FILE")"
        printf '%s' "$profile" > "$CACHE_FILE"
        printf '%s' "$profile"
    fi
}

PROFILE=""
ULTRA=false

# A pending click-selected profile takes precedence (ignore if stale >30s,
# e.g. leftover from a killed worker)
if [[ -s "$PENDING" ]] && (( $(date +%s) - $(stat -c %Y "$PENDING" 2>/dev/null || echo 0) < 30 )); then
    PROFILE=$(<"$PENDING")
    [[ "$PROFILE" == "ultra" ]] && ULTRA=true
else
    PROFILE=$(cached_profile_get)
    [[ -f "$STATE_FILE" ]] && ULTRA=true
fi

if $ULTRA; then
    ICON="⚡ (U)"
    TOOLTIP="Power profile: Ultra (Performance Plus)\nRyzenAdj OC active - survives suspend"
else
    case "$PROFILE" in
        performance)
            ICON="󰓅 (P)"
            TOOLTIP="Power profile: performance"
            ;;
        balanced)
            ICON="󰾅 (B)"
            TOOLTIP="Power profile: balanced"
            ;;
        power-saver)
            ICON="󰾆 (Q)"
            TOOLTIP="Power profile: power-saver"
            ;;
        *)
            ICON=""
            TOOLTIP="Power profile: unknown"
            ;;
    esac
fi

# Return JSON for the Omarchy bar's type: "command" module
echo "{\"text\":\"$ICON\",\"tooltip\":\"$TOOLTIP\"}"
