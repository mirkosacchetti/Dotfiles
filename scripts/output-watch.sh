#!/bin/bash
# Re-run the lid decision on every monitor hotplug.
#
# Sway emits an "output" IPC event when a monitor is plugged or unplugged,
# and that is the only notification we get for the case that matters:
# undocking with the lid still closed. No lid switch fires then, so nothing
# else would ever reconsider the clamshell decision made at lid-close time.
#
# swaymsg exits when sway does, which ends the loop and this script with it.

# Single instance: sway's `exec` runs once per session, but a manual start or
# a session restart must not leave two watchers firing the same decision.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/output-watch.lock"
flock -n 9 || exit 0

swaymsg -t subscribe -m '["output"]' | while read -r _; do
    /home/m/Dotfiles/scripts/lid-eval.sh --settle
done
