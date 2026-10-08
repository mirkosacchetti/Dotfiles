#!/bin/bash
# Sway state for the eww bar, long-running, one JSON line at start and on
# every workspace, window and mode event:
#   {"workspaces": [{"name", "num", "focused", "visible", "urgent"}],
#    "mode": "default", "title": "focused window title"}
emit() {
    jq -cn \
        --argjson ws "$(swaymsg -t get_workspaces)" \
        --argjson mode "$(swaymsg -t get_binding_state)" \
        --argjson tree "$(swaymsg -t get_tree)" '
        { workspaces: ($ws | map({name, num, focused, visible, urgent})),
          mode: $mode.name,
          title: ([$tree | .. | objects | select(.focused? == true and .type != "workspace") | .name] | first // "") }'
}
# only what changed goes out: window events come for focus, titles and
# more, most of them leave the line as it was
last=
emit_changed() {
    local line
    line=$(emit) || return 1
    [[ $line == "$last" ]] && return 0
    last=$line
    echo "$line"
}
emit_changed || exit
# exit once the bar is gone (write fails) instead of lingering
swaymsg -rm -t subscribe '["workspace", "window", "mode"]' | while read -r _; do
    # a burst of events is one emit
    while read -r -t 0.05 _; do :; done
    emit_changed || exit
done
