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

SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Validate inputs
if [ -z "$TASK_DIR" ] || [ -z "$PROMPT" ] || [ -z "$CWD" ] || [ -z "$MODE" ]; then
  echo "Usage: start-cc.sh <task-dir> <prompt> <cwd> <mode> [--resume <session_id>]" >&2
  exit 1
fi

# Verify claude CLI is available
if ! command -v claude > /dev/null 2>&1; then
  echo "ERROR: 'claude' CLI not found in PATH" >&2
  exit 1
fi

# Inject Supervisor Protocol via system prompt (not CLAUDE.md, to avoid file pollution)
SUPERVISOR_PROMPT="$(cat "$SKILL_DIR/templates/supervisor-protocol.md")"

# Build args — json mode produces ~1KB clean output
ARGS=(-p "$PROMPT" --output-format json --append-system-prompt "$SUPERVISOR_PROMPT")

# Both modes run unattended so need --dangerously-skip-permissions.
# "plan" vs "bypass" distinction is enforced by prompt instructions, not permission mode.
case "$MODE" in
  plan|bypass) ARGS+=(--dangerously-skip-permissions) ;;
  *)           echo "ERROR: mode must be 'plan' or 'bypass'" >&2; exit 1 ;;
esac

# Handle --resume (with fallback if session_id is missing/empty)
if [ "$1" = "--resume" ]; then
  SESSION_ID="$2"
  if [ -n "$SESSION_ID" ]; then
    ARGS+=(--resume "$SESSION_ID")
  else
    echo "WARN: --resume specified but session_id is empty, starting new session" >&2
  fi
fi

# Clear previous output
rm -f "$TASK_DIR/output.json"

# Start CC in background (cd to CWD first; setsid detaches from terminal; /dev/null satisfies stdin check)
# Unset CLAUDECODE to allow launching from within a CC session (claw-pilot dogfooding)
cd "$CWD"
setsid env -u CLAUDECODE claude "${ARGS[@]}" < /dev/null > "$TASK_DIR/output.json" 2>&1 &
CC_PID=$!

# Brief wait + verify process is alive
sleep 2
if ! kill -0 "$CC_PID" 2>/dev/null; then
  echo "ERROR: CC process (PID: $CC_PID) died immediately after launch" >&2
  [ -f "$TASK_DIR/output.json" ] && echo "Output:" >&2 && cat "$TASK_DIR/output.json" >&2
  exit 1
fi

echo "$CC_PID" > "$TASK_DIR/cc.pid"

echo "CC_PID=$CC_PID"
echo "OUTPUT=$TASK_DIR/output.json"
