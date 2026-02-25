# claw-pilot

> PM/QA skill for [OpenClaw](https://github.com/openclaw/openclaw) that manages [Claude Code](https://docs.anthropic.com/en/docs/claude-code) as a background engineer.

```
You (IM)  →  OpenClaw Agent (PM/QA)  →  Claude Code (Engineer, background)
```

Your OpenClaw agent becomes a project manager: it sends tasks to Claude Code, reviews plans, monitors progress, runs validation, and reports back — all without blocking your chat.

## Features

- **Plan → Approve → Execute → Validate** workflow
- **Non-blocking**: CC runs in background, agent stays responsive
- **Git worktree isolation**: each task gets its own branch and worktree
- **Dual progress tracking**: git commits (deterministic) + progress.json (real-time)
- **Human-in-the-loop**: agent escalates decisions, errors, and merge conflicts
- **Zero JS**: pure SKILL.md instructions + shell scripts

## Quick Start

### Prerequisites

- [OpenClaw](https://github.com/openclaw/openclaw) installed and configured
- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) CLI authenticated (`claude auth status`)
- `jq` installed (`sudo apt install jq`)
- `git` installed

### Install

```bash
# From ClawdHub
clawdhub install claw-pilot

# Or manually
cd ~/.openclaw/workspace/skills/
git clone https://github.com/horacehxw/claw-pilot.git
```

### Setup

```bash
# Create runtime directory (not in skill repo)
mkdir -p ~/.openclaw/supervisor/tasks

# Allow agent to access files outside workspace
openclaw config set tools.fs.workspaceOnly false
openclaw gateway restart

# Make scripts executable
chmod +x ~/.openclaw/workspace/skills/claw-pilot/scripts/*.sh
```

### Usage

In your IM (Feishu/Slack/etc.):

```
/dev Add JWT support to the auth module
```

The agent will:
1. Create a plan via CC → present for your approval
2. Execute the plan in a git worktree → monitor progress
3. Run tests + generate diff → report results
4. Merge on your approval → clean up

Other commands:

```
/task list              — Show all tasks
/task status jwt-auth   — Show task details
/task cancel jwt-auth   — Kill and clean up
/task approve jwt-auth  — Approve pending plan
```

## Architecture

```
claw-pilot/                          # Skill source (this repo)
├── SKILL.md                         # Agent instructions
├── scripts/                         # Shell scripts
└── templates/CLAUDE.md.tpl          # Injected into worktrees

~/.openclaw/supervisor/tasks/        # Runtime data (ephemeral)
└── jwt-auth/
    ├── task.json, output.json, cc.pid, session_id, status

~/.worktrees/jwt-auth/               # Git worktree (temporary)
├── .supervisor/progress.json        # CC writes progress here
├── CLAUDE.md                        # Supervisor Protocol
└── ...project files...
```

Three-layer separation: source code / runtime data / work trees — each with its own lifecycle.

## How It Works

**Output format**: `--output-format json` produces ~1KB clean JSON per CC invocation. No need for `stream-json --verbose` (which produces 50KB+ of noise per call).

**Progress tracking**: Two independent tracks that cross-validate:
- **Track A — Git commits**: CC commits after each sub-task. `git log main..HEAD` = deterministic progress.
- **Track B — progress.json**: CC writes `{"step": N, "total": T, "current": "...", "done": false}` after each step.

**Background execution**: `setsid claude ... < /dev/null > output.json 2>&1 &` — detaches CC from terminal while keeping stdin readable.

## Requirements

| Component | Version |
|-----------|---------|
| OpenClaw | 2026.2.19+ |
| Claude Code | 2.1.0+ |
| Node.js | 22+ |
| jq | any |
| git | 2.20+ (worktree support) |

## Configuration

The skill requires `tools.fs.workspaceOnly = false` because runtime data lives outside the workspace directory. Security is enforced by `exec-approvals.json` (command allowlist) and the Supervisor Protocol in CLAUDE.md.

## Roadmap

- [x] v0.1 — Core flow: plan → approve → execute → report
- [ ] v0.2 — Multi-task parallel + /task commands
- [ ] v0.3 — Auto-test + diff + merge with CC conflict resolution
- [ ] v0.4 — Optional stream-json for long tasks
- [ ] v0.5 — CI/CD: tag → auto publish ClawdHub
- [ ] v1.0 — Stable API

## License

[MIT](LICENSE)
