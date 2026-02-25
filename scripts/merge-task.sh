#!/bin/bash
# Usage: merge-task.sh <task-name> <project-dir>
# Merges feat/<task-name> into main.
# Exit 0 = clean merge. Exit 1 = conflict (caller should start CC to resolve).
set -e

TASK_NAME="$1"
PROJECT_DIR="$2"
BRANCH="feat/$TASK_NAME"

if [ -z "$TASK_NAME" ] || [ -z "$PROJECT_DIR" ]; then
  echo "Usage: merge-task.sh <task-name> <project-dir>" >&2
  exit 1
fi

cd "$PROJECT_DIR"

# Verify we are on main
CURRENT_BRANCH=$(git symbolic-ref --short HEAD 2>/dev/null)
if [ "$CURRENT_BRANCH" != "main" ]; then
  echo "ERROR: Must be on 'main' branch to merge (currently on '$CURRENT_BRANCH')" >&2
  exit 1
fi

# Verify feature branch exists
if ! git rev-parse --verify "$BRANCH" > /dev/null 2>&1; then
  echo "ERROR: Branch '$BRANCH' does not exist" >&2
  exit 1
fi

if git merge "$BRANCH" 2>&1; then
  echo "MERGED: clean"
else
  echo "CONFLICT: merge conflict detected, aborting merge"
  git merge --abort
  exit 1
fi
