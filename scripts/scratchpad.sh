#!/bin/bash
# Waybar scratchpad indicator. The builtin sway/scratchpad module only counts
# hidden windows (the ones in __i3_scratch); count shown ones too
# (scratchpad_state) and flag when one of them has focus.
# The count is drawn inside the icon: numeric-N-box-multiple-outline for
# 0-9, then the 9+ glyph.
ICONS=$'󰎢󰎥󰎨󰎫󰎲󰎯󰎴󰎷󰎺󰎽󰏀'
emit() {
    swaymsg -t get_tree | jq -c --arg icons "$ICONS" '
        [.. | objects | select(.scratchpad_state? and .scratchpad_state != "none")] as $w
        | {
            text: ($icons | .[([$w | length, 10] | min):][:1]),
            tooltip: ($w | map("\(.app_id // .window_properties.class // "?"): \(.name)") | join("\n")),
            class: (if any($w[]; .focused) then "focused" else "" end)
          }'
}
emit
# exit once waybar is gone (write fails) instead of lingering after a reload
swaymsg -rm -t subscribe '["window","workspace"]' | while read -r _; do emit || exit; done
