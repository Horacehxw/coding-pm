#!/bin/bash
# Automated tests for claw-pilot scripts.
# Usage: bash tests/test-scripts.sh
# Creates temp repos, runs scripts, checks results, cleans up.
# Does NOT require a real claude CLI (stubs it out).
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")/../scripts" && pwd)"
TESTS_PASSED=0
TESTS_FAILED=0
CLEANUP_TASKS=()

# --- Helpers ---

pass() { TESTS_PASSED=$((TESTS_PASSED + 1)); echo "  PASS: $1"; }
fail() { TESTS_FAILED=$((TESTS_FAILED + 1)); echo "  FAIL: $1" >&2; }

assert_eq() {
  local desc="$1" expected="$2" actual="$3"
  if [ "$expected" = "$actual" ]; then pass "$desc"
  else fail "$desc (expected '$expected', got '$actual')"; fi
}

assert_contains() {
  local desc="$1" haystack="$2" needle="$3"
  if echo "$haystack" | grep -qF "$needle"; then pass "$desc"
  else fail "$desc (expected to contain '$needle')"; fi
}

assert_file_exists() {
  local desc="$1" path="$2"
  if [ -f "$path" ]; then pass "$desc"
  else fail "$desc (file not found: $path)"; fi
}

assert_dir_not_exists() {
  local desc="$1" path="$2"
  if [ ! -d "$path" ]; then pass "$desc"
  else fail "$desc (dir still exists: $path)"; fi
}

# Create a temp git repo with an initial commit, optionally on a named branch
make_test_repo() {
  local dir="$1" branch="${2:-main}"
  mkdir -p "$dir"
  git -C "$dir" init -b main -q
  git -C "$dir" commit --allow-empty -m "init" -q
  if [ "$branch" != "main" ]; then
    git -C "$dir" checkout -b "$branch" -q
  fi
}

# Register a task name for cleanup at end
register_cleanup() {
  CLEANUP_TASKS+=("$1")
}

cleanup_all() {
  for name in "${CLEANUP_TASKS[@]}"; do
    local td="$HOME/.openclaw/supervisor/tasks/$name"
    local wt="$HOME/.worktrees/$name"
    if [ -d "$wt" ]; then
      # Find parent repo and remove worktree properly
      local parent
      parent=$(cd "$wt" && git rev-parse --git-common-dir 2>/dev/null | sed 's|/\.git$||') || true
      if [ -n "$parent" ] && [ -d "$parent" ]; then
        git -C "$parent" worktree remove "$wt" --force 2>/dev/null || rm -rf "$wt"
      else
        rm -rf "$wt"
      fi
    fi
    rm -rf "$td"
  done
  rm -rf /tmp/claw-test-*
  # Remove fake claude from PATH
  rm -f /tmp/claw-test-bin/claude
  rmdir /tmp/claw-test-bin 2>/dev/null || true
}
trap cleanup_all EXIT

# --- Fake claude CLI ---
setup_fake_claude() {
  mkdir -p /tmp/claw-test-bin
  cat > /tmp/claw-test-bin/claude <<'FAKECLAUDE'
#!/bin/bash
# Fake claude: writes a valid output.json and exits
# Parse --output-format to know if json requested
OUTPUT_FORMAT="text"
SESSION_ID="fake-session-$(date +%s)"
for arg in "$@"; do
  case "$prev" in
    --output-format) OUTPUT_FORMAT="$arg" ;;
  esac
  prev="$arg"
done
if [ "$OUTPUT_FORMAT" = "json" ]; then
  echo '{"type":"result","subtype":"success","is_error":false,"result":"[PLAN_START]\nFake plan\n[PLAN_END]","session_id":"'"$SESSION_ID"'","total_cost_usd":0.01}'
else
  echo "[PLAN_START]"
  echo "Fake plan"
  echo "[PLAN_END]"
fi
FAKECLAUDE
  chmod +x /tmp/claw-test-bin/claude
  export PATH="/tmp/claw-test-bin:$PATH"
}

