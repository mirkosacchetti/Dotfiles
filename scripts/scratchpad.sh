#!/bin/bash
# Waybar scratchpad indicator. The builtin sway/scratchpad module only counts
# hidden windows (the ones in __i3_scratch); count shown ones too
# (scratchpad_state) and flag when one of them has focus.
# The count is drawn inside the icon: numeric-N-box-multiple-outline for
# 0-9, then the 9+ glyph. With `info` the text is the windows instead, one
# line, for the drawer module next to the icon (custom/scratchpad-info).
ICONS=$'󰎢󰎥󰎨󰎫󰎲󰎯󰎴󰎷󰎺󰎽󰏀'
emit() {
    swaymsg -t get_tree | jq -c --arg icons "$ICONS" --arg mode "$1" '
        [.. | objects | select(.scratchpad_state? and .scratchpad_state != "none")] as $w
        | {
            text: (if $mode == "info"
                   then ($w | map("\(.app_id // .window_properties.class // "?"): \(.name)") | join("  ·  "))
                   else ($icons | .[([$w | length, 10] | min):][:1]) end),
            class: (if any($w[]; .focused) then "focused" else "" end)
          }'
}
emit "$1"
# exit once waybar is gone (write fails) instead of lingering after a reload
swaymsg -rm -t subscribe '["window","workspace"]' | while read -r _; do emit "$1" || exit; done
