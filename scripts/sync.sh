#!/bin/bash
# Sync: Tailscale and Syncthing, a switch each in the bar's toggles card
# (rustbar). Tailscale off is `tailscale down` (the daemon stays,
# disconnected), Syncthing off is its user service stopped. tailscale
# up/down needs this user as the daemon's operator, set once:
#   sudo tailscale set --operator=$USER
#
#   status                  JSON {tailscale: {on, info}, syncthing: {on, info}}
#   tailscale|syncthing on|off

status() {
    local ts st ts_on=false st_on=false ts_info st_info
    ts=$(tailscale status --json 2>/dev/null | jq -r '.BackendState // "NoState"')
    case $ts in
    Running) ts_on=true ts_info="On, $(tailscale ip -4 2>/dev/null)" ;;
    Stopped) ts_info=Off ;;
    *) ts_info=$ts ;;
    esac
    st=$(systemctl --user is-active syncthing.service)
    case $st in
    active) st_on=true st_info=On ;;
    inactive) st_info=Off ;;
    *) st_info=$st ;;
    esac
    jq -cn --argjson ts_on $ts_on --arg ts_info "$ts_info" --argjson st_on $st_on --arg st_info "$st_info" \
        '{tailscale: {on: $ts_on, info: $ts_info}, syncthing: {on: $st_on, info: $st_info}}'
}

# a failure says why in a notification, the switch goes back on refresh
run() {
    local out
    out=$("$@" 2>&1) || notify-send -i dialog-error Sync "$* failed: $out"
}

case $1:$2 in
status:) status ;;
tailscale:on) run tailscale up ;;
tailscale:off) run tailscale down ;;
syncthing:on) run systemctl --user start syncthing.service ;;
syncthing:off) run systemctl --user stop syncthing.service ;;
*) echo "usage: ${0##*/} status | tailscale|syncthing on|off" >&2; exit 1 ;;
esac
[[ $1 == status ]] || rustbar refresh sync
