#!/bin/bash
# Jarvis: Claude Code (claudio, permissions skipped) in its own terminal,
# living in the scratchpad like telegram and the players (sway's
# for_window on app_id jarvis). Its home is ~/Agents/Jarvis, and it
# manages it: the character it plays (`character`, appended to the system
# prompt), CLAUDE.md with how it works, its notes under note/ (the
# memory, in place of Claude Code's automatic one, which
# .claude/settings.json there turns off). It starts there, so --continue
# picks up Jarvis's own last conversation and no other Claude session's. rustbar's MCP server gives it eyes and hands: the
# bar's widgets, sway's windows, workspaces and outputs, screenshots,
# sway commands, the journal. Launched again while running, it brings the
# window up instead.
HOME_DIR=$HOME/Agents/Jarvis

id=$(swaymsg -t get_tree | jq -r 'first(.. | objects | select(.app_id? == "jarvis") | .id) // empty')
if [ -n "$id" ]; then
    exec /home/m/Dotfiles/scripts/scratchpad-ctl.sh show "$id"
fi

# sway's own PATH may lack ~/.local/bin, where claude and rustbar are
export PATH="$HOME/.local/bin:$PATH"
cd "$HOME_DIR" || { notify-send -i dialog-error Jarvis "no $HOME_DIR"; exit 1; }

# the last conversation, when there is one: Claude Code keeps them per
# directory, under the path with every / and . turned into -
args=()
if compgen -G "$HOME/.claude/projects/${HOME_DIR//[\/.]/-}/*.jsonl" > /dev/null; then
    args+=(--continue)
fi

exec alacritty --class jarvis --title Jarvis -e claude "${args[@]}" \
    --dangerously-skip-permissions \
    --name jarvis \
    --append-system-prompt "$(cat "$HOME_DIR/character")" \
    --mcp-config '{"mcpServers": {"rustbar": {"command": "'"$HOME"'/.local/bin/rustbar", "args": ["mcp"]}}}' \
    --add-dir "$HOME/Dotfiles" "$HOME/Projects/rustbar"
