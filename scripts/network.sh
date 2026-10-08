#!/bin/bash
# Network for the eww bar, polled: wifi through iwd (iwctl), else ethernet
# or nothing; the address and gateway from ip.
#   {"text": "ICON", "info": "wlan0: wifi25\nSignal: -44 dBm, 5.2 GHz\nIP: 192.168.2.54/24\nGateway: 192.168.2.1"}
printf -v WIFI '\xef\x87\xab'; printf -v ETH '\xf0\x9f\x96\xa7'; printf -v NOWIFI '\xf3\xb0\xa4\xad'

ip4() { ip -j -4 addr show "$1" 2>/dev/null | jq -r '.[0].addr_info[0] | select(.) | "\(.local)/\(.prefixlen)"'; }
gw() { ip -j route show default 2>/dev/null | jq -r '.[0].gateway // empty'; }
plain() { sed 's/\x1b\[[0-9;]*m//g'; }

wifi=$(iwctl device list 2>/dev/null | plain | awk '$NF == "station" { print $1; exit }')
if [[ -n $wifi ]]; then
    eval "$(iwctl station "$wifi" show 2>/dev/null | plain | awk '
        /^ *State /             { print "state=" $2 }
        /^ *Connected network / { $1 = $2 = ""; sub(/^ +/, ""); sub(/ +$/, ""); print "ssid=\"" $0 "\"" }
        /^ *RSSI /              { print "rssi=" $2 }
        /^ *Frequency /         { print "freq=" $2 }')"
fi
if [[ $state == connected ]]; then
    icon=$WIFI
    info="$wifi: $ssid"
    [[ -n $rssi ]] && info+=$'\n'"Signal: $rssi dBm${freq:+, $(awk "BEGIN { printf \"%.1f\", $freq / 1000 }") GHz}"
    addr=$(ip4 "$wifi"); g=$(gw)
    [[ -n $addr ]] && info+=$'\n'"IP: $addr"
    [[ -n $g ]] && info+=$'\n'"Gateway: $g"
else
    eth=$(ip -j link 2>/dev/null | jq -r '.[] | select(.operstate == "UP" and (.ifname | test("^(en|eth)"))) | .ifname' | head -1)
    if [[ -n $eth ]]; then
        icon=$ETH; info="$eth"$'\n'"IP: $(ip4 "$eth")"$'\n'"Gateway: $(gw)"
    else
        icon=$NOWIFI; info="Disconnected"
    fi
fi
jq -cn --arg text "$icon" --arg info "$info" '{text: $text, info: $info}'
