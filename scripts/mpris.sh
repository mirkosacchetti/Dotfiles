#!/bin/bash
# Media player module for the eww bar, built on playerctld: the active
# player is whichever was used last, `playerctld shift` cycles them.
#   status      JSON, long-running: the active player's track as text, and
#               as info the album, the app's own audio level (its PipeWire
#               stream, as pavucontrol shows it) and the player.
#               Refreshed on player, volume and player-list events
#   volume ARG  wpctl set-volume on the active player's stream (5%+, 5%-,
#               0.5...), the player's MPRIS volume if it has no stream
esc() { local s=$1; s=${s//&/\&amp;}; s=${s//</\&lt;}; s=${s//>/\&gt;}; printf %s "$s"; }

# players in playerctld order, the active one first, without the
# ".instance_N" suffix browsers add
players() { playerctl -l 2>/dev/null | sed 's/\.instance.*//'; }

# PipeWire node id of the player's output stream: the MPRIS name is normally
# the binary (spotify, firefox, cmus), else contained in the app name
# (Telegram's MPRIS name is tdesktop, its stream "Telegram Desktop"); with
# several streams (browser tabs) prefer a running one
stream_id() {
    local name=$1
    [[ $name == tdesktop ]] && name=telegram
    pw-dump 2>/dev/null | jq -r --arg p "$name" '
        [.[] | select(.info.props["media.class"]? == "Stream/Output/Audio")
         | .info.props as $q
         | select(($q["application.process.binary"] // "") == $p
                  or ($q["application.name"] // "" | ascii_downcase | contains($p))
                  or ($q["node.name"] // "" | ascii_downcase | contains($p)))
         | {id, running: (.info.state == "running")}]
        | sort_by(.running | not) | first // empty | .id'
}

# "55%" or "55% (muted)" for a stream, nothing when it is gone
stream_volume() {
    local v
    v=$(wpctl get-volume "$1" 2>/dev/null) || return 1
    [[ $v =~ Volume:\ ([0-9.]+)(.*MUTED)? ]] || return 1
    printf '%d%%%s' "$(awk "BEGIN { printf \"%d\", ${BASH_REMATCH[1]} * 100 + 0.5 }")" \
        "${BASH_REMATCH[2]:+ (muted)}"
}

case $1 in
    volume)
        active=$(players | head -1)
        [[ -n $active ]] || exit 0
        id=$(stream_id "$active")
        if [[ -n $id ]]; then
            exec wpctl set-volume -l 1.0 "$id" "$2"
        elif [[ $2 =~ ^([0-9]+)%([+-])$ ]]; then
            exec playerctl volume "$(awk "BEGIN { print ${BASH_REMATCH[1]} / 100 }")${BASH_REMATCH[2]}"
        else
            exec playerctl volume "$2"
        fi ;;
    status) ;;
    *) echo "usage: $0 status | volume ARG" >&2; exit 1 ;;
esac

# Event sources, all line-oriented, merged on one fd and told apart by their
# first field (fields split on \x1f: tabs would collapse empty ones):
#   M...  playerctl following the playerctld proxy, on every change of the
#         active player (no position: it would tick every second)
#   Event ... sink-input  pactl: a stream appeared, went away or changed volume
#   sig   dbus: playerctld's PropertiesChanged, i.e. the player list changed
# Anything else from pactl is ignored: rendering itself makes clients come
# and go (wpctl, pw-dump), reacting to those would loop.
exec {events}< <(
    trap 'kill $(jobs -p) 2>/dev/null' EXIT
    trap exit TERM
    stdbuf -oL playerctl -p playerctld --follow metadata --format \
        $'M\x1f{{status}}\x1f{{artist}}\x1f{{title}}\x1f{{album}}' &
    stdbuf -oL pactl subscribe 2>/dev/null &
    stdbuf -oL dbus-monitor --profile \
        "type='signal',sender='org.mpris.MediaPlayer2.playerctld',member='PropertiesChanged'" 2>/dev/null &
    wait
)
sources=$!
trap 'kill $sources 2>/dev/null' EXIT
# the bar does not kill us: a failed write means it is gone
trap '' PIPE

meta= stream= stream_of=
render() {
    local status artist title album dyn text info vol
    IFS=$'\x1f' read -r _ status artist title album <<< "$meta"
    mapfile -t names < <(players)
    local active=${names[0]}
    if [[ -z $active || ( $status != Playing && $status != Paused ) ]]; then
        echo '{"text": "", "info": ""}' || exit
        return
    fi
    dyn=$artist${artist:+${title:+ - }}$title
    (( ${#dyn} > 60 )) && dyn=${dyn:0:59}…
    case $status in
        Playing) text=" $(esc "$dyn")" ;;
        Paused) text=" <i>$(esc "$dyn")</i>" ;;
    esac
    # new active player or a stream event: look its stream up again
    if [[ $stream_of != "$active" || -z $stream ]]; then
        stream=$(stream_id "$active"); stream_of=$active
    fi
    vol=$(stream_volume "$stream") || {
        stream=
        vol=$(playerctl -p playerctld volume 2>/dev/null | awk '{ printf "%d%% (player)", $1 * 100 + 0.5 }')
    }
    # info: album, volume, the active player, what there is
    info=${album:+$(esc "$album")  |  }
    [[ -n $vol ]] && info+="󰕾 $vol  |  "
    info+=$active
    jq -cn --arg text "$text" --arg info "$info" --arg class "${status,,}" '{text: $text, info: $info, class: $class}' || exit
}

while :; do
    read -r -t 60 -u "$events" line; rc=$?
    if (( rc > 128 )); then
        # nothing for a minute: render anyway, so a bar that went away
        # without killing us is noticed (failed write) within that time
        render; continue
    fi
    (( rc == 0 )) || exit
    dirty=0
    # take whatever else is already queued (dbus signals come in bursts, a
    # shift is a burst plus playerctl's new line) so one burst is one render
    while :; do
        case $line in
            M$'\x1f'*) meta=$line; dirty=1 ;;
            *"on sink-input"*) dirty=1; [[ $line == *"'change'"* ]] || stream= ;;
            sig*) dirty=1 ;;
        esac
        read -r -t 0.2 -u "$events" line || break
    done
    (( dirty )) && render
done
