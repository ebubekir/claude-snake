#!/bin/bash
# Snake Game for Claude Code - Pure Bash, zero dependencies
# Plays in a terminal pane while waiting for Claude's response

set -u

SNAKE_DIR="${CLAUDE_SNAKE_DIR:-$HOME/.claude/snake}"
PID_FILE="$SNAKE_DIR/snake.pid"
HS_FILE="$SNAKE_DIR/highscore"

mkdir -p "$SNAKE_DIR"
echo $$ > "$PID_FILE"

# --- Terminal setup ---
cleanup() {
  tput cnorm 2>/dev/null
  stty sane 2>/dev/null
  printf '\033[2J\033[H'
  rm -f "$PID_FILE"
}
trap cleanup EXIT INT TERM HUP

tput civis 2>/dev/null
stty -echo -icanon min 0 time 0 2>/dev/null

# --- Colors ---
E=$'\033'
RST="${E}[0m"
BLD="${E}[1m"
DIM="${E}[2m"
GRN="${E}[32m"
BGN="${E}[92m"
RED="${E}[91m"
YEL="${E}[33m"
CYN="${E}[36m"
NL=$'\n'

# --- Auto-detect terminal size ---
COLS=$(tput cols 2>/dev/null || echo 60)
ROWS=$(tput lines 2>/dev/null || echo 24)
W=$(( (COLS - 4) / 2 ))
H=$(( ROWS - 6 ))
(( W > 28 )) && W=28
(( H > 16 )) && H=16
(( W < 10 )) && W=10
(( H < 8 )) && H=8

# --- Direction: 0=right 1=down 2=left 3=up ---
DX=(1 0 -1 0)
DY=(0 1 0 -1)

# --- Game state ---
declare -a SX SY G  # G: flat grid array, index = y*100+x (x<100)
dir=0 ndir=0 score=0 over=0 fx=0 fy=0
hi=0
[[ -f "$HS_FILE" ]] && { read -r hi < "$HS_FILE" 2>/dev/null; hi=${hi:-0}; }
tick="0.15"

# --- Pre-render static borders ---
BORDER_TOP="${DIM}+"
for ((x=0; x<W; x++)); do BORDER_TOP+="--"; done
BORDER_TOP+="+${RST}"

BORDER_BOT="$BORDER_TOP"

spawn_food() {
  local attempts=0
  while true; do
    fx=$(( RANDOM % W ))
    fy=$(( RANDOM % H ))
    [[ -z "${G[$((fy*100+fx))]:-}" ]] && break
    (( ++attempts > 500 )) && break
  done
}

init_game() {
  SX=() SY=() G=()
  local cx=$(( W / 2 )) cy=$(( H / 2 ))
  for ((i=0; i<3; i++)); do
    SX+=( $((cx - i)) )
    SY+=( $cy )
    G[$(( cy*100 + (cx - i) ))]=1
  done
  dir=0 ndir=0 score=0 over=0 tick="0.15"
  spawn_food
}

step() {
  (( over )) && return

  dir=$ndir
  local hx=$(( SX[0] + DX[dir] ))
  local hy=$(( SY[0] + DY[dir] ))

  # Wall collision
  if (( hx < 0 || hx >= W || hy < 0 || hy >= H )); then
    over=1
    (( score > hi )) && { hi=$score; echo "$hi" > "$HS_FILE"; }
    return
  fi

  # Self collision (allow moving into current tail position)
  if [[ -n "${G[$((hy*100+hx))]:-}" ]]; then
    local ti=$(( ${#SX[@]} - 1 ))
    if ! (( SX[ti] == hx && SY[ti] == hy )); then
      over=1
      (( score > hi )) && { hi=$score; echo "$hi" > "$HS_FILE"; }
      return
    fi
  fi

  # Add new head
  SX=( "$hx" "${SX[@]}" )
  SY=( "$hy" "${SY[@]}" )
  G[$(( hy*100+hx ))]=1

  # Eat food?
  if (( hx == fx && hy == fy )); then
    (( score += 10 ))
    if (( score % 50 == 0 )); then
      case $tick in
        0.15) tick="0.13" ;;
        0.13) tick="0.11" ;;
        0.11) tick="0.09" ;;
        0.09) tick="0.08" ;;
      esac
    fi
    spawn_food
  else
    # Remove tail
    local ti=$(( ${#SX[@]} - 1 ))
    unset "G[$(( SY[ti]*100 + SX[ti] ))]"
    unset "SX[$ti]" "SY[$ti]"
    SX=("${SX[@]}") SY=("${SY[@]}")
  fi
}

draw() {
  local buf="${E}[H"

  # Title bar
  local pad=$(( W * 2 - 22 ))
  (( pad < 0 )) && pad=0
  buf+="${BLD}${GRN} SNAKE ${RST} ${YEL}${score}${DIM}pts${RST}"
  buf+="$(printf '%*s' $pad '')"
  buf+="${DIM}Best:${hi}${RST}${NL}"

  # Top border
  buf+="${BORDER_TOP}${NL}"

  # Grid rows
  local hx=${SX[0]} hy=${SY[0]}
  for ((y=0; y<H; y++)); do
    buf+="${DIM}|${RST}"
    for ((x=0; x<W; x++)); do
      if (( x == hx && y == hy )); then
        buf+="${BGN}[]${RST}"
      elif (( x == fx && y == fy )); then
        buf+="${RED}<>${RST}"
      elif [[ -n "${G[$((y*100+x))]:-}" ]]; then
        buf+="${GRN}##${RST}"
      else
        buf+="  "
      fi
    done
    buf+="${DIM}|${RST}${NL}"
  done

  # Bottom border
  buf+="${BORDER_BOT}${NL}"

  # Status
  if (( over )); then
    buf+="${BLD}${RED} GAME OVER!${RST}"
    (( score == hi && score > 0 )) && buf+=" ${YEL}NEW BEST!${RST}"
    buf+=" ${DIM}[R] restart [Q] quit${RST}${NL}"
  else
    buf+="${DIM} Arrows/WASD: move  [Q] quit${RST}${NL}"
  fi
  buf+="${CYN} .. Claude is thinking...${RST}${NL}"

  printf '%s' "$buf"
}

handle_input() {
  local key
  IFS= read -rsn1 -t "$tick" key 2>/dev/null || true

  case "$key" in
    q|Q) exit 0 ;;
    r|R) (( over )) && init_game ;;
    w|W) (( dir != 1 )) && ndir=3 ;;
    s|S) (( dir != 3 )) && ndir=1 ;;
    a|A) (( dir != 0 )) && ndir=2 ;;
    d|D) (( dir != 2 )) && ndir=0 ;;
    "$E")
      IFS= read -rsn2 -t 0.01 key 2>/dev/null || true
      case "$key" in
        '[A') (( dir != 1 )) && ndir=3 ;;
        '[B') (( dir != 3 )) && ndir=1 ;;
        '[C') (( dir != 2 )) && ndir=0 ;;
        '[D') (( dir != 0 )) && ndir=2 ;;
      esac
      ;;
  esac
}

# --- Start ---
printf '\033[2J'
init_game

while true; do
  handle_input
  step
  draw
done
