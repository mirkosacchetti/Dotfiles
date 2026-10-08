#!/bin/bash
# Audio for the eww bar: default output and input as one JSON line,
# long-running, refreshed on pipewire's sink/source/server events (pactl
# subscribe; client events are ignored, our own wpctl calls make those).
#   {"sink": {"text": "ICON 78%", "info": "Volume: 78%\nDevice: FiiO K5 Pro Pro", "muted": false},
#    "source": {"text": "ICON", "info": "Volume: 45%\nDevice: Ryzen ... Microphone", "muted": false}}
printf -v VOL0 '\xef\x80\xa6'; printf -v VOL1 '\xef\x80\xa7'; printf -v VOL2 '\xef\x80\xa8'
printf -v HEADPHONE '\xef\x80\xa5'; printf -v MUTED '\xef\x9a\xa9'
printf -v MIC '\xef\x84\xb0'; printf -v MICMUTED '\xef\x84\xb1'

# "55 muted" from wpctl's "Volume: 0.55 [MUTED]"
volume() {
    wpctl get-volume "$1" 2>/dev/null | awk '{ printf "%d %s", $2 * 100 + 0.5, ($3 == "[MUTED]") ? "muted" : "" }'
}
# "form-factor|description" of a default node
describe() {
    wpctl inspect "$1" 2>/dev/null | awk -F'"' '/node.description/ { d = $2 } /device.form-factor/ { f = $2 } END { print f "|" d }'
}
bool() { [[ -n $1 ]] && echo true || echo false; }

emit() {
    local v m desc ff icon sink source
    read -r v m < <(volume @DEFAULT_AUDIO_SINK@)
    IFS='|' read -r ff desc < <(describe @DEFAULT_AUDIO_SINK@)
    if [[ $m == muted ]]; then icon=$MUTED
    elif [[ $ff == headphone || $ff == headset ]]; then icon=$HEADPHONE
    elif (( v > 66 )); then icon=$VOL2
    elif (( v > 33 )); then icon=$VOL1
    else icon=$VOL0; fi
    sink=$(jq -cn --arg text "$icon${m:+}${m:- $v%}" --arg info "${m:+Muted}${m:-Volume: $v%}"$'\n'"Device: $desc" --argjson muted "$(bool "$m")" \
        '{text: $text, info: $info, muted: $muted}')
    read -r v m < <(volume @DEFAULT_AUDIO_SOURCE@)
    IFS='|' read -r ff desc < <(describe @DEFAULT_AUDIO_SOURCE@)
    [[ $m == muted ]] && icon=$MICMUTED || icon=$MIC
    source=$(jq -cn --arg text "$icon" --arg info "${m:+Muted}${m:-Volume: $v%}"$'\n'"Device: $desc" --argjson muted "$(bool "$m")" \
        '{text: $text, info: $info, muted: $muted}')
    jq -cn --argjson sink "$sink" --argjson source "$source" '{sink: $sink, source: $source}'
}

emit || exit
# exit once the bar is gone (write fails) instead of lingering
stdbuf -oL pactl subscribe 2>/dev/null | while read -r line; do
    case $line in
        *" on sink"*|*" on source"*|*" on server"*|*" on card"*) ;;
        *) continue ;;
    esac
    # a burst (volume steps, device switch) is one emit
    while read -r -t 0.1 _; do :; done
    emit || exit
done
