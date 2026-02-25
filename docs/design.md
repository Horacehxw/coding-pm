# Design

> Architecture and rationale for claw-pilot.

## Problem

You want Claude Code (CC) to do development work, but:
- CC runs 5-10 minutes per task → blocks your chat if run synchronously
- You need to review plans before execution
- You want progress updates without babysitting
- Multiple tasks should run in parallel

## Solution

OpenClaw agent acts as PM/QA. CC runs in background. Communication via files.

```
User (IM) → OpenClaw Agent (PM/QA) → Claude Code (background)
                │                          │
                │  reads progress.json     │  writes progress.json
                │  reads git log           │  commits per sub-task
                │  reads output.json       │  writes output.json (on finish)
                │                          │
                └── reports to user ◄──────┘
```

## Why JSON Mode (not stream-json)

CC's `--output-format stream-json` requires `--verbose`, which dumps ~16KB of internal state per call (hooks, tools, plugins). A simple "2+2" produces 6 JSON events. Real tasks → 50KB-1MB+.

PM needs exactly 2 things: CC's answer text + session_id. JSON mode gives both in ~1KB.

Progress comes from **two independent tracks**, not from parsing output:

| Track | Source | What it tells you | Reliability |
|-------|--------|-------------------|-------------|
| A: Git commits | `git log main..HEAD` | Sub-tasks completed | Deterministic fact |
| B: progress.json | CC writes to `.supervisor/progress.json` | Current step, total, description | Depends on CC compliance |

They cross-validate: progress says step 3, git has 2 commits → normal (step 3 in progress). Progress says step 5, git has 1 commit → CC skipping commits.

## Why setsid (not nohup, not tmux)

CC needs a readable stdin to start. `nohup` closes stdin → CC silently exits.

| Method | Result | Reason |
|--------|--------|--------|
| `nohup claude ... &` | ❌ Empty output | stdin closed, CC exits |
| `script -qc '...'` | ❌ Process stopped | No controlling terminal |
| `setsid ... < /dev/null` | ✅ | New session + readable stdin (EOF) |
| `tmux new-session -d` | ✅ | Full PTY (overkill for our needs) |

setsid: zero dependencies, one line, exec-friendly. tmux reserved as fallback.

## Three-Layer File Separation

Source code, runtime data, and work trees have different lifecycles:

| Layer | Location | Lifecycle | In git? |
|-------|----------|-----------|---------|
| Source | `~/.openclaw/workspace/skills/claw-pilot/` | Permanent, versioned | Yes (this repo) |
| Runtime | `~/.openclaw/supervisor/tasks/{name}/` | Per-task, ephemeral | No |
| Worktree | `~/.worktrees/{name}/` | Per-task, cleaned up | No (project's git) |

This keeps the skill repo publishable as-is (no .gitignore gymnastics for runtime data).

## Security Model

`tools.fs.workspaceOnly = false` is required (scripts access project dirs + runtime data). Actual security layers:

1. **exec-approvals.json** — Command allowlist, `askFallback = deny`
2. **Supervisor Protocol** — CLAUDE.md.tpl rules (backup before delete, needs_decision before deploy)
3. **Agent oversight** — PM reads output.json, detects dangerous patterns, alerts user
4. **OpenClaw defaults** — `tools.deny: [sessions_spawn, sessions_send]`, `elevated.enabled: false`

## Workflow

```
/dev <request>
  → init-task.sh (worktree + branch + inject Protocol)
  → start-cc.sh (background CC, plan mode)
  → [user approves plan]
  → start-cc.sh (background CC, bypass mode, --resume)
  → check-cc.sh (poll progress.json + git log)
  → [CC done] → agent runs tests + diff
  → [user approves] → merge-task.sh → cleanup-task.sh
```

## Upgrade Path

```
v0.1: JSON mode + git + progress.json (current)
v0.2: Multi-task + segmented execution (PM sends steps one by one)
v0.4: Optional stream-json --verbose + filter script (if needed)
```