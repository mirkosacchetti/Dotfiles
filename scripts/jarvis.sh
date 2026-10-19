#!/bin/bash
# Jarvis: Claude Code (claudio, permissions skipped) in its own terminal,
# living in the scratchpad like telegram and the players (sway's
# for_window on app_id jarvis). Its home is ~/Agents/Jarvis, and it
# manages it: the character it plays (`character`, appended to the system
# prompt), CLAUDE.md with how it works, its notes under note/ (the
# memory, in place of Claude Code's automatic one, which
# .claude/settings.json there turns off). It starts there, so --continue
# picks up Jarvis's own last conversation and no other Claude session's. lintel's MCP server gives it eyes and hands: the
# bar's widgets, sway's windows, workspaces and outputs, screenshots,
# sway commands, the journal.
#
# tmux-launch.sh runs it in a tmux session: closing the window only
# detaches, launched again it brings the window up or reopens one on the
# running conversation.
HOME_DIR=$HOME/Agents/Jarvis

# sway's own PATH may lack ~/.local/bin, where claude and lintel are
export PATH="$HOME/.local/bin:$PATH"
cd "$HOME_DIR" || { notify-send -i dialog-error Jarvis "no $HOME_DIR"; exit 1; }

# the last conversation, when there is one: Claude Code keeps them per
# directory, under the path with every / and . turned into -
args=()
if compgen -G "$HOME/.claude/projects/${HOME_DIR//[\/.]/-}/*.jsonl" > /dev/null; then
    args+=(--continue)
fi

exec /home/m/Dotfiles/scripts/tmux-launch.sh jarvis Jarvis "$HOME_DIR" -- \
    claude "${args[@]}" \
    --dangerously-skip-permissions \
    --name jarvis \
    --append-system-prompt "$(cat "$HOME_DIR/character")" \
    --mcp-config '{"mcpServers": {"lintel": {"command": "'"$HOME"'/.local/bin/lintel", "args": ["mcp"]}}}' \
    --add-dir "$HOME/Dotfiles" "$HOME/Projects/lintel"
