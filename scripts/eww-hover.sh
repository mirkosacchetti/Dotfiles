#!/bin/bash
# Hover for the eww bar: the popup under the bar shows the hovered module's
# card (the popup window is always open, empty when nothing is hovered).
# Leaving is debounced: moving to the next module is a leave followed by an
# enter, and their handlers run concurrently. So an enter stamps hoverseq,
# a leave only notes the stamp and, a moment later and detached (eww kills
# a slow handler), clears the module if no enter has happened since.
#   enter NAME
#   leave
case $1 in
    enter) eww update "hovered=$2" "hoverseq=$(date +%s%N)" ;;
    leave) setsid -f "$0" clear-later "$(eww get hoverseq)" ;;
    clear-later)
        sleep 0.15
        [[ $(eww get hoverseq) == "$2" ]] && eww update hovered=
        ;;
    *) echo "usage: ${0##*/} enter NAME | leave" >&2; exit 1 ;;
esac
