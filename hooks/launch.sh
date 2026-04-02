#!/bin/bash
# Launch snake game when Claude starts thinking
# Called by Claude Code's UserPromptSubmit hook

SNAKE_DIR="$HOME/.claude/snake"
PID_FILE="$SNAKE_DIR/snake.pid"
GAME="$SNAKE_DIR/snake.sh"

# Don't launch if game is already running
if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE" 2>/dev/null)
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    exit 0
  fi
  rm -f "$PID_FILE"
fi

# Method 1: tmux (preferred - splits current window)
if [ -n "${TMUX:-}" ]; then
  tmux split-window -h -l 62 "bash $GAME" 2>/dev/null
  exit 0
fi

# Method 2: Windows Terminal split pane
if command -v wt.exe &>/dev/null; then
  DISTRO="${WSL_DISTRO_NAME:-Ubuntu}"
  wt.exe -w 0 sp -s 0.35 -- wsl.exe -d "$DISTRO" -- bash "$GAME" 2>/dev/null &
  exit 0
fi

# No supported terminal multiplexer found
exit 0
