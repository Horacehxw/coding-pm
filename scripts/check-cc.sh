#!/bin/bash
# Usage: check-cc.sh <task-dir>
# Outputs structured status for the PM agent to parse.

TASK_DIR="$1"

if [ -z "$TASK_DIR" ]; then
  echo "Usage: check-cc.sh <task-dir>" >&2
  exit 1
fi

WORKTREE=$(cat "$TASK_DIR/worktree" 2>/dev/null)

# 1. Process status
PID=$(cat "$TASK_DIR/cc.pid" 2>/dev/null)
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  echo "STATUS: running (PID: $PID)"
else
  echo "STATUS: finished"
fi

# 2. Progress file (Track B: written by CC in worktree)
if [ -n "$WORKTREE" ] && [ -f "$WORKTREE/.supervisor/progress.json" ]; then
  echo "PROGRESS: $(cat "$WORKTREE/.supervisor/progress.json")"
fi

# 3. Git progress (Track A: deterministic ground truth)
if [ -n "$WORKTREE" ] && { [ -d "$WORKTREE/.git" ] || [ -f "$WORKTREE/.git" ]; }; then
  COMMITS=$(cd "$WORKTREE" && git log --oneline main..HEAD 2>/dev/null | wc -l)
  LAST=$(cd "$WORKTREE" && git log --oneline -1 2>/dev/null)
  echo "COMMITS: $COMMITS | LAST: $LAST"
fi

# 4. CC output (available after process finishes)
if [ -f "$TASK_DIR/output.json" ] && [ -s "$TASK_DIR/output.json" ]; then
  IS_ERROR=$(jq -r '.is_error // empty' "$TASK_DIR/output.json" 2>/dev/null)
  SESSION=$(jq -r '.session_id // empty' "$TASK_DIR/output.json" 2>/dev/null)
  COST=$(jq -r '.total_cost_usd // empty' "$TASK_DIR/output.json" 2>/dev/null)
  # Persist session_id for --resume
  [ -n "$SESSION" ] && echo "$SESSION" > "$TASK_DIR/session_id"
  echo "SESSION: $SESSION"
  echo "ERROR: $IS_ERROR"
  echo "COST: \$$COST"
fi
