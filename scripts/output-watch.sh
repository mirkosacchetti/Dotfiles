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
    # Floor on the handling rate. Sway emits an output event for every output
    # command, so anything in lid-eval.sh that touches an output can feed an
    # event straight back into this loop; that is exactly what happened once
    # already (see the comment on go_clamshell in lid-eval.sh). A real hotplug
    # never needs to be handled more than once a second, and this cap means a
    # future regression of that shape costs one wakeup a second instead of
    # saturating the compositor. Events arriving during the sleep queue in the
    # pipe, so none are lost.
    sleep 1
done
