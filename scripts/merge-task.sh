#!/bin/bash
# Usage: merge-task.sh <task-name> <project-dir>
# Merges feat/<task-name> into current branch (main).
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

if git merge "$BRANCH" 2>&1; then
  echo "MERGED: clean"
else
  echo "CONFLICT: merge conflict detected"
  exit 1
fi
