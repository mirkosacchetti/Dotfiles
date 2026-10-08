#!/bin/bash
# Middle click in the bar steps to the next of something, wrapping around:
#   sink           default audio output (wpctl set-default)
#   source         default audio input
#   power-profile  powerprofilesctl
# Screens are display.sh next, players playerctld shift.

# the effective default node of a kind: pipewire's "default" metadata
current() {
    pw-dump | jq -r --arg key "$1" '
        .[] | select(.type == "PipeWire:Interface:Metadata" and .props["metadata.name"] == "default")
        | .metadata[] | select(.key == $key) | .value.name'
}

# nodes of a media class as "id name", by id, starting after the current
# default and wrapping, the current one left out
candidates() {
    pw-dump | jq -r --arg class "$1" --arg cur "$2" '
        [.[] | select(.info.props["media.class"]? == $class)
             | {id, name: .info.props["node.name"]}]
        | sort_by(.id)
        | (map(.name) | index($cur)) as $i
        | (if $i == null then . else .[$i + 1:] + .[:$i] end)
        | .[] | "\(.id) \(.name)"'
}

# wireplumber keeps the default where it is when the node asked for is not
# available (an HDMI port with nothing on it, a mic route the codec has not
# got): so try the candidates in turn until the default has really moved
cycle_node() {
    local class=$1 key=$2 cur id name i
    cur=$(current "$key")
    while read -r id name; do
        wpctl set-default "$id" 2>/dev/null || continue
        for i in 1 2 3 4 5; do
            sleep 0.1
            [[ $(current "$key") == "$name" ]] && return 0
        done
    done < <(candidates "$class" "$cur")
    # none took: put the configured default back on the current one
    [[ -n $cur ]] && wpctl set-default "$(pw-dump | jq -r --arg n "$cur" '.[] | select(.info.props["node.name"]? == $n) | .id')"
    return 1
}

case $1 in
    sink)   cycle_node Audio/Sink default.audio.sink ;;
    source) cycle_node Audio/Source default.audio.source ;;
    power-profile)
        # "* balanced:" marks the current one in the list
        powerprofilesctl set "$(powerprofilesctl list | awk '
            /^[ *]+[a-z-]+:$/ { sub(":", "", $NF); p[n++] = $NF; if ($1 == "*") cur = n - 1 }
            END { print p[(cur + 1) % n] }')" ;;
    *) echo "usage: ${0##*/} sink|source|power-profile" >&2; exit 1 ;;
esac
