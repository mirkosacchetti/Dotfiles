#!/bin/bash
# Copy the focused window to the clipboard (geometry from the sway tree, no slurp).

GEOM=$(swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | "\(.x),\(.y) \(.width)x\(.height)"')
[[ -z $GEOM ]] && exit 1

grim -g "$GEOM" - | wl-copy
notify-send -u low "Screenshot" "Window copied to clipboard"
