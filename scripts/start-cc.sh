#!/bin/bash
# Usage: start-cc.sh <task-dir> <prompt> <cwd> <mode> [--resume <session_id>]
# mode: plan | bypass
# Starts CC in background via setsid. Output goes to <task-dir>/output.json.
set -e

TASK_DIR="$1"
PROMPT="$2"
CWD="$3"
MODE="$4"
shift 4

# Validate inputs
if [ -z "$TASK_DIR" ] || [ -z "$PROMPT" ] || [ -z "$CWD" ] || [ -z "$MODE" ]; then
  echo "Usage: start-cc.sh <task-dir> <prompt> <cwd> <mode> [--resume <session_id>]" >&2
  exit 1
fi

# Build args — json mode produces ~1KB clean output
ARGS=(-p "$PROMPT" --output-format json --cwd "$CWD")

case "$MODE" in
  plan)   ARGS+=(--permission-mode plan) ;;
  bypass) ARGS+=(--permission-mode bypassPermissions) ;;
  *)      echo "ERROR: mode must be 'plan' or 'bypass'" >&2; exit 1 ;;
esac

# Handle --resume
if [ "$1" = "--resume" ] && [ -n "$2" ]; then
  ARGS+=(--resume "$2")
fi

# Clear previous output
rm -f "$TASK_DIR/output.json"

# Start CC in background (setsid detaches from terminal, /dev/null satisfies stdin check)
setsid claude "${ARGS[@]}" < /dev/null > "$TASK_DIR/output.json" 2>&1 &
CC_PID=$!
echo "$CC_PID" > "$TASK_DIR/cc.pid"

echo "CC_PID=$CC_PID"
echo "OUTPUT=$TASK_DIR/output.json"
