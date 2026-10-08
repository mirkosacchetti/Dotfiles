#!/bin/bash
# Notification controls around dunst, for the waybar module and sway keys.
#
#   status   waybar JSON: bell (filled with history, crossed when paused,
#            outline when empty)
#   info     waybar JSON for the drawer next to the bell: the last entry and
#            how many more, or silenced
#   pick     notification center: the history in fuzzel, newest first; Enter shows the
#            chosen notification again (dunstctl history-pop ID)
#   pop      show the latest history entry again
#   clear    empty the history
#   toggle   pause/unpause notifications (do not disturb)
#
# dunst keeps `history_length` closed notifications (dunstrc) and exposes
# them with `dunstctl history` as JSON; the timestamp there is monotonic
# microseconds, hence the boot-time arithmetic below. Anything that changes
# the state signals waybar (RTMIN+2, see custom/notifications) so the bar
# updates right away instead of on its next poll.

SIGNAL='pkill -RTMIN+2 waybar'

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
    text=$icon
    if [ "$1" = info ]; then
        text=$(history | head -1 | awk -F'\t' '{ printf "%s  %s: %s", $2, $4, $5 }')
        [ "$count" -gt 1 ] && text="$text  ·  $((count - 1)) more"
        [ -z "$text" ] && text="No notifications"
        [ "$paused" = true ] && text="Silenced  ·  $text"
    fi
    jq -cn --arg text "$text" --arg class "$class" '{text: $text, class: $class}'
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
