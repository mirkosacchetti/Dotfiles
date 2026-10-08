#!/bin/bash
# Brightness of the screen in use, for waybar (custom/brightness, signal 6)
# and the XF86MonBrightness keys. The screen is the one picked with the
# middle click (display.sh next), else the focused output. The laptop
# panel goes through its backlight (brightnessctl, via logind), an external
# monitor through DDC/CI (ddcutil, which needs the i2c group and takes a
# few hundred ms per call, hence the cache: ddcutil is only asked every
# minute, or when a set changes the value).
#   status   waybar JSON: sun icon by level
#   info     waybar JSON for the drawer: "45%  ·  DP-7 DELL U2725QE", plus
#            the other screens when there are any
#   set ARG  5%+, 5%-, or an absolute percent; then signals waybar
CACHE_MAX_AGE=60
PICK=$XDG_RUNTIME_DIR/screen-pick
# nerd font glyphs as bytes, so the locale does not matter: sun (U+F185),
# brightness-5 and -6 (U+F00DF, U+F00E0), circle (U+F111)
printf -v SUN '\xef\x86\x85'; printf -v HALF '\xf3\xb0\x83\x9f'
printf -v HIGH '\xf3\xb0\x83\xa0'; printf -v FULL '\xef\x84\x91'

# active outputs, one per line, "name model" (the panel's model is a bare
# code, so only the name for that one), the focused one first
screens() {
    swaymsg -t get_outputs | jq -r '
        [.[] | select(.active)] | sort_by(.focused | not)[]
        | if .name | startswith("eDP") then .name else "\(.name) \(.model)" end'
}

# the picked screen if still there, else the focused one; sets name, model
# and others: the rest, starting after the current one and wrapping, the
# order the drawer lists them in
screen() {
    local pick i n
    pick=$(cat "$PICK" 2>/dev/null)
    mapfile -t all < <(screens)
    n=${#all[@]}
    for (( i = 0; i < n; i++ )); do
        [[ ${all[i]%% *} == "$pick" ]] && break
    done
    # no pick, or gone: the focused one, first in the list
    (( i == n )) && i=0
    read -r name model <<< "${all[i]}"
    others=("${all[@]:i+1}" "${all[@]:0:i}")
}

# ddcutil display number of an output, from the DRM connector in `detect`
# ("DRM_connector" in 3.0, "DRM connector" before)
ddc_display() {
    local cache=$XDG_RUNTIME_DIR/brightness-ddc-$1 n
    if n=$(cat "$cache" 2>/dev/null) && [[ -n $n ]]; then echo "$n"; return; fi
    n=$(ddcutil detect 2>/dev/null | awk -v out="$1" '
        /^Display [0-9]+/ { d = $2 }
        /DRM.connector:/ && $NF ~ ("-" out "$") { print d; exit }')
    [[ -n $n ]] && echo "$n" | tee "$cache"
}

fresh() { [[ -f $1 && $(( $(date +%s) - $(stat -c %Y "$1") )) -lt $CACHE_MAX_AGE ]]; }

# current percent of a screen, from the cache when fresh enough; the lock
# keeps the two waybar modules from asking ddcutil at the same time, the
# second one finds the cache filled
get() {
    local name=$1 cache=$XDG_RUNTIME_DIR/brightness-$1 v max d bl lock
    if [[ $name == eDP-* ]]; then
        bl=(/sys/class/backlight/*)
        read -r v < "${bl[0]}/brightness"
        read -r max < "${bl[0]}/max_brightness"
        echo $(( (v * 100 + max / 2) / max ))
        return
    fi
    exec {lock}> "$cache.lock"; flock "$lock"
    if fresh "$cache"; then cat "$cache"; return; fi
    d=$(ddc_display "$name") || return 1
    # "VCP 10 C 45 100"
    v=$(ddcutil getvcp 10 --brief --display "$d" 2>/dev/null | awk '{ print $4 }')
    [[ -n $v ]] && echo "$v" | tee "$cache"
}

screen
case $1 in
    status|info)
        pct=$(get "$name")
        if [[ -z $pct ]]; then
            icon=$SUN; text="no DDC/CI  ·  $name"
        else
            # same levels as waybar's backlight module had: half, high, full
            if (( pct >= 100 )); then icon=$FULL
            elif (( pct >= 76 )); then icon=$HIGH
            elif (( pct >= 51 )); then icon=$HALF
            else icon=$SUN; fi
            text="$pct%  ·  $name${model:+ $model}"
        fi
        (( ${#others[@]} )) && text+=", $(IFS=,; echo "${others[*]}" | sed 's/,/, /g')"
        [[ $1 == status ]] && text=$icon
        jq -cn --arg text "$text" '{text: $text}'
        ;;
    set)
        if [[ $name == eDP-* ]]; then
            brightnessctl -q set "$2"
        else
            d=$(ddc_display "$name") || exit 1
            cur=$(get "$name") || exit 1
            case $2 in
                *%+) new=$(( cur + ${2%\%+} )) ;;
                *%-) new=$(( cur - ${2%\%-} )) ;;
                *) new=${2%\%} ;;
            esac
            (( new > 100 )) && new=100
            (( new < 0 )) && new=0
            ddcutil setvcp 10 "$new" --display "$d" 2>/dev/null &&
                echo "$new" > "$XDG_RUNTIME_DIR/brightness-$name"
        fi
        pkill -RTMIN+6 waybar
        ;;
    *) echo "usage: ${0##*/} status|info|set ARG" >&2; exit 1 ;;
esac
