# claude-snake

Play Snake in your terminal while waiting for Claude Code responses.

A pure Bash game (zero dependencies) that automatically opens in a side pane when you send a message to Claude Code, and closes when Claude responds.

```
 SNAKE   40pts        Best:120
+--------------------------------------------------------+
|                                                        |
|              []######                                  |
|                    ##                                  |
|                    ########                            |
|                                                        |
|                          <>                            |
|                                                        |
+--------------------------------------------------------+
 Arrows/WASD: move  [Q] quit
 .. Claude is thinking...
```

## How It Works

Uses [Claude Code hooks](https://docs.anthropic.com/en/docs/claude-code/hooks) to automatically manage the game:

1. **You send a message** &rarr; `UserPromptSubmit` hook launches snake in a side pane
2. **You play snake** while Claude thinks
3. **Claude responds** &rarr; `Stop` hook closes the game

The game only opens **one instance** - sending multiple messages won't spawn extra panes.

## Requirements

- **Bash 4+** (ships with most Linux/macOS/WSL systems)
- **One of:**
  - [tmux](https://github.com/tmux/tmux) (recommended)
  - [Windows Terminal](https://github.com/microsoft/terminal) (for WSL users)

## Installation

```bash
git clone https://github.com/ebubekir/claude-snake.git
cd claude-snake
bash install.sh
```

The installer:
1. Copies game files to `~/.claude/snake/`
2. Adds `UserPromptSubmit` and `Stop` hooks to `~/.claude/settings.json`
3. Verifies the installation

## Usage

### Automatic (with hooks)

Start Claude Code inside tmux or Windows Terminal:

```bash
# With tmux
tmux
claude

# Or just open Windows Terminal and run claude
```

Send any message - the snake game opens automatically in a side pane. It closes when Claude responds.

### Manual

```bash
bash ~/.claude/snake/snake.sh
```

## Controls

| Key | Action |
|-----|--------|
| `Arrow keys` / `WASD` | Move |
| `R` | Restart after game over |
| `Q` | Quit |

## Features

- **Zero dependencies** - pure Bash, works everywhere
- **Auto-sizing** - adapts to terminal dimensions
- **Persistent high score** - saved between sessions
- **Progressive speed** - gets faster every 50 points
- **Smart spawning** - won't open duplicate game panes

## Uninstall

```bash
cd claude-snake
bash uninstall.sh
```

Or manually:
```bash
rm -rf ~/.claude/snake
# Remove UserPromptSubmit and Stop hooks from ~/.claude/settings.json
```

## License

MIT
