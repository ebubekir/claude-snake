#!/bin/bash
# claude-snake uninstaller

set -e

SNAKE_DIR="$HOME/.claude/snake"
SETTINGS="$HOME/.claude/settings.json"

RED='\033[31m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${RED}claude-snake uninstaller${RESET}"
echo ""

# Kill running game
if [ -f "$SNAKE_DIR/snake.pid" ]; then
  PID=$(cat "$SNAKE_DIR/snake.pid" 2>/dev/null)
  [ -n "$PID" ] && kill "$PID" 2>/dev/null || true
fi

# Remove game files
if [ -d "$SNAKE_DIR" ]; then
  rm -rf "$SNAKE_DIR"
  echo -e "  Removed ${DIM}$SNAKE_DIR${RESET}"
fi

# Remove hooks from settings
if [ -f "$SETTINGS" ] && command -v jq &>/dev/null; then
  cp "$SETTINGS" "$SETTINGS.bak"
  jq 'del(.hooks.UserPromptSubmit) | del(.hooks.Stop)' "$SETTINGS.bak" > "$SETTINGS"
  echo -e "  Removed hooks from ${DIM}$SETTINGS${RESET}"
else
  echo -e "  ${DIM}Remove UserPromptSubmit and Stop hooks manually from $SETTINGS${RESET}"
fi

echo ""
echo -e "${BOLD}Uninstalled.${RESET}"
