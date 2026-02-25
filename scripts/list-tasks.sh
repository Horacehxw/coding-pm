#!/bin/bash
# Usage: list-tasks.sh
# Lists all tasks under ~/.openclaw/supervisor/tasks/ with status and progress.
set -e

TASKS_DIR="$HOME/.openclaw/supervisor/tasks"

# Validate tasks directory exists
if [ ! -d "$TASKS_DIR" ]; then
  echo "No tasks directory found at $TASKS_DIR" >&2
  exit 0
fi

task_count=0

for task_dir in "$TASKS_DIR"/*/; do
  [ -d "$task_dir" ] || continue

  task_name="$(basename "$task_dir")"

  # Read status (default: unknown)
  if [ -f "$task_dir/status" ]; then
    status="$(cat "$task_dir/status")"
  else
    status="unknown"
  fi

  # Read progress from worktree's .supervisor/progress.json
  progress="n/a"
  if [ -f "$task_dir/worktree" ]; then
    worktree="$(cat "$task_dir/worktree")"
    progress_file="$worktree/.supervisor/progress.json"
    if [ -f "$progress_file" ]; then
      step=$(jq -r '.step // 0' "$progress_file" 2>/dev/null) || step=""
      total=$(jq -r '.total // 0' "$progress_file" 2>/dev/null) || total=""
      current=$(jq -r '.current // ""' "$progress_file" 2>/dev/null) || current=""
      done_flag=$(jq -r '.done // false' "$progress_file" 2>/dev/null) || done_flag=""

      if [ -n "$step" ] && [ -n "$total" ]; then
        progress="step ${step}/${total}"
        [ -n "$current" ] && progress="$progress — $current"
        [ "$done_flag" = "true" ] && progress="$progress (done)"
      fi
    fi
  fi

  # Check if CC process is running
  run_indicator=""
  if [ -f "$task_dir/cc.pid" ]; then
    pid="$(cat "$task_dir/cc.pid")"
    if kill -0 "$pid" 2>/dev/null; then
      run_indicator=" (running)"
    fi
  fi

  echo "TASK: $task_name | STATUS: $status | PROGRESS: ${progress}${run_indicator}"
  task_count=$((task_count + 1))
done

if [ "$task_count" -eq 0 ]; then
  echo "No tasks found."
fi
