#!/bin/bash
# Toggle registrazione schermo di una regione con wf-recorder.
# Un pallino in waybar (custom/recording, signal 3) mostra quando gira.

if pgrep -x wf-recorder >/dev/null; then
  pkill -INT -x wf-recorder
  sleep 0.3
  pkill -RTMIN+3 waybar
  notify-send -u low "Registrazione" "Fermata, video in ~/Videos"
else
  SELECTION=$(slurp 2>/dev/null)
  [[ -z $SELECTION ]] && exit 0
  mkdir -p "$HOME/Videos"
  wf-recorder -g "$SELECTION" -f "$HOME/Videos/screencast-$(date +%Y%m%d-%H%M%S).mp4" &
  sleep 0.3
  pkill -RTMIN+3 waybar
fi
