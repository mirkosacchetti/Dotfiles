#!/bin/bash
# Night light: gammastep's user service, switched from waybar
# (custom/nightlight, signal 4). gammastep follows the sun at the location in
# ~/.config/gammastep/config.ini, so while on it only tints the screen at night.
#
#   status   waybar JSON: filled lamp when running, outline when not
#   info     waybar JSON for the drawer next to it: on with period and colour
#            temperature, or off
#   toggle   start/stop the service

UNIT=gammastep.service

case $1 in
status|info)
    if systemctl --user -q is-active $UNIT; then
        icon=$'󰚵'; class=on
        # "Notice: Period: Night", "Notice: Colour temperature: 4500K"
        info="on, "$(gammastep -p 2>&1 |
            awk -F': ' '/Period|temperature/ { printf "%s%s", sep, $NF; sep = ", " }')
    else
        icon=$'󱟐'; class=off
        info=off
    fi
    [[ $1 == info ]] && icon=$info
    jq -cn --arg text "$icon" --arg class "$class" '{text: $text, class: $class}'
    ;;
toggle)
    if systemctl --user -q is-active $UNIT; then
        systemctl --user stop $UNIT
    else
        systemctl --user start $UNIT
    fi
    pkill -RTMIN+4 waybar
    ;;
*) echo "usage: ${0##*/} status|info|toggle" >&2; exit 1 ;;
esac
