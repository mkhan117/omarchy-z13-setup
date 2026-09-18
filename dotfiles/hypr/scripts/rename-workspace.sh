#!/bin/bash
id=$(hyprctl activeworkspace -j | jq '.id')
name=$(omarchy-launch-walker --dmenu --inputonly --width 350 -p "Rename (empty for default)…")
if [[ -n "$name" ]]; then
  esc_name=${name//\'/\\\'}
  hyprctl dispatch "hl.dsp.workspace.rename({workspace = $id, name = '$id:$esc_name'})"
else
  hyprctl dispatch "hl.dsp.workspace.rename({workspace = $id, name = '$id'})"
fi
