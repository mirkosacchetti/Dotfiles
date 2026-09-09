#!/bin/bash
# Decide what to do with the current lid + output state. Sway owns this
# decision, logind's own lid handling is off (see systemd/logind-lid.conf).
#
#   lid open                -> nothing to do
#   lid closed + external   -> clamshell: keep running, drop the internal panel
#   lid closed, no external -> suspend
#
# Called from two places, because the lid switch alone is not enough:
#   - bindswitch lid:on, the normal "close the lid" case
#   - scripts/output-watch.sh, on every output hotplug. Unplugging the
#     external monitor while the lid is *already* closed fires no lid event,
#     so without this the machine stays awake with every screen off and goes
#     in the bag running.
#
# --settle waits a few seconds before acting on "no external monitor": a dock
# or a DisplayPort renegotiation can drop and re-add outputs, and that
# transient must not suspend the machine. The lid:on path skips it so closing
# the lid standalone still suspends immediately.

LID_STATE=${LID_STATE:-/proc/acpi/button/lid/LID/state}
SETTLE=0
[ "$1" = --settle ] && SETTLE=${LID_SETTLE:-4}

# Bursts of output events would otherwise race each other into `systemctl
# suspend`; the first invocation wins and the rest drop out.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/lid-eval.lock"
flock -n 9 || exit 0

lid_closed() { [ -r "$LID_STATE" ] && grep -q closed "$LID_STATE"; }

external_active() {
    swaymsg -t get_outputs |
        jq -e '[.[] | select(.name != "eDP-1" and .active)] | length > 0' >/dev/null
}

lid_closed || exit 0
external_active && exec swaymsg -q output eDP-1 disable

if [ "$SETTLE" -gt 0 ]; then
    sleep "$SETTLE"
    lid_closed || exit 0
    external_active && exec swaymsg -q output eDP-1 disable
fi

# Re-enable the internal panel before sleeping: it was disabled for clamshell,
# and sway does not reliably get the lid:off switch event across a resume, so
# reopening the lid would otherwise land on a black screen.
swaymsg -q output eDP-1 enable
logger -t lid-eval "lid closed with no external output: suspending"
systemctl suspend
