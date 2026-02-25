#!/bin/bash
# Usage: init-task.sh <project-dir> <task-name> [request]
# Creates task data dir, git worktree, feature branch, and progress tracking.
set -e

PROJECT_DIR="$1"
TASK_NAME="$2"
REQUEST="$3"
TASK_DIR="$HOME/.openclaw/supervisor/tasks/$TASK_NAME"
WORKTREE="$HOME/.worktrees/$TASK_NAME"

# Validate inputs
if [ -z "$PROJECT_DIR" ] || [ -z "$TASK_NAME" ]; then
  echo "Usage: init-task.sh <project-dir> <task-name> [request]" >&2
  exit 1
fi

# Pre-validation: PROJECT_DIR must be a git repo
if ! git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR: '$PROJECT_DIR' is not a git repository" >&2
  exit 1
fi

# Pre-validation: task must not already exist
if [ -d "$TASK_DIR" ]; then
  echo "ERROR: Task '$TASK_NAME' already exists at $TASK_DIR" >&2
  exit 1
fi

# Pre-validation: worktree must not already exist (leftover from previous run)
if [ -d "$WORKTREE" ]; then
  echo "ERROR: Worktree '$WORKTREE' already exists (leftover from previous task?)" >&2
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

# Generate task.json
cat > "$TASK_DIR/task.json" <<EOF
{"name": "$TASK_NAME", "request": $(echo "$REQUEST" | jq -Rs .), "project": "$PROJECT_DIR", "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF

# Record paths
echo "$WORKTREE" > "$TASK_DIR/worktree"
echo "planning" > "$TASK_DIR/status"

echo "TASK_DIR=$TASK_DIR"
echo "WORKTREE=$WORKTREE"
echo "BRANCH=feat/$TASK_NAME"
