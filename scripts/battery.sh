#!/bin/bash
# Battery for the eww bar, polled, from sysfs:
#   {"text": "100% ICON", "info": "100%, full" | "85%, 1h 30min left" | "40%, 0h 40min to full",
#    "class": "" | "warning" | "critical"}
printf -v CHARGING '\xef\x97\xa7'; printf -v PLUGGED '\xef\x87\xa6'
printf -v ICONS '\xef\x89\x84 \xef\x89\x83 \xef\x89\x82 \xef\x89\x81 \xef\x89\x80'; read -ra ICONS <<< "$ICONS"
B=/sys/class/power_supply/BAT0
read -r cap < $B/capacity; read -r status < $B/status
read -r now < $B/energy_now; read -r full < $B/energy_full; read -r power < $B/power_now
# hours and minutes to move wh at w
hm() { awk -v wh="$1" -v w="$2" 'BEGIN { if (w <= 0) exit; h = wh / w; printf "%dh %02dmin", h, (h - int(h)) * 60 }'; }
case $status in
    Charging) text="$CHARGING $cap%"; info="$cap%, $(hm $((full - now)) "$power") to full" ;;
    Full|"Not charging") text="$PLUGGED $cap%"; info="$cap%, full" ;;
    *) text="$cap% ${ICONS[cap * 4 / 100]}"; info="$cap%, $(hm "$now" "$power") left" ;;
esac
class=
if [[ $status != Charging ]]; then
    (( cap <= 30 )) && class=warning
    (( cap <= 15 )) && class=critical
fi
jq -cn --arg text "$text" --arg info "${info:-$cap%}" --arg class "$class" '{text: $text, info: $info, class: $class}'
