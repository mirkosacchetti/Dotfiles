#!/bin/bash
# Bluetooth drawer for waybar (custom/bluetooth-info, signal 7), next to the
# builtin bluetooth icon: the connected devices with their battery, the
# picked one first; the middle click (`next`) picks the next one.
#   info   waybar JSON: "HHKB-Hybrid_1 85%, Mouse 60%", the controller's
#          name when nothing is connected, off when powered down
#   next   pick the next connected device, wrapping; then signals waybar
PICK=$XDG_RUNTIME_DIR/bt-pick

# connected devices as "mac name" lines, the picked one first
devices() {
    local pick
    pick=$(cat "$PICK" 2>/dev/null)
    bluetoothctl devices Connected 2>/dev/null | awk -v pick="$pick" '
        { sub(/^Device /, ""); if ($1 == pick) first = $0; else rest[n++] = $0 }
        END { if (first != "") print first; for (i = 0; i < n; i++) print rest[i] }'
}

case $1 in
    info)
        if ! bluetoothctl show 2>/dev/null | grep -q 'Powered: yes'; then
            text=off
        else
            text=
            while read -r mac name; do
                # "Battery Percentage: 0x55 (85)"
                pct=$(bluetoothctl info "$mac" 2>/dev/null | awk -F'[()]' '/Battery Percentage/ { print $2 "%" }')
                text+="${text:+, }$name${pct:+ $pct}"
            done < <(devices)
            [[ -n $text ]] || text=$(bluetoothctl show 2>/dev/null | awk '/Alias:/ { print $2 }')
        fi
        jq -cn --arg text "$text" '{text: $text}'
        ;;
    next)
        # the second of the list, which starts with the current one
        devices | awk 'NR == 2 { print $1 }' > "$PICK"
        pkill -RTMIN+7 waybar
        ;;
    *) echo "usage: ${0##*/} info|next" >&2; exit 1 ;;
esac
