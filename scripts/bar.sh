#!/bin/bash
# The eww bar on every active output: opened where missing, closed where the
# output is gone. `watch` (the eww-bar user service) does it at start and on
# every output event (hotplug), single instance; without arguments (sway's
# exec_always) once. The daemon is the eww user service
# (linux/systemd/user/eww.service), started here if needed.
daemon() {
    local i
    systemctl --user start eww.service
    for i in 1 2 3 4 5 6 7 8 9 10; do eww ping > /dev/null 2>&1 && return 0; sleep 0.5; done
    return 1
}

# true when every active output has its bar
open_all() {
    local active open o id ok=0
    active=$(swaymsg -t get_outputs | jq -r '.[] | select(.active) | .name')
    open=$(eww active-windows 2>/dev/null)
    for id in $(sed -n 's/^\(bar-[^:]*\):.*/\1/p' <<< "$open"); do
        grep -qx "${id#bar-}" <<< "$active" || eww close "$id"
    done
    for o in $active; do
        grep -q "^bar-$o:" <<< "$open" && continue
        # a monitor just plugged may not have its name in GTK yet: the
        # caller retries
        eww open bar --id "bar-$o" --screen "$o" --arg "screen=$o" > /dev/null 2>&1 || ok=1
    done
    return $ok
}

daemon || exit 1
if [[ $1 == watch ]]; then
    exec 9> "${XDG_RUNTIME_DIR:-/tmp}/bar-watch.lock"
    flock -n 9 || exit 0
    for _ in 1 2 3 4 5; do open_all && break; sleep 1; done
    swaymsg -rm -t subscribe '["output"]' | while read -r _; do
        for _ in 1 2 3 4 5; do sleep 1; open_all && break; done
    done
else
    open_all
fi
