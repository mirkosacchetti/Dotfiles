#!/bin/bash
# Hover for the eww bar: the info line under the bar opens when the pointer
# enters a module and closes when it leaves. Leaving is debounced: mapping
# the info window makes the compositor send the bar a leave and a fresh
# enter, and moving to the next module is a leave followed by an enter, so
# the window only closes when, a moment later, no module is hovered. The
# wait runs detached: eww kills a handler that takes too long.
#   enter NAME SCREEN
#   leave SCREEN
case $1 in
    enter)
        eww update "hovered=$2"
        eww active-windows | grep -q "^info-$3:" ||
            eww open info --id "info-$3" --screen "$3" --arg "screen=$3"
        ;;
    leave)
        eww update hovered=
        setsid -f "$0" close-later "$2"
        ;;
    close-later)
        sleep 0.15
        [[ -z $(eww get hovered) ]] && eww active-windows | grep -q "^info-$2:" && eww close "info-$2"
        ;;
    *) echo "usage: ${0##*/} enter NAME SCREEN | leave SCREEN" >&2; exit 1 ;;
esac
