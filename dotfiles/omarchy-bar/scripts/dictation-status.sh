#!/bin/bash
#
# Dictation status for the Omarchy bar (type: "command" module)
# Tracks this repo's own whisper.cpp-based dictate.sh (Super+D) — NOT
# Omarchy's built-in voxtype dictation feature, which is a separate system
# omarchy.indicators' native "Dictation" entry tracks instead.

PID_FILE="/tmp/dictate.pid"

if [[ -f "$PID_FILE" ]] && kill -0 "$(<"$PID_FILE")" 2>/dev/null; then
    echo "{\"text\":\"<span color='#ff4444'>󰍬</span>\",\"tooltip\":\"Dictating... (Super+D to stop)\"}"
else
    echo "{\"text\":\"󰍬\",\"tooltip\":\"Dictate (Super+D)\"}"
fi
