#!/bin/bash
# Toggle a wf-recorder region recording.
# A dot in the bar (lintel) (recording) shows while it runs.

if pgrep -x wf-recorder >/dev/null; then
  pkill -INT -x wf-recorder
  sleep 0.3
  lintel refresh recording
  notify-send -u low "Recording" "Stopped, video saved in ~/Videos"
else
  SELECTION=$(slurp 2>/dev/null)
  [[ -z $SELECTION ]] && exit 0
  mkdir -p "$HOME/Videos"
  wf-recorder -g "$SELECTION" -f "$HOME/Videos/screencast-$(date +%Y%m%d-%H%M%S).mp4" &
  sleep 0.3
  lintel refresh recording
fi
