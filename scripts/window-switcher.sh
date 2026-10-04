#!/bin/bash
# Pick an open window with fuzzel and focus it, switching to its workspace;
# ctrl+tab (custom-1) switches to the app launcher.

APP_DIRS=(~/.local/share/applications /usr/share/applications /var/lib/flatpak/exports/share/applications)

# "icon<TAB>name" from the .desktop entry named after the app_id/class, or
# declaring it as StartupWMClass; falls back to the app_id itself
app_info() {
    local f
    f=$(find "${APP_DIRS[@]}" -maxdepth 1 -iname "$1.desktop" 2>/dev/null | head -1)
    [[ -z $f ]] && f=$(grep -lix "StartupWMClass=$1" "${APP_DIRS[@]/%//*.desktop}" 2>/dev/null | head -1)
    [[ -n $f ]] && awk -F= -v id="$1" '
        /^\[/ && n++ { exit }
        $1 == "Icon" && !icon { icon = $2 }
        $1 == "Name" && !name { name = $2 }
        END { printf "%s\t%s\n", icon ? icon : tolower(id), name ? name : id }' "$f" \
        || printf '%s\t%s\n' "${1,,}" "$1"
}

mapfile -t WINDOWS < <(swaymsg -t get_tree | jq -r '
    .nodes[].nodes[]
    | (if .name == "__i3_scratch" then "scratch" else .name end) as $ws
    | recurse(.nodes[], .floating_nodes[])
    | select(.pid != null)
    | "\(.id)\t\(.app_id // .window_properties.class // "?")\t\($ws)\t\(.name)"')
declare -A INFO
IDX=$(for w in "${WINDOWS[@]}"; do
    IFS=$'\t' read -r _ app ws title <<< "$w"
    [[ -v INFO[$app] ]] || INFO[$app]=$(app_info "$app")
    IFS=$'\t' read -r icon name <<< "${INFO[$app]}"
    printf '[%s] %s — %s\0icon\x1f%s,application-x-executable\n' "$ws" "$name" "$title" "$icon"
done | fuzzel --dmenu --index)
RC=$?
(( RC == 10 )) && exec /home/m/Dotfiles/scripts/launcher.sh
(( RC == 0 )) && [[ $IDX =~ ^[0-9]+$ ]] || exit 0
ID=${WINDOWS[IDX]%%$'\t'*}
# scratchpad windows go through scratchpad-ctl: one shown at a time
if swaymsg -t get_tree | jq -e --argjson id "$ID" \
    '.. | objects | select(.id? == $id and (.scratchpad_state // "none") != "none")' > /dev/null; then
    exec /home/m/Dotfiles/scripts/scratchpad-ctl.sh show "$ID"
fi
swaymsg "[con_id=$ID] focus" > /dev/null
