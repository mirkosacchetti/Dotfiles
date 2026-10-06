#!/bin/bash
# Power menu in fuzzel, for the waybar power button and the launcher entry.

ICONS=/home/m/Dotfiles/applications/icons

# "label<TAB>icon<TAB>command"; the first row is the preselected one
ACTIONS=(
    $'Shutdown\tpower\tsystemctl poweroff'
    $'Reboot\tpower-reboot\tsystemctl reboot'
    $'Suspend\tpower-suspend\tsystemctl suspend'
    $'Lock\tpower-lock\tswaylock'
    $'Logout\tpower-logout\tswaymsg exit'
)

IDX=$(for a in "${ACTIONS[@]}"; do
    IFS=$'\t' read -r label icon _ <<< "$a"
    printf '%s\0icon\x1f%s/%s.png\n' "$label" "$ICONS" "$icon"
done | fuzzel --dmenu --index --lines ${#ACTIONS[@]}) || exit 0
[[ $IDX =~ ^[0-9]+$ ]] || exit 0
exec ${ACTIONS[IDX]##*$'\t'}
