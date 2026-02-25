#!/bin/bash
# Usage: init-task.sh <project-dir> <task-name>
# Creates task data dir, git worktree, feature branch, and injects Supervisor Protocol.
set -e

PROJECT_DIR="$1"
TASK_NAME="$2"
TASK_DIR="$HOME/.openclaw/supervisor/tasks/$TASK_NAME"
WORKTREE="$HOME/.worktrees/$TASK_NAME"
SKILL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Validate inputs
if [ -z "$PROJECT_DIR" ] || [ -z "$TASK_NAME" ]; then
  echo "Usage: init-task.sh <project-dir> <task-name>" >&2
  exit 1
fi

if [ -d "$TASK_DIR" ]; then
  echo "ERROR: Task '$TASK_NAME' already exists at $TASK_DIR" >&2
  exit 1
fi

# Create task data directory
mkdir -p "$TASK_DIR"

# Create worktree + branch
git -C "$PROJECT_DIR" worktree add "$WORKTREE" -b "feat/$TASK_NAME" 2>&1

# Create progress tracking dir in worktree
mkdir -p "$WORKTREE/.supervisor"
echo '{"step": 0, "total": 0, "current": "initializing", "done": false}' \
  > "$WORKTREE/.supervisor/progress.json"

# Record paths
echo "$WORKTREE" > "$TASK_DIR/worktree"
echo "planning" > "$TASK_DIR/status"

# Inject CLAUDE.md Supervisor Protocol
TEMPLATE="$SKILL_DIR/templates/CLAUDE.md.tpl"
TARGET="$WORKTREE/CLAUDE.md"
if [ -f "$TARGET" ]; then
  echo -e "\n\n# --- Supervisor Protocol (auto-injected by claw-pilot, do not edit) ---\n" >> "$TARGET"
  cat "$TEMPLATE" >> "$TARGET"
else
  cp "$TEMPLATE" "$TARGET"
fi

echo "TASK_DIR=$TASK_DIR"
echo "WORKTREE=$WORKTREE"
echo "BRANCH=feat/$TASK_NAME"
