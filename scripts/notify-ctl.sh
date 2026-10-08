#!/bin/bash
# Notification controls around dunst, for the eww bar and sway keys.
#
#   status   JSON: bell (filled with history, crossed when paused,
#            outline when empty)
#   info     JSON with the info text: the last entry and how many more, or
#            silenced (status carries it too, as info)
#   pick     notification center: the history in fuzzel, newest first; Enter shows the
#            chosen notification again (dunstctl history-pop ID)
#   pop      show the latest history entry again
#   clear    empty the history
#   toggle   pause/unpause notifications (do not disturb)
#
# dunst keeps `history_length` closed notifications (dunstrc) and exposes
# them with `dunstctl history` as JSON; the timestamp there is monotonic
# microseconds, hence the boot-time arithmetic below. Anything that changes
# the state refreshes the bar's variable so it updates right away instead
# of on its next poll.

SIGNAL='eww poll notifications'

# Flat history: "id<TAB>HH:MM<TAB>icon<TAB>summary<TAB>body", newest first,
# one line each, pango markup stripped. dunst stamps entries with a clock
# that keeps counting through suspend, so boot time from /proc/uptime gives
# the right wall-clock conversion (checked against the journal).
history() {
    local offset
    offset=$(awk -v now="$(date +%s)" '{ printf "%d", now - $1 }' /proc/uptime)
    dunstctl history | jq -r --argjson offset "$offset" '
        .data[0][]
        | [ .id.data,
            ($offset + (.timestamp.data / 1000000 | floor) | strflocaltime("%H:%M")),
            (.icon_path.data | if . == "" then "dialog-information" else . end),
            (.summary.data | gsub("<[^>]*>"; "") | gsub("\\s+"; " ")),
            (.body.data    | gsub("<[^>]*>"; "") | gsub("\\s+"; " ")) ]
        | @tsv'
}

case $1 in
status|info)
    count=$(dunstctl count history)
    paused=$(dunstctl is-paused)
    if [ "$paused" = true ]; then
        icon='󰂛'; class=paused
    elif [ "$count" -gt 0 ]; then
        icon='󰂚'; class=history
    else
        icon='󰂜'; class=empty
    fi
    info=$(history | head -1 | awk -F'\t' '{ printf "%s  %s: %s", $2, $4, $5 }')
    [ "$count" -gt 1 ] && info="$info"$'\n'"$((count - 1)) more"
    [ -z "$info" ] && info="No notifications"
    [ "$paused" = true ] && info="Silenced"$'\n'"$info"
    text=$icon; [ "$1" = info ] && text=$info
    jq -cn --arg text "$text" --arg info "$info" --arg class "$class" '{text: $text, info: $info, class: $class}'
    ;;
pick)
    mapfile -t LINES < <(history)
    [ ${#LINES[@]} -eq 0 ] && exit 0
    IDX=$(printf '%s\n' "${LINES[@]}" |
        awk -F'\t' '{ printf "%s  %s — %s\0icon\x1f%s\n", $2, $4, $5, $3 }' |
        fuzzel --dmenu --index) || exit 0
    [[ $IDX =~ ^[0-9]+$ ]] || exit 0
    dunstctl history-pop "${LINES[IDX]%%$'\t'*}"
    $SIGNAL
    ;;
pop)    dunstctl history-pop; $SIGNAL ;;
clear)  dunstctl history-clear; $SIGNAL ;;
toggle) dunstctl set-paused toggle; $SIGNAL ;;
*)      echo "usage: ${0##*/} status|info|pick|pop|clear|toggle" >&2; exit 2 ;;
esac
