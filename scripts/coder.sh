#!/bin/bash
# Coder Assistant: opencode on the local model served by the Mac
# (Ollama, qwen3-coder-next), in its own terminal, living in the
# scratchpad like Jarvis (sway's for_window on app_id coder). Its home is
# ~/Agents/Coder, and it manages it: the character it plays (`character`,
# the agent's prompt), AGENTS.md with how it works, its notes under note/
# (the memory). opencode.json there sets the agent, the model and the
# instructions, and gives it lintel's MCP server. It starts there, so
# --continue picks up its own last session.
#
# tmux-launch.sh runs it in a tmux session: closing the window only
# detaches, launched again it brings the window up or reopens one on the
# running session.
HOME_DIR=$HOME/Agents/Coder

# sway's own PATH may lack ~/.local/bin, where lintel is
export PATH="$HOME/.local/bin:$PATH"
cd "$HOME_DIR" || { notify-send -i dialog-error "Coder Assistant" "no $HOME_DIR"; exit 1; }

exec /home/m/Dotfiles/scripts/tmux-launch.sh coder "Coder Assistant" "$HOME_DIR" -- \
    opencode --continue
