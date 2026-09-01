#
# ~/.bash_profile
#

# User bins in PATH for login shells, including non-interactive SSH (bash -lc)
export PATH="$HOME/.local/bin:$PATH"

[[ -f ~/.bashrc ]] && . ~/.bashrc

# Start sway automatically on tty1
if [ -z "$DISPLAY" ] && [ "$XDG_VTNR" = "1" ]; then
  exec sway 2> ~/.sway.log
fi