# ============================================================
# TEST: init-task.sh
# ============================================================
test_init_task() {
  echo "--- test_init_task ---"
  local repo="/tmp/claw-test-init"
  local name="test-$$-init"
  register_cleanup "$name"
  make_test_repo "$repo" "dev"

  # Run init
  local out
  out=$(bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "test request")

  # Check outputs
  assert_contains "init outputs TASK_DIR" "$out" "TASK_DIR="
  assert_contains "init outputs WORKTREE" "$out" "WORKTREE="
  assert_contains "init outputs BRANCH" "$out" "BRANCH=feat/$name"
  assert_contains "init outputs BASE_BRANCH" "$out" "BASE_BRANCH=dev"

  # Check task.json
  local td="$HOME/.openclaw/supervisor/tasks/$name"
  assert_file_exists "task.json created" "$td/task.json"
  assert_eq "task.json name" "$name" "$(jq -r '.name' "$td/task.json")"
  assert_eq "task.json base_branch" "dev" "$(jq -r '.base_branch' "$td/task.json")"
  assert_eq "task.json request no trailing newline" "test request" "$(jq -r '.request' "$td/task.json")"

  # Check status
  assert_eq "status is planning" "planning" "$(cat "$td/status")"

  # Check worktree exists
  local wt="$HOME/.worktrees/$name"
  assert_file_exists "progress.json created" "$wt/.supervisor/progress.json"

  # Check branch
  local branch
  branch=$(cd "$wt" && git symbolic-ref --short HEAD)
  assert_eq "worktree on feat branch" "feat/$name" "$branch"
}

# ============================================================
# TEST: init-task.sh rejects non-git dir
# ============================================================
test_init_rejects_non_git() {
  echo "--- test_init_rejects_non_git ---"
  local name="test-$$-nongit"
  if bash "$SCRIPT_DIR/init-task.sh" "/tmp" "$name" "test" 2>/dev/null; then
    fail "init should reject non-git dir"
  else
    pass "init rejects non-git dir"
  fi
}

# ============================================================
# TEST: init-task.sh rejects duplicate
# ============================================================
test_init_rejects_duplicate() {
  echo "--- test_init_rejects_duplicate ---"
  local repo="/tmp/claw-test-dup"
  local name="test-$$-dup"
  register_cleanup "$name"
  make_test_repo "$repo"

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "first" > /dev/null
  if bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "second" 2>/dev/null; then
    fail "init should reject duplicate task"
  else
    pass "init rejects duplicate task"
  fi
}

# ============================================================
# TEST: init-task.sh --force overwrites
# ============================================================
test_init_force() {
  echo "--- test_init_force ---"
  local repo="/tmp/claw-test-force"
  local name="test-$$-force"
  register_cleanup "$name"
  make_test_repo "$repo"

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "first" > /dev/null
  local out
  out=$(bash "$SCRIPT_DIR/init-task.sh" --force "$repo" "$name" "second" 2>&1)
  assert_contains "force shows warning" "$out" "WARN"

  local td="$HOME/.openclaw/supervisor/tasks/$name"
  assert_eq "request updated" "second" "$(jq -r '.request' "$td/task.json")"
}

# ============================================================
# TEST: start-cc.sh (with fake claude)
# ============================================================
test_start_cc() {
  echo "--- test_start_cc ---"
  local repo="/tmp/claw-test-startcc"
  local name="test-$$-startcc"
  register_cleanup "$name"
  make_test_repo "$repo"
  setup_fake_claude

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "test" > /dev/null

  local td="$HOME/.openclaw/supervisor/tasks/$name"
  local wt="$HOME/.worktrees/$name"

  # Note: start-cc.sh does sleep 2 + kill -0, fake claude exits instantly
  # so the process check will fail. We test what we can:
  # just verify the script runs and writes output.json
  local out
  out=$(bash "$SCRIPT_DIR/start-cc.sh" "$td" "test prompt" "$wt" plan 2>&1) || true

  # Even if process died, output.json should have been written by fake claude
  assert_file_exists "output.json written" "$td/output.json"
}

# ============================================================
# TEST: check-cc.sh
# ============================================================
test_check_cc() {
  echo "--- test_check_cc ---"
  local repo="/tmp/claw-test-checkcc"
  local name="test-$$-checkcc"
  register_cleanup "$name"
  make_test_repo "$repo" "dev"

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "test" > /dev/null

  local td="$HOME/.openclaw/supervisor/tasks/$name"
  local wt="$HOME/.worktrees/$name"

  # Simulate CC having finished: write a fake output.json
  echo '{"is_error":false,"session_id":"fake-123","total_cost_usd":0.05}' > "$td/output.json"

  # Make a commit in worktree to test git tracking
  echo "hello" > "$wt/test.txt"
  (cd "$wt" && git add test.txt && git commit -m "test commit" -q)

  local out
  out=$(bash "$SCRIPT_DIR/check-cc.sh" "$td")

  assert_contains "check shows finished" "$out" "STATUS: finished"
  assert_contains "check shows commits" "$out" "COMMITS: 1"
  assert_contains "check shows session" "$out" "SESSION: fake-123"
  assert_contains "check shows cost" "$out" "COST:"

  # Verify session_id persisted
  assert_eq "session_id persisted" "fake-123" "$(cat "$td/session_id")"
}

