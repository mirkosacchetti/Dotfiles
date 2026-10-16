#!/bin/bash
# Coder Assistant: opencode on the local model served by the Mac
# (Ollama, qwen3-coder-next), in its own terminal, living in the
# scratchpad like Jarvis (sway's for_window on app_id coder). Its home is
# ~/Agents/Coder, and it manages it: the character it plays (`character`,
# the agent's prompt), AGENTS.md with how it works, its notes under note/
# (the memory). opencode.json there sets the agent, the model and the
# instructions, and gives it lintel's MCP server. It starts there, so
# --continue picks up its own last session. Launched again while running,
# it brings the window up instead.
HOME_DIR=$HOME/Agents/Coder

id=$(swaymsg -t get_tree | jq -r 'first(.. | objects | select(.app_id? == "coder") | .id) // empty')
if [ -n "$id" ]; then
    exec /home/m/Dotfiles/scripts/scratchpad-ctl.sh show "$id"
fi

# sway's own PATH may lack ~/.local/bin, where lintel is
export PATH="$HOME/.local/bin:$PATH"
cd "$HOME_DIR" || { notify-send -i dialog-error "Coder Assistant" "no $HOME_DIR"; exit 1; }

exec alacritty --class coder --title "Coder Assistant" -e opencode --continue
