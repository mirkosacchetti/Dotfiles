#!/bin/bash
# Waybar display indicator (custom/display): an icon, flagged red when an
# output runs below the best refresh rate it offers at its current
# resolution, e.g. the Dell stuck at 60 Hz after a hotplug (see
# output-watch.sh). With `info` it prints resolution, refresh rate and scale
# of every active output on one line instead, for the drawer module next to
# the icon (custom/display-info).
emit() {
    swaymsg -t get_outputs | jq -c --arg icon $'󰍹' --arg mode "$1" '
        [.[] | select(.active)
         | .current_mode as $m
         | ([.modes[] | select(.width == $m.width and .height == $m.height).refresh] | max) as $best
         | {
             line: "\(.name): \($m.width)x\($m.height)@\($m.refresh / 1000 | round)Hz, scale \(.scale)",
             low: ($m.refresh < $best - 1000)
           }] as $o
        | {
            text: (if $mode == "info"
                   then ($o | map(.line + (if .low then " (below max)" else "" end)) | join("  ·  "))
                   else $icon end),
            class: (if any($o[]; .low) then "degraded" else "" end)
          }'
}
emit "$1"
# exit once waybar is gone (write fails) instead of lingering after a reload
swaymsg -rm -t subscribe '["output"]' | while read -r _; do emit "$1" || exit; done
