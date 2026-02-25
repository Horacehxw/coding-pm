#!/bin/bash
# Usage: init-task.sh [--force] <project-dir> <task-name> [request]
# Creates task data dir, git worktree, feature branch, and progress tracking.
set -e

# Handle --force flag
FORCE=false
if [ "$1" = "--force" ]; then
  FORCE=true
  shift
fi

PROJECT_DIR="$1"
TASK_NAME="$2"
REQUEST="$3"
TASK_DIR="$HOME/.openclaw/supervisor/tasks/$TASK_NAME"
WORKTREE="$HOME/.worktrees/$TASK_NAME"

# Validate inputs
if [ -z "$PROJECT_DIR" ] || [ -z "$TASK_NAME" ]; then
  echo "Usage: init-task.sh [--force] <project-dir> <task-name> [request]" >&2
  exit 1
fi

# Pre-validation: PROJECT_DIR must be a git repo
if ! git -C "$PROJECT_DIR" rev-parse --git-dir > /dev/null 2>&1; then
  echo "ERROR: '$PROJECT_DIR' is not a git repository" >&2
  exit 1
fi

# Detect current branch as base branch for later merge
BASE_BRANCH=$(git -C "$PROJECT_DIR" symbolic-ref --short HEAD 2>/dev/null || echo "main")

# Pre-validation: task must not already exist (unless --force)
if [ -d "$TASK_DIR" ]; then
  if [ "$FORCE" = true ]; then
    echo "WARN: Removing existing task dir $TASK_DIR (--force)" >&2
    rm -rf "$TASK_DIR"
  else
    echo "ERROR: Task '$TASK_NAME' already exists at $TASK_DIR" >&2
    exit 1
  fi
fi

# Pre-validation: worktree must not already exist (unless --force)
if [ -d "$WORKTREE" ]; then
  if [ "$FORCE" = true ]; then
    echo "WARN: Removing existing worktree $WORKTREE (--force)" >&2
    git -C "$PROJECT_DIR" worktree remove "$WORKTREE" --force 2>/dev/null || rm -rf "$WORKTREE"
    git -C "$PROJECT_DIR" branch -D "feat/$TASK_NAME" 2>/dev/null || true
  else
    echo "ERROR: Worktree '$WORKTREE' already exists (leftover from previous task?)" >&2
    exit 1
  fi
fi

# Create task data directory
mkdir -p "$TASK_DIR"

# Create worktree + branch
git -C "$PROJECT_DIR" worktree add "$WORKTREE" -b "feat/$TASK_NAME" "$BASE_BRANCH" 2>&1

# Create progress tracking dir in worktree
mkdir -p "$WORKTREE/.supervisor"
echo '{"step": 0, "total": 0, "current": "initializing", "done": false}' \
  > "$WORKTREE/.supervisor/progress.json"

# Generate task.json
cat > "$TASK_DIR/task.json" <<EOF
{"name": "$TASK_NAME", "request": $(printf '%s' "$REQUEST" | jq -Rs .), "project": "$PROJECT_DIR", "base_branch": "$BASE_BRANCH", "created": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"}
EOF

# Record paths
echo "$WORKTREE" > "$TASK_DIR/worktree"
echo "planning" > "$TASK_DIR/status"

echo "TASK_DIR=$TASK_DIR"
echo "WORKTREE=$WORKTREE"
echo "BRANCH=feat/$TASK_NAME"
echo "BASE_BRANCH=$BASE_BRANCH"
