#!/bin/bash
# Pick an open window with fuzzel and focus it, switching to its workspace.

WINDOWS=$(swaymsg -t get_tree | jq -r '
    .nodes[].nodes[]
    | (if .name == "__i3_scratch" then "scratch" else .name end) as $ws
    | recurse(.nodes[], .floating_nodes[])
    | select(.pid != null)
    | "\(.id)\t[\($ws)] \(.app_id // .window_properties.class // "?") — \(.name)"')
[[ -z $WINDOWS ]] && exit 0

IDX=$(cut -f2 <<< "$WINDOWS" | fuzzel --dmenu --index --lines 15 --width 60) || exit 0
[[ $IDX =~ ^[0-9]+$ ]] || exit 0
ID=$(sed -n "$((IDX + 1))p" <<< "$WINDOWS" | cut -f1)
swaymsg "[con_id=$ID] focus" > /dev/null
