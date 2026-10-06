#!/bin/bash
# Re-apply the modes set in sway's config to every output: undoes whatever was
# changed at runtime (nwg-displays) and retries a mode the monitor fell out
# of, e.g. the Dell staying at 60 Hz after a hotplug (see output-watch.sh).
# Right click on the waybar display indicator (custom/display).

CONFIG=/home/m/Dotfiles/linux/sway/config

# one "output ID mode MODE" per output block that sets a resolution, with
# $variables (set $laptop_display ...) resolved
awk '
    $1 == "set" {
        value = $0; sub(/^[ \t]*set[ \t]+[^ \t]+[ \t]+/, "", value)
        vars[$2] = value
    }
    $1 == "output" && $NF == "{" {
        id = $0; sub(/^[ \t]*output[ \t]+/, "", id); sub(/[ \t]*\{[ \t]*$/, "", id)
        if (id in vars) id = vars[id]
        next
    }
    $1 == "}" { id = "" }
    id != "" && ($1 == "resolution" || $1 == "mode") { print "output " id " mode " $2 }
' "$CONFIG" | while read -r cmd; do swaymsg "$cmd" > /dev/null 2>&1; done
notify-send -u low "Display" "Configured modes restored"
