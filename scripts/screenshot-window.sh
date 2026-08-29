#!/bin/bash
# Cattura la finestra focusata in clipboard (geometria da sway, niente slurp).

GEOM=$(swaymsg -t get_tree | jq -j '.. | select(.type?) | select(.focused).rect | "\(.x),\(.y) \(.width)x\(.height)"')
[[ -z $GEOM ]] && exit 1

grim -g "$GEOM" - | wl-copy
notify-send -u low "Screenshot" "Finestra copiata in clipboard"
