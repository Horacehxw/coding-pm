#!/bin/bash
# Usage: merge-task.sh <task-name> <project-dir>
# Merges feat/<task-name> into the base branch recorded in task.json.
# Exit 0 = clean merge. Exit 1 = conflict (caller should start CC to resolve).
set -e

TASK_NAME="$1"
PROJECT_DIR="$2"
BRANCH="feat/$TASK_NAME"
TASK_DIR="$HOME/.openclaw/supervisor/tasks/$TASK_NAME"

if [ -z "$TASK_NAME" ] || [ -z "$PROJECT_DIR" ]; then
  echo "Usage: merge-task.sh <task-name> <project-dir>" >&2
  exit 1
fi

# Read base branch from task.json (default "main" for backward compat)
if [ -f "$TASK_DIR/task.json" ]; then
  BASE_BRANCH=$(jq -r '.base_branch // "main"' "$TASK_DIR/task.json" 2>/dev/null || echo "main")
else
  BASE_BRANCH="main"
fi

cd "$PROJECT_DIR"

# Verify we are on the base branch
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$CURRENT_BRANCH" != "$BASE_BRANCH" ]; then
  echo "ERROR: Must be on '$BASE_BRANCH' branch to merge (currently on '$CURRENT_BRANCH')" >&2
  exit 1
fi

# Verify feature branch exists
if ! git rev-parse --verify "$BRANCH" > /dev/null 2>&1; then
  echo "ERROR: Branch '$BRANCH' does not exist" >&2
  exit 1
fi

if git merge "$BRANCH" 2>&1; then
  echo "MERGED: clean (into $BASE_BRANCH)"
else
  echo "CONFLICT: merge conflict detected, aborting merge"
  git merge --abort
  exit 1
fi
