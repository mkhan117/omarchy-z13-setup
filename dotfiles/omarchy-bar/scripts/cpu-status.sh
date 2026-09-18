#!/bin/bash
#
# CPU status for the Omarchy bar (type: "command" module)
# Returns JSON with 1-min load average, instantaneous usage %, and avg frequency

load=$(awk '{print $1}' /proc/loadavg)

read -r _ u1 n1 s1 i1 w1 q1 sq1 _ < <(grep '^cpu ' /proc/stat)
sleep 0.2
read -r _ u2 n2 s2 i2 w2 q2 sq2 _ < <(grep '^cpu ' /proc/stat)

idle1=$((i1 + w1)); idle2=$((i2 + w2))
total1=$((u1 + n1 + s1 + i1 + w1 + q1 + sq1)); total2=$((u2 + n2 + s2 + i2 + w2 + q2 + sq2))
totald=$((total2 - total1)); idled=$((idle2 - idle1))
usage=0
(( totald > 0 )) && usage=$(( (100 * (totald - idled)) / totald ))

freq_sum=0
freq_count=0
for f in /sys/devices/system/cpu/cpu[0-9]*/cpufreq/scaling_cur_freq; do
    [[ -r "$f" ]] || continue
    freq_sum=$(( freq_sum + $(<"$f") ))
    freq_count=$(( freq_count + 1 ))
done
avg_freq="0.00"
(( freq_count > 0 )) && avg_freq=$(awk "BEGIN {printf \"%.2f\", $freq_sum / $freq_count / 1000000}")

echo "{\"text\":\"󰍛 ${load}\",\"tooltip\":\"1min load: ${load}\\nUsage: ${usage}%\\nFrequency: ${avg_freq}GHz\"}"
