#!/bin/bash
#
# macOS-style system-wide zoom control.
# Usage: zoom.sh in <step> <max>   — zoom in by <step>, capped at <max>
#        zoom.sh out <step> <min>  — zoom out by <step>, floored at <min>
#        zoom.sh reset             — back to 1.0
#
# hyprctl keyword doesn't work on this Hyprland version's Lua-native config
# parser ("keyword can't work with non-legacy parsers") — hyprctl eval with
# an hl.config() call is the replacement.

set -euo pipefail

hyprctl eval 'hl.config({cursor={zoom_rigid=true}})' >/dev/null

case "$1" in
    in)
        step="$2" max="$3"
        current=$(hyprctl getoption cursor:zoom_factor -j | jq -r '.float')
        new=$(awk "BEGIN {v=$current+$step; print (v < $max ? v : $max)}")
        ;;
    out)
        step="$2" min="$3"
        current=$(hyprctl getoption cursor:zoom_factor -j | jq -r '.float')
        new=$(awk "BEGIN {v=$current-$step; print (v > $min ? v : $min)}")
        ;;
    reset)
        new=1.0
        ;;
    *)
        echo "Usage: zoom.sh in|out <step> <max|min>, or zoom.sh reset" >&2
        exit 1
        ;;
esac

hyprctl eval "hl.config({cursor={zoom_factor=$new}})" >/dev/null
