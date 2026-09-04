#!/bin/bash
# Wrapper for sway's swaybar_command: relaunch waybar if it crashes.
# waybar 0.15.0's battery module aborts (std::terminate) when a
# /sys/class/power_supply entry disappears mid-poll, e.g. on dock unplug.
# Fixed upstream after 0.15.0; drop this wrapper once the fix is packaged.
# Named without "waybar" so `pkill -RTMIN+N waybar` from other scripts
# doesn't hit the wrapper.
#
# sway hands the bar a private Wayland connection via WAYLAND_SOCKET (an
# inherited fd) and stops the bar on reload/exit by closing its end of it.
# That fd can only be used once, so waybar connects through WAYLAND_DISPLAY
# instead, and a watchdog reads the fd: EOF means sway wants us gone.

cleanup() { kill "$pid" "$watchdog" 2>/dev/null; exit 0; }
trap cleanup TERM INT HUP

ws=$WAYLAND_SOCKET
unset WAYLAND_SOCKET
if [[ $ws =~ ^[0-9]+$ ]]; then
    ( cat <&"$ws" >/dev/null 2>&1; kill -TERM $$ ) &
    watchdog=$!
    exec {ws}<&-
fi

fails=0
while :; do
    start=$SECONDS
    waybar "$@" &
    pid=$!
    wait "$pid"
    rc=$?
    # 0 = clean exit, 143 = killed by SIGTERM: intentional, don't respawn
    if [ "$rc" -eq 0 ] || [ "$rc" -eq 143 ]; then
        cleanup
    fi
    if (( SECONDS - start < 5 )); then
        fails=$((fails + 1))
        if (( fails >= 20 )); then
            echo "bar-loop: waybar keeps failing (rc=$rc), giving up" >&2
            cleanup
        fi
    else
        fails=0
    fi
    sleep 1
done
