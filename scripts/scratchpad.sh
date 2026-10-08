#!/bin/bash
# Scratchpad indicator for the eww bar. The builtin sway/scratchpad module only counts
# hidden windows (the ones in __i3_scratch); count shown ones too
# (scratchpad_state) and flag when one of them has focus.
# The count is drawn inside the icon: numeric-N-box-multiple-outline for
# 0-9, then the 9+ glyph; the windows, one line, as info (and as the text
# with `info`).
ICONS=$'󰎢󰎥󰎨󰎫󰎲󰎯󰎴󰎷󰎺󰎽󰏀'
emit() {
    swaymsg -t get_tree | jq -c --arg icons "$ICONS" --arg mode "$1" '
        [.. | objects | select(.scratchpad_state? and .scratchpad_state != "none")] as $w
        | ($w | map("\(.app_id // .window_properties.class // "?"): \(.name)") | join(", ")) as $info
        | {
            text: (if $mode == "info" then $info else ($icons | .[([$w | length, 10] | min):][:1]) end),
            info: $info,
            class: (if any($w[]; .focused) then "focused" else "" end)
          }'
}
emit "$1"
# exit once the bar is gone (write fails) instead of lingering
swaymsg -rm -t subscribe '["window","workspace"]' | while read -r _; do emit "$1" || exit; done
