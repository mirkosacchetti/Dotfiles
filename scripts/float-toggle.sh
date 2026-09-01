#!/bin/bash
# Toggle floating on the focused window; sway keeps the creation-time border
# style across the toggle, so set it explicitly: titlebar only while floating.
# read the state before toggling: right after the toggle the tree can still
# report the old state while sway's transaction settles
type=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .type')
swaymsg floating toggle
if [ "$type" = "floating_con" ]; then
    swaymsg border none
else
    swaymsg border normal
fi
