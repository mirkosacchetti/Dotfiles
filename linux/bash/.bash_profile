#
# ~/.bash_profile
#

# User bins in PATH for login shells, including non-interactive SSH (bash -lc)
export PATH="$HOME/.local/bin:$PATH"

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start sway automatically on tty1. With Xwayland disabled sway no longer
# sets DISPLAY, so WAYLAND_DISPLAY is the guard too: without it every login
# shell opened inside the session (bash -l, Claude Code's shell) started a
# nested sway, with its whole exec list.
if [ -z "$DISPLAY" ] && [ -z "$WAYLAND_DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
  exec sway 2> ~/.sway.log
fi
