#!/bin/bash
# Brightness of the screen in use, for the eww bar (status, info keys)
# and the XF86MonBrightness keys. The screen is the one picked with the
# middle click (display.sh next), else the focused output. The laptop
# panel goes through its backlight (brightnessctl, via logind), an external
# monitor through DDC/CI, spoken directly on its I2C bus with i2ctransfer
# (i2c-tools): the monitor answers at address 0x37 to MCCS packets, VCP
# code 0x10 is brightness. ddcutil would do the same but its detection
# fails when the kernel does not link the connector to its I2C bus, as
# happens here with the Dell behind DisplayPort MST. The bus is found by
# reading the EDID (address 0x50) of each display bus and matching model
# and serial with sway's, then cached. Every transaction on a display bus
# goes through the GPU driver's AUX/DDC path and can stall the compositor
# (visible as input lag), so the scan is kept rare and short: aux and MST
# buses answer fast when empty, the HDMI DDC lines time out and are only
# tried for an HDMI output; a failed scan is not retried for 5 minutes.
#   status   JSON: sun icon by level, the info text as a second key
#   info     JSON with the text: "DP-7 DELL U2725QE  |  45%", the
#            label as display.sh writes it
#   set ARG  5%+, 5%-, or an absolute percent; then refreshes the bar
PICK=$XDG_RUNTIME_DIR/screen-pick
# nerd font glyphs as bytes, so the locale does not matter: sun (U+F185),
# brightness-5 and -6 (U+F00DF, U+F00E0), circle (U+F111)
printf -v SUN '\xef\x86\x85'; printf -v HALF '\xf3\xb0\x83\x9f'
printf -v HIGH '\xf3\xb0\x83\xa0'; printf -v FULL '\xef\x84\x91'

# active outputs, one per line, "name|model|serial", the focused one first
screens() {
    swaymsg -t get_outputs | jq -r '
        [.[] | select(.active)] | sort_by(.focused | not)[]
        | "\(.name)|\(.model)|\(.serial)"'
}

