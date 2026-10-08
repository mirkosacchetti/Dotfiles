#!/bin/bash
# Waybar display indicator (custom/display) and the screen the other modules
# act on. The icon turns red when an output runs below the best refresh
# rate it offers at its current resolution, e.g. the Dell stuck at 60 Hz
# after a hotplug (see output-watch.sh).
#   (none)  waybar JSON, long-running: the icon
#   info    the same, with the picked output as text: "DP-7 DELL U2725QE  ·
#           3840x2160@60Hz, scale 1.5", the same label brightness.sh uses
#   next    pick the next screen. The pick is a file, what brightness.sh acts
#           on too, so the middle click on either module moves both drawers.
# The long-running instances follow sway's output events, plus the tick
# event next sends through sway.
PICK=$XDG_RUNTIME_DIR/screen-pick

# active outputs as a JSON array of {name, line, low}, the focused one
# first, then rotated so the picked one (if still there) leads: the drawer
# shows it, next takes the one after. The label is the name plus the model,
# except for the panel, whose model is a bare code.
outputs() {
    swaymsg -t get_outputs | jq -c --arg pick "$(cat "$PICK" 2>/dev/null)" '
        [.[] | select(.active)] | sort_by(.focused | not)
        | map(.current_mode as $m
              | ([.modes[] | select(.width == $m.width and .height == $m.height).refresh] | max) as $best
              | (if .name | startswith("eDP") then .name else "\(.name) \(.model)" end) as $label
              | { name,
                  line: "\($label)  ·  \($m.width)x\($m.height)@\($m.refresh / 1000 | round)Hz, scale \(.scale)",
                  low: ($m.refresh < $best - 1000) })
        | (map(.name) | index($pick)) as $i
        | if $i == null then . else .[$i:] + .[:$i] end'
}

emit() {
    outputs | jq -c --arg icon $'󰍹' --arg mode "$1" '
        {
          text: (if $mode == "info"
                 then .[0] | .line + (if .low then " (below max)" else "" end)
                 else $icon end),
          class: (if any(.[]; .low) then "degraded" else "" end)
        }'
}

case $1 in
    next)
        # the one after the current; with a single screen, no pick at all
        # (read before writing: the redirection would empty the file first)
        pick=$(outputs | jq -r '.[1].name // empty')
        echo "$pick" > "$PICK"
        pkill -RTMIN+6 waybar
        swaymsg -t send_tick screen-pick > /dev/null
        exit
        ;;
    info|'') mode=$1 ;;
    *) echo "usage: ${0##*/} [info|next]" >&2; exit 1 ;;
esac

# exit once waybar is gone (write fails) instead of lingering after a reload
emit "$mode" || exit
swaymsg -rm -t subscribe '["output", "tick"]' | while read -r _; do emit "$mode" || exit; done
