#!/bin/bash
# Lid closed: sway owns the decision (logind has HandleLidSwitch=ignore,
# see systemd/logind-lid.conf). With an external monitor active keep
# running in clamshell and just drop the internal panel; standalone, suspend.
external=$(swaymsg -t get_outputs | jq '[.[] | select(.name != "eDP-1" and .active)] | length')
if [ "$external" -gt 0 ]; then
    swaymsg output eDP-1 disable
else
    systemctl suspend
fi
