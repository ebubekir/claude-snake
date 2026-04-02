#!/bin/bash
# Kill snake game when Claude finishes responding
# Called by Claude Code's Stop hook

PID_FILE="$HOME/.claude/snake/snake.pid"

if [ -f "$PID_FILE" ]; then
  PID=$(cat "$PID_FILE" 2>/dev/null)
  if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
    kill "$PID" 2>/dev/null
  fi
  rm -f "$PID_FILE"
fi

exit 0
