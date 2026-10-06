#!/bin/bash
# Night light: gammastep's user service, switched from waybar
# (custom/nightlight, signal 4). gammastep follows the sun at the location in
# ~/.config/gammastep/config.ini, so while on it only tints the screen at night.
#
#   status   waybar JSON: filled lamp when running, outline when not; period
#            and colour temperature as tooltip
#   toggle   start/stop the service

UNIT=gammastep.service

case $1 in
status)
    if systemctl --user -q is-active $UNIT; then
        icon=$'󰚵'; class=on
        # "Notice: Period: Night", "Notice: Colour temperature: 4500K"
        tooltip="Night light: on"$'\n'$(gammastep -p 2>&1 |
            awk -F': ' '/Period|temperature/ { printf "%s%s", sep, $NF; sep = ", " }')
    else
        icon=$'󱟐'; class=off
        tooltip="Night light: off"
    fi
    jq -cn --arg text "$icon" --arg class "$class" --arg tooltip "$tooltip" \
        '{text: $text, class: $class, tooltip: $tooltip}'
    ;;
toggle)
    if systemctl --user -q is-active $UNIT; then
        systemctl --user stop $UNIT
    else
        systemctl --user start $UNIT
    fi
    pkill -RTMIN+4 waybar
    ;;
*) echo "usage: ${0##*/} status|toggle" >&2; exit 1 ;;
esac
