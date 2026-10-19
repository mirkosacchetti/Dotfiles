#!/bin/bash
# A terminal program as a desktop app, with a window that can be closed
# without killing it: the program runs in a tmux session named after the
# app, alacritty shows it with that app_id and title. Closing the window
# only detaches; launched again, the app brings its window up if there is
# one, else opens a new window on the running session, else starts the
# program afresh. The session ends when the program exits.
#
#   tmux-launch.sh NAME TITLE DIR -- COMMAND [ARG...]
#
# NAME is the tmux session, alacritty's --class (sway's app_id) and the
# window's fixed title when TITLE is empty. The window's title stays TITLE
# (the user's tmux.conf would retitle it) and tmux's status line is off:
# it is the app's window, not a terminal. The scratchpad script does the
# bringing up, so the app lives there when sway's for_window puts it in
# (jarvis.sh, coder.sh).
#
# tmux hands a command to the default shell as one string, which would
# undo the arguments' quoting (the JSON of --mcp-config, a prompt with
# newlines), so the session runs this script again, --inside, with the
# command carried in the environment in bash's own quoting (printf %q),
# and eval puts it back together exactly.
SCRATCHPAD=/home/m/Dotfiles/scripts/scratchpad-ctl.sh

if [ "$1" = --inside ]; then
    eval "exec $TMUX_LAUNCH_CMD"
fi

name=$1 title=${2:-$1} dir=$3 self=$(realpath "$0")
[ "$4" = -- ] || { echo "usage: ${0##*/} NAME TITLE DIR -- COMMAND [ARG...]" >&2; exit 2; }
shift 4

id=$(swaymsg -t get_tree | jq -r --arg a "$name" 'first(.. | objects | select(.app_id? == $a) | .id) // empty')
if [ -n "$id" ]; then
    exec "$SCRATCHPAD" show "$id"
fi

# -A attaches when the session is already there (its window closed
# earlier; -e is then ignored, the command inside is the running one),
# else creates it running this script --inside (by its absolute path:
# the session starts in DIR).
exec alacritty --class "$name" --title "$title" -e \
    tmux new-session -A -s "$name" -c "$dir" \
        -e TMUX_LAUNCH_CMD="$(printf '%q ' "$@")" \
        "$self --inside" \; \
        set-option set-titles-string "$title" \; \
        set-option status off
