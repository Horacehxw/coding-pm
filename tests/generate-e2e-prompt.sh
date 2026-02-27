#!/usr/bin/env bash
# Generate a structured e2e test prompt for OpenClaw testing
# Usage: bash tests/generate-e2e-prompt.sh [project-type]
# project-type: "todo" (default, fast) or "holdem" (comprehensive, slow)

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_MD="$PROJECT_DIR/SKILL.md"

VERSION=$(grep '^version:' "$SKILL_MD" | head -1 | sed 's/version: *//')
PROJECT_TYPE="${1:-todo}"

cat <<HEADER
╔══════════════════════════════════════════════════════╗
║  coding-pm e2e test — v${VERSION}
║  Generated: $(date '+%Y-%m-%d %H:%M')
║  Project type: ${PROJECT_TYPE}
╚══════════════════════════════════════════════════════╝

HEADER

# --- Step 1: Setup test project ---
cat <<'SETUP'
━━━ Step 1: Create test project ━━━

Run in terminal:

  mkdir -p /tmp/coding-pm-e2e-test && cd /tmp/coding-pm-e2e-test
  git init && echo '{}' > package.json && git add . && git commit -m "init"

SETUP

# --- Step 2: Dev command ---
echo "━━━ Step 2: Send to OpenClaw ━━━"
echo ""

if [ "$PROJECT_TYPE" = "holdem" ]; then
    cat <<'HOLDEM'
Paste in IM:

  /dev "Build a Texas Holdem poker game for 2-8 players with a web GUI.
  Use HTML/CSS/JS with a Node.js backend. Include game logic (dealing,
  betting rounds, hand evaluation), a responsive web interface showing
  player hands and community cards, and WebSocket-based multiplayer.
  Include unit tests with Jest."

  Project: /tmp/coding-pm-e2e-test

HOLDEM
else
    cat <<'TODO'
Paste in IM:

  /dev "Build a CLI todo app in Node.js. Commands: add <text>, list,
  complete <id>, delete <id>. Store todos in a JSON file (todos.json).
  Include unit tests with Jest. Add a --help flag."

  Project: /tmp/coding-pm-e2e-test

TODO
fi

# --- Step 3: Verification checklist ---
cat <<CHECKLIST
━━━ Step 3: Verify each phase ━━━

Phase 1 — Preprocessing:
  □ PM reports "Task started, coding-agent is researching..."
  □ Worktree exists: ls ~/.worktrees/  (should see task dir)
  □ Feature branch created: git -C /tmp/coding-pm-e2e-test branch

Phase 2 — Plan Review:
  □ PM presents a numbered plan summary (not raw agent output)
  □ Plan includes test strategy
  □ PM waited for your approval before execution

Phase 3 — Execution Monitoring:
  □ PM sends checkpoint updates during execution
  □ No dangerous pattern alerts (unless the plan has risky operations)
  □ If [DECISION_NEEDED]: PM forwarded question to you

Phase 4 — Acceptance Testing:
  □ PM reports test results (pass/fail)
  □ PM shows diff stat summary
  □ If tests failed: PM sent failures to coding-agent for fixing

Phase 5 — Merge & Cleanup:
  □ After you reply "done": code merged to main branch
  □ Worktree removed: ls ~/.worktrees/  (task dir gone)
  □ Feature branch deleted: git -C /tmp/coding-pm-e2e-test branch

CHECKLIST

# --- Step 4: Functional verification ---
echo "━━━ Step 4: Functional verification ━━━"
echo ""

if [ "$PROJECT_TYPE" = "holdem" ]; then
    cat <<'HOLDEM_VERIFY'
  cd /tmp/coding-pm-e2e-test
  npm install && npm test          # unit tests pass
  npm start &                      # start server
  open http://localhost:3000       # UI renders
  # Verify: cards visible, can join game, betting works
  kill %1

HOLDEM_VERIFY
else
    cat <<'TODO_VERIFY'
  cd /tmp/coding-pm-e2e-test
  npm install && npm test          # unit tests pass
  node cli.js add "Buy milk"      # add a todo
  node cli.js add "Walk the dog"  # add another
  node cli.js list                # both visible
  node cli.js complete 1          # mark first done
  node cli.js delete 2            # delete second
  node cli.js list                # only completed #1 remains
  node cli.js --help              # help text shown

TODO_VERIFY
fi

# --- Step 5: Cleanup ---
cat <<'CLEANUP'

━━━ Step 5: Cleanup ━━━

  rm -rf /tmp/coding-pm-e2e-test

CLEANUP

echo "━━━ Test complete ━━━"
