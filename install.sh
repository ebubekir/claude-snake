#!/bin/bash
# claude-snake installer
# Copies game files and configures Claude Code hooks

set -e

SNAKE_DIR="$HOME/.claude/snake"
SETTINGS="$HOME/.claude/settings.json"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

GREEN='\033[32m'
YELLOW='\033[33m'
CYAN='\033[36m'
DIM='\033[2m'
BOLD='\033[1m'
RESET='\033[0m'

echo -e "${BOLD}${GREEN}claude-snake installer${RESET}"
echo ""

# Step 1: Copy game files
echo -e "${CYAN}[1/3]${RESET} Installing game files..."
mkdir -p "$SNAKE_DIR"
cp "$SCRIPT_DIR/snake.sh" "$SNAKE_DIR/snake.sh"
cp "$SCRIPT_DIR/hooks/launch.sh" "$SNAKE_DIR/launch.sh"
cp "$SCRIPT_DIR/hooks/kill.sh" "$SNAKE_DIR/kill.sh"
chmod +x "$SNAKE_DIR/snake.sh" "$SNAKE_DIR/launch.sh" "$SNAKE_DIR/kill.sh"
echo -e "  Installed to ${DIM}$SNAKE_DIR${RESET}"

# Step 2: Configure Claude Code hooks
echo -e "${CYAN}[2/3]${RESET} Configuring Claude Code hooks..."

if [ ! -f "$SETTINGS" ]; then
  # No settings file - create one with hooks
  cat > "$SETTINGS" << 'SETTINGS_EOF'
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/snake/launch.sh",
            "timeout": 5
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ~/.claude/snake/kill.sh",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
SETTINGS_EOF
  echo -e "  Created ${DIM}$SETTINGS${RESET}"
elif command -v jq &>/dev/null; then
  # Merge hooks into existing settings using jq
  HOOKS_JSON='{
    "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash ~/.claude/snake/launch.sh", "timeout": 5}]}],
    "Stop": [{"hooks": [{"type": "command", "command": "bash ~/.claude/snake/kill.sh", "timeout": 5}]}]
  }'

  # Check if hooks already exist
  HAS_SUBMIT=$(jq -r '.hooks.UserPromptSubmit // empty' "$SETTINGS" 2>/dev/null)
  HAS_STOP=$(jq -r '.hooks.Stop // empty' "$SETTINGS" 2>/dev/null)

  if [ -n "$HAS_SUBMIT" ] && [ -n "$HAS_STOP" ]; then
    echo -e "  ${YELLOW}Hooks already configured, skipping${RESET}"
  else
    cp "$SETTINGS" "$SETTINGS.bak"
    jq --argjson hooks "$HOOKS_JSON" '.hooks = (.hooks // {}) + $hooks' "$SETTINGS.bak" > "$SETTINGS"
    echo -e "  Updated ${DIM}$SETTINGS${RESET} ${DIM}(backup: settings.json.bak)${RESET}"
  fi
else
  # No jq available - show manual instructions
  echo -e "  ${YELLOW}jq not found. Add these hooks manually to $SETTINGS:${RESET}"
  echo ""
  echo '    "hooks": {'
  echo '      "UserPromptSubmit": [{"hooks": [{"type": "command", "command": "bash ~/.claude/snake/launch.sh", "timeout": 5}]}],'
  echo '      "Stop": [{"hooks": [{"type": "command", "command": "bash ~/.claude/snake/kill.sh", "timeout": 5}]}]'
  echo '    }'
  echo ""
fi

# Step 3: Verify
echo -e "${CYAN}[3/3]${RESET} Verifying installation..."
if [ -x "$SNAKE_DIR/snake.sh" ] && [ -x "$SNAKE_DIR/launch.sh" ] && [ -x "$SNAKE_DIR/kill.sh" ]; then
  echo -e "  ${GREEN}All files installed and executable${RESET}"
else
  echo -e "  ${YELLOW}Warning: Some files may not be executable${RESET}"
fi

echo ""
echo -e "${BOLD}${GREEN}Done!${RESET} Snake game is ready."
echo ""
echo -e "  ${BOLD}How to use:${RESET}"
echo -e "  ${DIM}1.${RESET} Start Claude Code (inside tmux or Windows Terminal)"
echo -e "  ${DIM}2.${RESET} Send a message - snake game opens in a side pane"
echo -e "  ${DIM}3.${RESET} Play while Claude thinks - game closes when Claude responds"
echo ""
echo -e "  ${DIM}Manual play:${RESET} bash ~/.claude/snake/snake.sh"
echo -e "  ${DIM}Uninstall:${RESET}   bash $(dirname "$0")/uninstall.sh"
