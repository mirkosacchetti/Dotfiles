#!/bin/bash
# The eww bar on every active output: opened where missing, closed where the
# output is gone. One-shot from sway's exec_always; `watch` keeps doing it on
# output events (hotplug), single instance. The first eww command starts the
# daemon, with sway's environment.
open_all() {
    local active o id
    active=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .name')
    for id in $(eww active-windows 2>/dev/null | sed -n 's/^\(bar-[^:]*\):.*/\1/p'); do
        grep -qx "${id#bar-}" <<< "$active" || eww close "$id"
    done
    for o in $active; do
        eww active-windows 2>/dev/null | grep -q "^bar-$o:" ||
            eww open bar --id "bar-$o" --screen "$o" --arg "screen=$o"
    done
}
if [[ $1 == watch ]]; then
    exec 9> "${XDG_RUNTIME_DIR:-/tmp}/bar-watch.lock"
    flock -n 9 || exit 0
    swaymsg -rm -t subscribe '["output"]' | while read -r _; do sleep 1; open_all; done
else
    open_all
fi
