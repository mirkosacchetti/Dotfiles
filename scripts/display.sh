#!/bin/bash
# Waybar display indicator (custom/display) and the screen the other modules
# act on. The icon turns red when an output runs below the best refresh
# rate it offers at its current resolution, e.g. the Dell stuck at 60 Hz
# after a hotplug (see output-watch.sh).
#   (none)  waybar JSON, long-running: the icon
#   info    the same, with every active output (resolution, refresh rate,
#           scale) as text, the picked one first and in bold
#   next    pick the next screen. The pick is a file, what brightness.sh acts
#           on too, so the middle click on either module moves both drawers.
# The long-running instances follow sway's output events and re-emit on
# SIGUSR1, which next sends them.
PICK=$XDG_RUNTIME_DIR/screen-pick

# active outputs as a JSON array of {name, line, low}, the focused one
# first, then rotated so the picked one (if still there) leads
outputs() {
    swaymsg -t get_outputs | jq -c --arg pick "$(cat "$PICK" 2>/dev/null)" '
        [.[] | select(.active)] | sort_by(.focused | not)
        | map(.current_mode as $m
              | ([.modes[] | select(.width == $m.width and .height == $m.height).refresh] | max) as $best
              | { name,
                  line: "\(.name): \($m.width)x\($m.height)@\($m.refresh / 1000 | round)Hz, scale \(.scale)",
                  low: ($m.refresh < $best - 1000) })
        | (map(.name) | index($pick)) as $i
        | if $i == null then . else .[$i:] + .[:$i] end'
}

emit() {
    outputs | jq -c --arg icon $'󰍹' --arg mode "$1" '
        {
          text: (if $mode == "info"
                 then map(.line + (if .low then " (below max)" else "" end))
                      | .[0] |= "<b>" + . + "</b>" | join("  ·  ")
                 else $icon end),
          class: (if any(.[]; .low) then "degraded" else "" end)
        }'
}

case $1 in
    next)
        # the one after the current; with a single screen, no pick at all
        outputs | jq -r '.[1].name // empty' > "$PICK"
        pkill -RTMIN+6 waybar
        pkill -USR1 -f 'scripts/display\.sh( info)?$'
        exit
        ;;
    info|'') mode=$1 ;;
    *) echo "usage: ${0##*/} [info|next]" >&2; exit 1 ;;
esac

exec {events}< <(swaymsg -rm -t subscribe '["output"]')
trap 'kill $! 2>/dev/null' EXIT
trap 'emit "$mode" || exit' USR1
# exit once waybar is gone (write fails) instead of lingering after a reload
emit "$mode" || exit
while :; do
    if read -r -u "$events" _; then emit "$mode" || exit
    else (( $? > 128 )) || exit; fi   # EOF: sway is gone; a signal is fine
done
