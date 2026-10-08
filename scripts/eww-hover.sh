#!/bin/bash
# Hover for the eww bar: the popup under the bar opens when the pointer
# enters a module and closes when it leaves. Leaving is debounced: mapping
# the popup window makes the compositor send the bar a leave and a fresh
# enter, and moving to the next module is a leave followed by an enter, and
# their handlers run concurrently. So an enter stamps hoverseq, a leave only
# notes the stamp and, a moment later and detached (eww kills a slow
# handler), closes if no enter has happened since.
#   enter NAME SCREEN
#   leave SCREEN
case $1 in
    enter)
        eww update "hovered=$2" "hoverseq=$(date +%s%N)"
        eww active-windows | grep -q "^info-$3:" ||
            eww open info --id "info-$3" --screen "$3" --arg "screen=$3"
        ;;
    leave)
        setsid -f "$0" close-later "$2" "$(eww get hoverseq)"
        ;;
    close-later)
        sleep 0.15
        [[ $(eww get hoverseq) == "$3" ]] || exit 0
        eww update hovered=
        eww active-windows | grep -q "^info-$2:" && eww close "info-$2"
        ;;
    *) echo "usage: ${0##*/} enter NAME SCREEN | leave SCREEN" >&2; exit 1 ;;
esac
