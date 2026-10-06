#!/bin/bash
# Re-run the lid decision on every monitor hotplug.
#
# Sway emits an "output" IPC event when a monitor is plugged or unplugged,
# and that is the only notification we get for the case that matters:
# undocking with the lid still closed. No lid switch fires then, so nothing
# else would ever reconsider the clamshell decision made at lid-close time.
#
# It also fixes the external monitor's refresh rate after a plug: see
# fix_refresh below.
#
# swaymsg exits when sway does, which ends the loop and this script with it.

# Single instance: sway's `exec` runs once per session, but a manual start or
# a session restart must not leave two watchers firing the same decision.
exec 9>"${XDG_RUNTIME_DIR:-/tmp}/output-watch.lock"
flock -n 9 || exit 0

# Refresh-rate fallback for the Dell. amdgpu on this APU (DCN 3.1.4) sometimes
# rejects the first 4K@120 modeset right after hotplug: the kernel logs a
# REG_WAIT timeout in dcn31_program_compbuf_size and a WARNING out of
# amdgpu_dm_atomic_check, sway's configured mode fails, and sway silently
# settles on the monitor's preferred 60 Hz mode. The link itself negotiates
# fine (4 lanes HBR3, DSC on), so re-issuing the configured mode once things
# have settled succeeds. Retries are capped per plug: a failed mode command
# also emits an output event, so without the cap this would ask once a second
# forever on a link that genuinely cannot do 120. The counter re-arms when
# the monitor goes away.
DELL='Dell Inc. DELL U2725QE GNM6C34'
DELL_MODE='3840x2160@120Hz'   # keep in sync with linux/sway/config
DELL_MIN_REFRESH=119000       # mHz, as sway reports it
DELL_MAX_TRIES=3
dell_tries=0
dell_retried=0   # a retry went out and its outcome has not been reported yet

notify() { notify-send -u "$1" -i video-display "Monitor" "$2"; logger -t output-watch "$2"; }

fix_refresh() {
    local name refresh has_mode
    # Connector name (DP-7 style) from the identity string: output commands go
    # through swaymsg, which joins its arguments and re-tokenizes them, so a
    # quoted make/model/serial would come apart. The connector name has no
    # spaces and is unambiguous while the monitor is plugged.
    IFS=$'\t' read -r name refresh has_mode < <(swaymsg -t get_outputs | jq -r --arg m "$DELL" --argjson min "$DELL_MIN_REFRESH" \
        '.[] | select(.active and (.make + " " + .model + " " + .serial) == $m)
             | [.name, (.current_mode.refresh // 0), any(.modes[]; .width == 3840 and .refresh >= $min)] | @tsv')
    if [ -z "$name" ]; then
        dell_tries=0
        dell_retried=0
        return
    fi
    # No 120 Hz mode on offer at all: the link came up without the bandwidth
    # for it (DSC off or a lower rate), the kernel filtered those modes out,
    # and no mode command can bring them back. Only a replug retrains the
    # link. Say so once per plug instead of burning the retries.
    if [ "$has_mode" != true ]; then
        if [ "$dell_tries" -lt "$DELL_MAX_TRIES" ]; then
            dell_tries=$DELL_MAX_TRIES
            dell_retried=0
            notify normal "Dell link came up without 120 Hz modes (now $(( (refresh + 500) / 1000 )) Hz), replug the cable to retrain it"
        fi
        return
    fi
    if [ "$refresh" -ge "$DELL_MIN_REFRESH" ]; then
        if [ "$dell_retried" = 1 ]; then
            dell_retried=0
            notify low "Dell back at $(( (refresh + 500) / 1000 )) Hz after $dell_tries retr$([ "$dell_tries" = 1 ] && echo y || echo ies)"
        fi
        return
    fi
    if [ "$dell_tries" -ge "$DELL_MAX_TRIES" ]; then
        if [ "$dell_retried" = 1 ]; then
            dell_retried=0
            notify normal "Dell stuck at $(( (refresh + 500) / 1000 )) Hz after $DELL_MAX_TRIES retries, giving up until replug"
        fi
        return
    fi
    dell_tries=$((dell_tries + 1))
    dell_retried=1
    # Give link training a moment: retrying in the same instant the first
    # modeset failed tends to fail the same way.
    sleep 2
    notify low "Dell at $(( (refresh + 500) / 1000 )) Hz, re-applying $DELL_MODE (try $dell_tries/$DELL_MAX_TRIES)"
    swaymsg -q output "$name" mode "$DELL_MODE"
}

swaymsg -t subscribe -m '["output"]' | while read -r _; do
    /home/m/Dotfiles/scripts/lid-eval.sh --settle
    fix_refresh
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
