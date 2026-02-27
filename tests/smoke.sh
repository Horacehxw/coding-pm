#!/usr/bin/env bash
# coding-pm smoke tests — run during development to catch regressions
# Usage: bash tests/smoke.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_MD="$PROJECT_DIR/SKILL.md"
SUPERVISOR_PROMPT="$PROJECT_DIR/references/supervisor-prompt.md"

PASS=0
FAIL=0

pass() { PASS=$((PASS + 1)); echo "  ✓ $1"; }
fail() { FAIL=$((FAIL + 1)); echo "  ✗ $1"; }

echo "=== coding-pm smoke tests ==="
echo ""

# --- Test 1: Unicode control characters ---
echo "[1/6] Unicode control characters"
UNICODE_HITS=$(python3 -c "
with open('$SKILL_MD', 'r') as f:
    content = f.read()
hits = []
for i, ch in enumerate(content):
    cp = ord(ch)
    if cp == 0x200D or (0x200B <= cp <= 0x200F) or (0x202A <= cp <= 0x202E) or cp == 0xFEFF:
        line = content[:i].count('\n') + 1
        hits.append(f'Line {line}: U+{cp:04X}')
print('\n'.join(hits))
" 2>&1)

if [ -z "$UNICODE_HITS" ]; then
    pass "No unicode control characters in SKILL.md"
else
    fail "Unicode control characters found:"
    echo "$UNICODE_HITS" | sed 's/^/      /'
fi

# --- Test 2: Version consistency ---
echo "[2/6] Version consistency"
SKILL_VERSION=$(grep '^version:' "$SKILL_MD" | head -1 | sed 's/version: *//')
LATEST_TAG=$(git -C "$PROJECT_DIR" tag --sort=-v:refname | head -1 | sed 's/^v//')

if [ -z "$LATEST_TAG" ]; then
    pass "No git tags yet — skipping version check"
elif [ "$SKILL_VERSION" = "$LATEST_TAG" ]; then
    pass "SKILL.md version ($SKILL_VERSION) matches latest tag (v$LATEST_TAG)"
else
    fail "SKILL.md version ($SKILL_VERSION) != latest tag (v$LATEST_TAG)"
fi

# --- Test 3: Supervisor prompt exists ---
echo "[3/6] Supervisor prompt"
if [ -f "$SUPERVISOR_PROMPT" ] && [ -s "$SUPERVISOR_PROMPT" ]; then
    pass "references/supervisor-prompt.md exists and is non-empty"
else
    fail "references/supervisor-prompt.md missing or empty"
fi

# --- Test 4: --output-format json discipline ---
echo "[4/6] --output-format json discipline"
# Planning commands (Phase 1-2) SHOULD have --output-format json
# Execution/fix commands (Phase 3-4) SHOULD NOT

# Extract planning phase commands (between Phase 1 and Phase 3 headers)
PLAN_SECTION=$(sed -n '/^## Phase 1:/,/^## Phase 3:/p' "$SKILL_MD")
EXEC_SECTION=$(sed -n '/^## Phase 3:/,/^## Phase 5:/p' "$SKILL_MD")

PLAN_CLAUDE_CMDS=$(echo "$PLAN_SECTION" | grep -c 'claude -p' || true)
PLAN_JSON_FLAGS=$(echo "$PLAN_SECTION" | grep -c '\-\-output-format json' || true)
EXEC_CLAUDE_CMDS=$(echo "$EXEC_SECTION" | grep -c 'claude -p' || true)
EXEC_JSON_FLAGS=$(echo "$EXEC_SECTION" | grep -c '\-\-output-format json' || true)

JSON_OK=true
if [ "$PLAN_CLAUDE_CMDS" -gt 0 ] && [ "$PLAN_JSON_FLAGS" -ne "$PLAN_CLAUDE_CMDS" ]; then
    fail "Planning phase: $PLAN_JSON_FLAGS/$PLAN_CLAUDE_CMDS claude commands have --output-format json (all should)"
    JSON_OK=false
fi
if [ "$EXEC_JSON_FLAGS" -gt 0 ]; then
    fail "Execution/fix phase: $EXEC_JSON_FLAGS commands have --output-format json (none should)"
    JSON_OK=false
fi
if [ "$JSON_OK" = true ]; then
    pass "Planning commands use --output-format json; execution commands don't"
fi

# --- Test 5: Required files for ClawdHub ---
echo "[5/6] Required files"
MISSING=""
for f in SKILL.md README.md references/supervisor-prompt.md; do
    if [ ! -f "$PROJECT_DIR/$f" ]; then
        MISSING="$MISSING $f"
    fi
done

if [ -z "$MISSING" ]; then
    pass "All required files present (SKILL.md, README.md, references/supervisor-prompt.md)"
else
    fail "Missing files:$MISSING"
fi

# --- Test 6: Worktree lifecycle ---
echo "[6/6] Worktree lifecycle"
TEST_WORKTREE="$HOME/.worktrees/_smoke-test-$$"
TEST_BRANCH="feat/_smoke-test-$$"

WORKTREE_OK=true
git -C "$PROJECT_DIR" worktree add "$TEST_WORKTREE" -b "$TEST_BRANCH" >/dev/null 2>&1 || { fail "Failed to create worktree"; WORKTREE_OK=false; }

if [ "$WORKTREE_OK" = true ]; then
    if [ -d "$TEST_WORKTREE/.git" ] || [ -f "$TEST_WORKTREE/.git" ]; then
        git -C "$PROJECT_DIR" worktree remove "$TEST_WORKTREE" >/dev/null 2>&1
        git -C "$PROJECT_DIR" branch -D "$TEST_BRANCH" >/dev/null 2>&1
        pass "Worktree create/remove lifecycle works"
    else
        fail "Worktree created but .git not found"
        git -C "$PROJECT_DIR" worktree remove "$TEST_WORKTREE" >/dev/null 2>&1 || true
        git -C "$PROJECT_DIR" branch -D "$TEST_BRANCH" >/dev/null 2>&1 || true
    fi
fi

# --- Summary ---
echo ""
echo "=== Results: $PASS passed, $FAIL failed ==="
exit $FAIL
