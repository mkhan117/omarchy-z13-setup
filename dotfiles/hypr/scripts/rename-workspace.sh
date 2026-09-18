#!/bin/bash
id=$(hyprctl activeworkspace -j | jq '.id')
name=$(omarchy-menu-input "Rename (empty for default)…" --width 350)
if [[ -n "$name" ]]; then
  esc_name=${name//\'/\\\'}
  hyprctl dispatch "hl.dsp.workspace.rename({workspace = $id, name = '$id:$esc_name'})"
else
  hyprctl dispatch "hl.dsp.workspace.rename({workspace = $id, name = '$id'})"
fi
