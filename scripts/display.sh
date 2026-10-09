#!/bin/bash
# The screen the other modules act on: the bar's display and brightness
# modules (lintel) show the picked output, brightness.sh sets its level.
#   next    pick the next screen. The pick is a file, what brightness.sh acts
#           on too, so the middle click on either module moves both cards.
# lintel reads the outputs itself; the tick sent through sway tells it the
# pick changed.
PICK=$XDG_RUNTIME_DIR/screen-pick

case $1 in
    next) ;;
    *) echo "usage: ${0##*/} next" >&2; exit 1 ;;
esac

# the active outputs, the focused one first, then rotated so the picked one
# (if still there) leads, as the bar orders them; the next is the one after
# it, and with a single screen there is no pick at all (read before writing:
# the redirection would empty the file first)
pick=$(swaymsg -t get_outputs | jq -r --arg pick "$(cat "$PICK" 2>/dev/null)" '
    [.[] | select(.active)] | sort_by(.focused | not) | map(.name)
    | index($pick) as $i
    | (if $i == null then . else .[$i:] + .[:$i] end)
    | .[1] // empty')
echo "$pick" > "$PICK"
lintel refresh brightness
swaymsg -t send_tick screen-pick > /dev/null
