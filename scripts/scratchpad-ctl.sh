#!/bin/bash
# Usage: scratchpad-ctl.sh toggle|show CON_ID|next|prev|close|release|add|move [--else SWAY_COMMAND]
# Scratchpad logic on top of sway's: windows in a fixed order (creation), one
# shown at a time, next/prev swap directly. sway's own `scratchpad show`
# rotates a queue, so which window comes up depends on history, and showing
# one never hides the others; toggle here brings back the last one used.
# With --else, next/prev act only from a focused scratchpad window and run
# SWAY_COMMAND otherwise, so they can share keys with plain focus moves.
# close and release act on the window in front (focused, else the one shown
# on this workspace): close asks it to quit, release tiles it back into the
# workspace, which takes it out of the scratchpad (the inverse of
# `move scratchpad`). add sends the focused window into the scratchpad, move
# does add or release depending on whether the focused window is already a
# scratchpad one. Neither needs the state below, and add must not be stopped
# by the "scratchpad empty" exit, so they go first.
case $1 in
    add) exec swaymsg -q move scratchpad ;;
    move) if swaymsg -t get_tree | jq -e '.. | objects | select(.focused? and .scratchpad_state != "none")' > /dev/null
          then exec "$0" release; else exec "$0" add; fi ;;
esac
last_file=$XDG_RUNTIME_DIR/scratchpad-last

# scratchpad windows by creation: "id hidden|here|away focused"
# (hidden = in __i3_scratch, here = shown on the focused workspace)
mapfile -t windows < <(swaymsg -t get_tree | jq -r '
    (first(.. | objects | select(.type? == "workspace" and any(.. | objects; .focused))) | .name) as $cur
    | [.. | objects | select(.type? == "workspace") as $ws | $ws
       | .. | objects | select(.scratchpad_state? and .scratchpad_state != "none")
       | {id, focused, where: (if $ws.name == "__i3_scratch" then "hidden"
                               elif $ws.name == $cur then "here" else "away" end)}]
    | sort_by(.id)[] | "\(.id) \(.where) \(.focused)"')
ids=() shown=() focused= here=
for w in "${windows[@]}"; do
    read -r id where foc <<< "$w"
    ids+=("$id")
    [[ $foc == true ]] && focused=$id
    [[ $where == here ]] && here=$id
    [[ $where != hidden ]] && shown+=("$id")
done
[[ $2 == --else && -z $focused ]] && exec swaymsg "$3" > /dev/null
(( ${#ids[@]} )) || exit 0
last=$(cat "$last_file" 2>/dev/null)
[[ " ${ids[*]} " == *" $last "* ]] || last=${ids[0]}

hide() {
    echo "$1" > "$last_file"
    swaymsg "[con_id=$1] move scratchpad" > /dev/null
}

# show $1 on the focused workspace, sending any other shown one back first;
# resized to 88% of that workspace every time, since a floating window keeps
# the pixel size it got on the output where it was first shown
show() {
    local cmd= id
    for id in "${shown[@]}"; do
        # already on this workspace: just focus it, no hide/show flicker
        [[ $id == "$1" && $id == "$here" ]] && continue
        cmd+="[con_id=$id] move scratchpad; "
    done
    echo "$1" > "$last_file"
    swaymsg "$cmd[con_id=$1] focus; [con_id=$1] resize set 88 ppt 88 ppt, move position center" > /dev/null
    # the client may answer the resize with a different size (Spotify has a
    # minimum height) after sway already centered the requested one: center
    # again once it has settled
    ( sleep 0.2; swaymsg "[con_id=$1] move position center" > /dev/null ) &
}

# step through ids from the current one (focused, else shown here, else last)
step() {
    local cur=${focused:-${here:-$last}} i n=${#ids[@]}
    for i in "${!ids[@]}"; do [[ ${ids[i]} == "$cur" ]] && break; done
    # nothing up yet: start from the current one instead of skipping it
    [[ -z $focused && -z $here ]] && { show "$cur"; return; }
    show "${ids[(i + $1 + n) % n]}"
}

case $1 in
    toggle)
        # hidden: show it; shown here, focused or not: hide it — a click
        # on the bar never focuses it, so "focused" alone would show it
        # again (resized to this output) instead of hiding it
        if [[ -n ${focused:-$here} ]]; then hide "${focused:-$here}"
        else show "$last"
        fi ;;
    next) step 1 ;;
    prev) step -1 ;;
    show) [[ " ${ids[*]} " == *" $2 "* ]] && show "$2" ;;
    close) [[ -n ${focused:-$here} ]] && swaymsg -q "[con_id=${focused:-$here}] kill" ;;
    release) [[ -n ${focused:-$here} ]] && swaymsg -q "[con_id=${focused:-$here}] floating disable, border none" ;;
    *) echo "usage: ${0##*/} toggle|show CON_ID|next|prev|close|release|add|move [--else SWAY_COMMAND]" >&2; exit 1 ;;
esac
