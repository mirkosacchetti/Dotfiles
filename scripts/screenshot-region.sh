#!/bin/bash
# Copy a slurp-selected region to the clipboard.

SELECTION=$(slurp 2>/dev/null)
[[ -z $SELECTION ]] && exit 0

grim -g "$SELECTION" - | wl-copy || exit 1
notify-send -u low "Screenshot" "Region copied to clipboard"
