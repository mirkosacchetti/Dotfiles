#!/bin/bash
# Toggle a wf-recorder region recording.
# A dot in waybar (custom/recording, signal 3) shows while it runs.

if pgrep -x wf-recorder >/dev/null; then
  pkill -INT -x wf-recorder
  sleep 0.3
  pkill -RTMIN+3 waybar
  notify-send -u low "Recording" "Stopped, video saved in ~/Videos"
else
  SELECTION=$(slurp 2>/dev/null)
  [[ -z $SELECTION ]] && exit 0
  mkdir -p "$HOME/Videos"
  wf-recorder -g "$SELECTION" -f "$HOME/Videos/screencast-$(date +%Y%m%d-%H%M%S).mp4" &
  sleep 0.3
  pkill -RTMIN+3 waybar
fi
