#!/bin/bash
# Safety net for spurious wakes: launched (detached) by thinkpad-sleep-hook
# after every resume. If the lid is still closed and no external monitor is
# connected, nobody woke the machine on purpose, so suspend again.
#
# Why: the T14 Gen 5 AMD (BIOS 1.14) wakes itself 4-13 s after s2idle entry in
# about half of the cycles (EC/USB-C PD "connector change" event, followed by
# "ucsi_acpi: GET_CONNECTOR_STATUS failed (-110)"), then stays on for hours in
# the bag. Occurrences are logged with tag "thinkpad-resuspend".

LID_STATE=${LID_STATE:-/proc/acpi/button/lid/LID/state}
DELAY=${RESUSPEND_DELAY:-10}

log() { logger -t thinkpad-resuspend "$*"; }

lid_closed() { [ -r "$LID_STATE" ] && grep -q closed "$LID_STATE"; }

external_monitor() {
    local s
    for s in /sys/class/drm/card*-*/status; do
        case "$s" in *eDP*|*LVDS*|*DSI*|*Writeback*) continue ;; esac
        [ "$(cat "$s" 2>/dev/null)" = connected ] && return 0
    done
    return 1
}

lid_closed || exit 0          # normal wake, lid open
external_monitor && exit 0    # clamshell mode, stay awake

# Let the resume settle and give a real user time to open the lid.
sleep "$DELAY"
lid_closed || { log "lid opened within ${DELAY}s, staying awake"; exit 0; }
external_monitor && { log "external monitor connected, staying awake"; exit 0; }

# logind refuses a new request while the previous sleep operation is finishing.
for _ in $(seq 10); do
    systemctl is-active --quiet systemd-suspend.service || break
    sleep 1
done

log "woke with lid closed and no external monitor: suspending again"
systemctl suspend
