# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**claw-pilot** is an OpenClaw Skill that turns the OpenClaw agent into a PM/QA managing Claude Code (CC) as a background engineer. The agent sends tasks to CC, reviews plans, monitors progress, runs validation, and reports back through IM — all without blocking the chat session.

```
User (IM) → OpenClaw Agent (PM/QA, kimi-k2.5) → Claude Code (Engineer, background)
```

## Architecture

**Zero JS** — All logic lives in two layers:
- `SKILL.md` — Natural language instructions that the OpenClaw agent follows (the "PM manual"). This is the brain.
- `scripts/*.sh` — Shell scripts that SKILL.md calls. These are the hands.

**Script pipeline** (each script is a discrete step, called by the agent in sequence):
```
init-task.sh → start-cc.sh (plan) → [agent reviews] → start-cc.sh (bypass, --resume) → check-cc.sh (poll) → merge-task.sh → cleanup-task.sh
```

**Supervisor Protocol** (`templates/supervisor-protocol.md`) is injected as a system prompt via `--append-system-prompt`. It tells CC to write `progress.json` and follow safety/git rules. This is the contract between PM and Engineer.

**Three-layer file separation** — Different lifecycles, different locations:
- Source: this repo (`~/.openclaw/workspace/skills/claw-pilot/`)
- Runtime data: `~/.openclaw/supervisor/tasks/{name}/` — task.json, output.json, cc.pid, session_id, status
- Worktrees: `~/.worktrees/{name}/` — git worktree with `.supervisor/progress.json`

**Dual-track progress** — Git commits (deterministic ground truth) + progress.json (CC-written structured status). `check-cc.sh` reads both and the PM cross-validates them.

**Background execution** — `setsid claude ... < /dev/null` (not nohup, which closes stdin and causes CC to exit silently). See `docs/design.md` for rationale.

## Development Commands

```bash
# Run automated tests
bash tests/test-scripts.sh

# Test scripts manually
bash scripts/init-task.sh /path/to/project test-task "request text"
bash scripts/init-task.sh --force /path/to/project test-task "retry"  # overwrite existing
bash scripts/start-cc.sh ~/.openclaw/supervisor/tasks/test-task "What is 2+2?" /tmp plan
bash scripts/check-cc.sh ~/.openclaw/supervisor/tasks/test-task
bash scripts/merge-task.sh test-task /path/to/project
bash scripts/cleanup-task.sh test-task
bash scripts/list-tasks.sh

# Verify CC background execution works on this system
setsid claude -p "What is 2+2?" --output-format json < /dev/null > /tmp/test.json 2>&1 &
sleep 10 && cat /tmp/test.json

# Publish
clawdhub publish . --slug claw-pilot --name "Claw Pilot" --version X.Y.Z --changelog "..."
```

## Conventions

- **Commit format**: `type(scope): description` (feat/fix/refactor/test/docs/chore)
- **Branch strategy**: Direct to main for v0.x. Feature branches when needed.
- **Shell scripts**: `set -e`, validate inputs at top, English comments.
- **SKILL.md**: English instructions. Agent IM output follows user's language automatically.
- **Version tags**: SemVer `v0.1.0`, `v0.2.0`, etc. Every tag = GitHub + ClawdHub release.

## Requirements

- OpenClaw 2026.2.19+, Claude Code 2.1.0+, Node.js 22+, jq, git 2.20+
- `tools.fs.workspaceOnly = false` in OpenClaw config (scripts access paths outside workspace)
- Security: exec-approvals.json allowlist (from Starter Kit)
