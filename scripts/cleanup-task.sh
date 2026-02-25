#!/bin/bash
# Usage: cleanup-task.sh <task-name>
# Kills CC if running, removes worktree, cleans ephemeral files.
# Keeps task.json for history.

TASK_NAME="$1"
TASK_DIR="$HOME/.openclaw/supervisor/tasks/$TASK_NAME"

if [ -z "$TASK_NAME" ]; then
  echo "Usage: cleanup-task.sh <task-name>" >&2
  exit 1
fi

if [ ! -d "$TASK_DIR" ]; then
  echo "ERROR: Task '$TASK_NAME' not found" >&2
  exit 1
fi

WORKTREE=$(cat "$TASK_DIR/worktree" 2>/dev/null)

# Kill CC if still running
PID=$(cat "$TASK_DIR/cc.pid" 2>/dev/null)
if [ -n "$PID" ] && kill -0 "$PID" 2>/dev/null; then
  kill "$PID" 2>/dev/null || true
  echo "Killed CC process (PID: $PID)"
fi

# Remove worktree
if [ -n "$WORKTREE" ] && [ -d "$WORKTREE" ]; then
  # Find the parent repo from worktree
  PARENT_REPO=$(cd "$WORKTREE" && git rev-parse --git-common-dir 2>/dev/null | sed 's|/\.git$||')
  if [ -n "$PARENT_REPO" ]; then
    git -C "$PARENT_REPO" worktree remove "$WORKTREE" --force 2>/dev/null || true
  fi
  echo "Removed worktree: $WORKTREE"
fi

# Remove ephemeral files, keep task.json for history
rm -f "$TASK_DIR/output.json" "$TASK_DIR/cc.pid" "$TASK_DIR/worktree" "$TASK_DIR/session_id"
echo "cleaned" > "$TASK_DIR/status"

echo "Task $TASK_NAME cleaned up"