# ============================================================
# TEST: merge-task.sh (clean merge)
# ============================================================
test_merge_clean() {
  echo "--- test_merge_clean ---"
  local repo="/tmp/claw-test-merge"
  local name="test-$$-merge"
  register_cleanup "$name"
  make_test_repo "$repo" "dev"

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "test" > /dev/null

  local wt="$HOME/.worktrees/$name"

  # Add a file on the feature branch
  echo "feature" > "$wt/feature.txt"
  (cd "$wt" && git add feature.txt && git commit -m "feat: add feature" -q)

  # Switch back to base branch and merge
  git -C "$repo" checkout dev -q
  local out
  out=$(bash "$SCRIPT_DIR/merge-task.sh" "$name" "$repo")

  assert_contains "merge succeeds" "$out" "MERGED: clean (into dev)"
  assert_file_exists "feature.txt on dev" "$repo/feature.txt"
}

# ============================================================
# TEST: merge-task.sh rejects wrong branch
# ============================================================
test_merge_wrong_branch() {
  echo "--- test_merge_wrong_branch ---"
  local repo="/tmp/claw-test-mergewrong"
  local name="test-$$-mergewrong"
  register_cleanup "$name"
  make_test_repo "$repo" "dev"

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "test" > /dev/null

  # Stay on main instead of dev
  git -C "$repo" checkout main -q
  if bash "$SCRIPT_DIR/merge-task.sh" "$name" "$repo" 2>/dev/null; then
    fail "merge should reject wrong branch"
  else
    pass "merge rejects wrong branch"
  fi
}

# ============================================================
# TEST: merge-task.sh conflict -> abort
# ============================================================
test_merge_conflict() {
  echo "--- test_merge_conflict ---"
  local repo="/tmp/claw-test-conflict"
  local name="test-$$-conflict"
  register_cleanup "$name"
  make_test_repo "$repo" "dev"

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "test" > /dev/null

  local wt="$HOME/.worktrees/$name"

  # Create conflicting changes
  echo "feature version" > "$wt/conflict.txt"
  (cd "$wt" && git add conflict.txt && git commit -m "feat: add conflict" -q)
  echo "dev version" > "$repo/conflict.txt"
  (cd "$repo" && git add conflict.txt && git commit -m "dev: add conflict" -q)

  if bash "$SCRIPT_DIR/merge-task.sh" "$name" "$repo" 2>/dev/null; then
    fail "merge should detect conflict"
  else
    pass "merge detects conflict and aborts"
    # Verify repo is clean (merge was aborted)
    local status
    status=$(cd "$repo" && git status --porcelain)
    assert_eq "repo clean after abort" "" "$status"
  fi
}

# ============================================================
# TEST: cleanup-task.sh
# ============================================================
test_cleanup() {
  echo "--- test_cleanup ---"
  local repo="/tmp/claw-test-cleanup"
  local name="test-$$-cleanup"
  register_cleanup "$name"
  make_test_repo "$repo"

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "test" > /dev/null

  local td="$HOME/.openclaw/supervisor/tasks/$name"
  local wt="$HOME/.worktrees/$name"

  # Write fake ephemeral files
  echo "fake-pid" > "$td/cc.pid"
  echo "fake-session" > "$td/session_id"
  echo '{}' > "$td/output.json"

  bash "$SCRIPT_DIR/cleanup-task.sh" "$name" > /dev/null

  assert_dir_not_exists "worktree removed" "$wt"
  assert_eq "status is cleaned" "cleaned" "$(cat "$td/status")"
  assert_file_exists "task.json preserved" "$td/task.json"

  # Verify branch deleted
  if git -C "$repo" rev-parse --verify "feat/$name" 2>/dev/null; then
    fail "feature branch should be deleted"
  else
    pass "feature branch deleted"
  fi
}

# ============================================================
# TEST: list-tasks.sh
# ============================================================
test_list_tasks() {
  echo "--- test_list_tasks ---"
  local repo="/tmp/claw-test-list"
  local name="test-$$-list"
  register_cleanup "$name"
  make_test_repo "$repo"

  bash "$SCRIPT_DIR/init-task.sh" "$repo" "$name" "test" > /dev/null

  local out
  out=$(bash "$SCRIPT_DIR/list-tasks.sh")

  assert_contains "list shows task" "$out" "$name"
  assert_contains "list shows status" "$out" "STATUS: planning"
}

# ============================================================
# RUN ALL TESTS
# ============================================================
echo "=== claw-pilot script tests ==="
echo ""

test_init_task
test_init_rejects_non_git
test_init_rejects_duplicate
test_init_force
test_start_cc
test_check_cc
test_merge_clean
test_merge_wrong_branch
test_merge_conflict
test_cleanup
test_list_tasks

echo ""
echo "=== Results: $TESTS_PASSED passed, $TESTS_FAILED failed ==="
[ "$TESTS_FAILED" -eq 0 ] || exit 1
