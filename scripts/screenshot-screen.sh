#!/bin/bash
# Capture the focused output to ~/Pictures/screenshots and the clipboard.
# The short sleep lets the launcher (fuzzel) close before grim shoots.

sleep 0.3
OUTPUT=$(swaymsg -t get_outputs | jq -r '.[] | select(.focused).name')
[[ -z $OUTPUT ]] && exit 1

DIR="$HOME/Pictures/screenshots"
FILE="$DIR/screenshot-$(date +%Y%m%d-%H%M%S).png"
mkdir -p "$DIR"

grim -o "$OUTPUT" "$FILE" || exit 1
wl-copy < "$FILE"
notify-send -u low "Screenshot" "Screen saved to ~/Pictures/screenshots and copied to clipboard"
