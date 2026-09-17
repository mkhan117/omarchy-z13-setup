#!/bin/bash
# Watch asusd platform profile changes via dbus and show a notification.
# Triggered by Fn+F5 (Armory Crate key), which cycles the ACPI platform
# profile directly through asusd — independent of the Performance Plus
# Waybar toggle in dotfiles/waybar/scripts/power-profile-toggle.sh.
#
# Because Fn+F5 bypasses the toggle script, it can leave Ultra mode's state
# file (/var/lib/performance-plus/active) stale — e.g. Ultra is active, the
# user presses Fn+F5 to cycle to quiet, and Waybar would otherwise keep
# showing "Ultra". Clear the state file whenever Fn+F5 lands on anything
# other than "performance" so Waybar's next poll reflects reality.

NOTIFY_ID=0
LAST_PROFILE=""
ULTRA_STATE_FILE="/var/lib/performance-plus/active"

send_notify() {
    NOTIFY_ID=$(notify-send -u low -t 2000 -r "$NOTIFY_ID" -p "$1")
}

dbus-monitor --system "type='signal',sender='xyz.ljones.Asusd',member='PropertiesChanged',path='/xyz/ljones'" 2>/dev/null |
while read -r line; do
    if [[ "$line" == *"PlatformProfile"* ]]; then
        profile=$(cat /sys/firmware/acpi/platform_profile)
        # Only notify if profile actually changed
        if [[ "$profile" != "$LAST_PROFILE" ]]; then
            LAST_PROFILE="$profile"

            if [[ "$profile" != "performance" && -f "$ULTRA_STATE_FILE" ]]; then
                sudo -n rm -f "$ULTRA_STATE_FILE" 2>/dev/null
                pkill -RTMIN+13 waybar 2>/dev/null
            fi

            case "$profile" in
                quiet)       send_notify "󰌪    Quiet" ;;
                balanced)    send_notify "󰈈    Balanced" ;;
                performance) send_notify "󱐋    Performance" ;;
                *)           send_notify "    $profile" ;;
            esac
        fi
    fi
done
