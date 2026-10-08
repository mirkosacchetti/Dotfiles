#!/bin/bash
# Bluetooth for the eww bar: the picked connected device with its battery;
# the middle click (`next`) picks the next one.
#   info   JSON: "HHKB-Hybrid_1", then "Battery: 85%"; or no device, or off
#   status the icon (off, on, connected) with that text as info key
#   next   pick the next connected device, wrapping; then refreshes the bar
PICK=$XDG_RUNTIME_DIR/bt-pick
printf -v BT '\xef\x8a\x94'; printf -v BTOFF '\xf3\xb0\x82\xb2'; printf -v BTCONN '\xf3\xb0\x82\xb0'

# connected devices as "mac name" lines, the picked one first
devices() {
    local pick
    pick=$(cat "$PICK" 2>/dev/null)
    bluetoothctl devices Connected 2>/dev/null | awk -v pick="$pick" '
        { sub(/^Device /, ""); if ($1 == pick) first = $0; else rest[n++] = $0 }
        END { if (first != "") print first; for (i = 0; i < n; i++) print rest[i] }'
}

case $1 in
    info|status)
        if ! bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
            text=Off; icon=$BTOFF
        else
            icon=$BT
            read -r mac name < <(devices)
            if [[ -n $mac ]]; then
                # "Battery Percentage: 0x55 (85)"
                pct=$(bluetoothctl info "$mac" 2>/dev/null | awk -F'[()]' '/Battery Percentage/ { print $2 "%" }')
                text="$name${pct:+$'\n'Battery: $pct}"; icon=$BTCONN
            else
                text="No device connected"
            fi
        fi
        [[ $1 == status ]] && jq -cn --arg text "$icon" --arg info "$text" '{text: $text, info: $info}' \
                           || jq -cn --arg text "$text" '{text: $text}'
        ;;
    next)
        # the second of the list, which starts with the current one
        devices | awk 'NR == 2 { print $1 }' > "$PICK"
        eww poll bluetooth
        ;;
    *) echo "usage: ${0##*/} info|next" >&2; exit 1 ;;
esac