# the picked screen if still there, else the focused one; sets name, model,
# serial and label (name, plus the model unless it is the panel's bare code)
screen() {
    local pick i n
    pick=$(cat "$PICK" 2>/dev/null)
    mapfile -t all < <(screens)
    n=${#all[@]}
    for (( i = 0; i < n; i++ )); do
        [[ ${all[i]%%|*} == "$pick" ]] && break
    done
    (( i == n )) && i=0
    IFS='|' read -r name model serial <<< "${all[i]}"
    label=$(label "${all[i]}")
}
label() { local n=${1%%|*} m=${1#*|}; m=${m%|*}; [[ $n == eDP-* ]] && echo "$n" || echo "$n $m"; }

# DDC/CI packet checksum: XOR of the bytes with the destination address
# (0x6e = 0x37 << 1 for what we send, 0x50 for what the monitor answers)
chk() { local c=$1 b; shift; for b in "$@"; do c=$(( c ^ b )); done; printf '0x%02x' "$c"; }

# the I2C bus of an external output, by EDID: the 128-byte base block at
# 0x50, descriptors at 54, 72, 90, 108 tagged 0xfc (name) and 0xff (serial)
ddc_bus() {
    local cache=$XDG_RUNTIME_DIR/brightness-bus-$1 bus b e off tag s mname mserial pat
    if bus=$(cat "$cache" 2>/dev/null) && [[ -n $bus ]]; then echo "$bus"; return; fi
    [[ -f $cache.failed && $(( $(date +%s) - $(stat -c %Y "$cache.failed") )) -lt 300 ]] && return 1
    pat='DPMST|aux'; [[ $1 == HDMI* ]] && pat='AMDGPU DM i2c|DDC'
    for b in /sys/bus/i2c/devices/i2c-*; do
        # display buses only: the SMBus has EEPROMs at 0x50 too
        grep -qiE "$pat" "$b/name" || continue
        bus=${b##*i2c-}
        e=($(i2ctransfer -y "$bus" w1@0x50 0x00 r128@0x50 2>/dev/null)) || continue
        (( ${#e[@]} == 128 )) || continue
        mname= mserial=
        for off in 54 72 90 108; do
            (( e[off] == 0 && e[off+1] == 0 && e[off+2] == 0 )) || continue
            s=$(printf "$(printf '\\x%02x' "${e[@]:off+5:13}")" | tr -d '\n' | sed 's/ *$//')
            case ${e[off+3]} in 0xfc) mname=$s ;; 0xff) mserial=$s ;; esac
        done
        [[ $mname == "$2" && $mserial == "$3" ]] || continue
        # and it must speak DDC/CI: a valid reply to "get VCP 0x10"
        ddc_get "$bus" > /dev/null || continue
        echo "$bus" | tee "$cache"
        rm -f "$cache.failed"
        return
    done
    touch "$cache.failed"
    return 1
}

# brightness percent over DDC/CI: ask for VCP 0x10, the reply carries max
# and current (bytes 6-7, 8-9), checked by length, opcode and checksum
ddc_get() {
    local bus=$1 r
    i2ctransfer -y "$bus" w5@0x37 0x51 0x82 0x01 0x10 "$(chk 0x6e 0x51 0x82 0x01 0x10)" 2>/dev/null || return 1
    sleep 0.05
    r=($(i2ctransfer -y "$bus" r11@0x37 2>/dev/null)) || return 1
    [[ ${#r[@]} == 11 && ${r[1]} == 0x88 && ${r[2]} == 0x02 && ${r[4]} == 0x10 ]] || return 1
    [[ $(chk 0x50 "${r[@]:0:10}") == "${r[10]}" ]] || return 1
    local max=$(( r[6] << 8 | r[7] )) cur=$(( r[8] << 8 | r[9] ))
    (( max > 0 )) && echo $(( (cur * 100 + max / 2) / max ))
}

# set VCP 0x10 to a percent (the Dell's max is 100, the value is sent as is)
ddc_set() {
    local bus=$1 hi=$(( $2 >> 8 )) lo=$(( $2 & 0xff ))
    i2ctransfer -y "$bus" w7@0x37 0x51 0x84 0x03 0x10 "$hi" "$lo" "$(chk 0x6e 0x51 0x84 0x03 0x10 "$hi" "$lo")" 2>/dev/null
    sleep 0.05
}

# one DDC conversation at a time on a bus: the bar and the keys may ask
# at the same time
lock() { exec {lockfd}> "$XDG_RUNTIME_DIR/brightness-lock"; flock "$lockfd"; }

# current percent of the screen
get() {
    local bl bus v max
    if [[ $name == eDP-* ]]; then
        bl=(/sys/class/backlight/*)
        read -r v < "${bl[0]}/brightness"
        read -r max < "${bl[0]}/max_brightness"
        echo $(( (v * 100 + max / 2) / max ))
        return
    fi
    lock
    bus=$(ddc_bus "$name" "$model" "$serial") || return 1
    ddc_get "$bus" || { rm -f "$XDG_RUNTIME_DIR/brightness-bus-$name"; return 1; }
}

screen
case $1 in
    status|info)
        pct=$(get)
        if [[ -z $pct ]]; then
            icon=$SUN; text="$label  |  no DDC/CI"
        else
            # levels: half, high, full
            if (( pct >= 100 )); then icon=$FULL
            elif (( pct >= 76 )); then icon=$HIGH
            elif (( pct >= 51 )); then icon=$HALF
            else icon=$SUN; fi
            text="$label  |  $pct%"
        fi
        info=$text; [[ $1 == status ]] && text=$icon
        jq -cn --arg text "$text" --arg info "$info" '{text: $text, info: $info}'
        ;;
    set)
        if [[ $name == eDP-* ]]; then
            brightnessctl -q set "$2"
        else
            cur=$(get) || exit 1
            case $2 in
                *%+) new=$(( cur + ${2%\%+} )) ;;
                *%-) new=$(( cur - ${2%\%-} )) ;;
                *) new=${2%\%} ;;
            esac
            (( new > 100 )) && new=100
            (( new < 0 )) && new=0
            ddc_set "$(ddc_bus "$name" "$model" "$serial")" "$new"
        fi
        eww poll brightness
        ;;
    *) echo "usage: ${0##*/} status|info|set ARG" >&2; exit 1 ;;
esac
