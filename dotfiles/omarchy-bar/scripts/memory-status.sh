#!/bin/bash
#
# Memory status for the Omarchy bar (type: "command" module)
# Returns JSON with used/total RAM and swap in GiB

mem_total_kb=$(awk '/^MemTotal:/{print $2}' /proc/meminfo)
mem_avail_kb=$(awk '/^MemAvailable:/{print $2}' /proc/meminfo)
swap_total_kb=$(awk '/^SwapTotal:/{print $2}' /proc/meminfo)
swap_free_kb=$(awk '/^SwapFree:/{print $2}' /proc/meminfo)

mem_used_kb=$(( mem_total_kb - mem_avail_kb ))
swap_used_kb=$(( swap_total_kb - swap_free_kb ))

mem_used_gib=$(awk "BEGIN {printf \"%.1f\", $mem_used_kb / 1048576}")
mem_total_gib=$(awk "BEGIN {printf \"%.1f\", $mem_total_kb / 1048576}")
swap_used_gib=$(awk "BEGIN {printf \"%.1f\", $swap_used_kb / 1048576}")
swap_total_gib=$(awk "BEGIN {printf \"%.1f\", $swap_total_kb / 1048576}")

mem_pct=0
(( mem_total_kb > 0 )) && mem_pct=$(( 100 * mem_used_kb / mem_total_kb ))
swap_pct=0
(( swap_total_kb > 0 )) && swap_pct=$(( 100 * swap_used_kb / swap_total_kb ))

text=$(awk "BEGIN {printf \"%.0f/%.0f\", $mem_used_kb / 1048576, $swap_used_kb / 1048576}")

echo "{\"text\":\"󰘚 ${text}\",\"tooltip\":\"RAM: ${mem_used_gib}GiB / ${mem_total_gib}GiB (${mem_pct}%)\\nSwap: ${swap_used_gib}GiB / ${swap_total_gib}GiB (${swap_pct}%)\"}"
