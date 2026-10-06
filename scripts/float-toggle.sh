#!/bin/bash
# Toggle floating on the focused window; sway keeps the creation-time border
# style across the toggle, so set it explicitly: titlebar only while floating.
# A window going floating gets 88% of the workspace, centered, like the
# scratchpad ones: sway would give it the size it had when it was opened,
# which can be the whole output, plus the titlebar on top.
# Each direction is a single sway command, so the client gets one resize:
# floating first and resizing in a second command sends two, and sway takes a
# late answer to the first as the client's own choice of size.
type=$(swaymsg -t get_tree | jq -r '.. | select(.focused? == true) | .type')
if [ "$type" = "floating_con" ]; then
    swaymsg 'floating disable, border none'
else
    swaymsg 'floating enable, border normal, resize set 88 ppt 88 ppt, move position center'
fi
