#!/bin/bash
# Waybar display indicator: resolution, refresh rate and scale of every active
# output as tooltip. An output running below the best refresh rate it offers
# at its current resolution gets flagged, e.g. the Dell stuck at 60 Hz after
# a hotplug (see output-watch.sh).
emit() {
    swaymsg -t get_outputs | jq -c --arg icon $'󰍹' '
        [.[] | select(.active)
         | .current_mode as $m
         | ([.modes[] | select(.width == $m.width and .height == $m.height).refresh] | max) as $best
         | {
             line: "\(.name): \($m.width)x\($m.height)@\($m.refresh / 1000 | round)Hz, scale \(.scale)",
             low: ($m.refresh < $best - 1000)
           }] as $o
        | {
            text: $icon,
            tooltip: ($o | map(.line + (if .low then " (below max)" else "" end)) | join("\n")),
            class: (if any($o[]; .low) then "degraded" else "" end)
          }'
}
emit
# exit once waybar is gone (write fails) instead of lingering after a reload
swaymsg -rm -t subscribe '["output"]' | while read -r _; do emit || exit; done
