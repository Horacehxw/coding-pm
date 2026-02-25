# coding-pm

[English](README.md) | [中文](README_zh.md)

[![GitHub release](https://img.shields.io/github/v/release/horacehxw/coding-pm?include_prereleases&style=for-the-badge)](https://github.com/horacehxw/coding-pm/releases)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-8A2BE2?style=for-the-badge)](https://github.com/openclaw/openclaw)

> PM/QA skill for [OpenClaw](https://github.com/openclaw/openclaw) that manages coding agents as background engineers. Complements [coding-agent](https://github.com/openclaw/openclaw): agent executes, PM manages.

**PM** (Project Manager) ensures requirements are covered, process is followed, and results meet quality standards. **QA** (Quality Assurance) validates deliverables through automated tests, functional checks, and visual inspection. coding-pm plays both roles — managing the coding-agent's work from plan to merge, so you don't have to.

```
You (IM)  →  coding-pm (PM/QA)  →  coding-agent (Engineer, background)
```

## Features

- **5-phase workflow**: preprocessing → plan review → execution monitoring → acceptance testing → merge & cleanup
- **Non-blocking**: coding-agent runs in background, your chat stays responsive
- **PM manages people, not tech**: reviews requirements coverage, process compliance, and result quality — coding-agent owns all technical decisions
- **Active monitoring**: polls every 30-60s, parses structured markers, pushes progress to you
- **3-layer acceptance testing**: automated tests + functional integration + screenshot analysis
- **Git worktree isolation**: each task gets its own branch and worktree
- **Concurrency**: multiple tasks run simultaneously with independent isolation
- **Multi-agent support**: Claude Code, Codex, OpenCode, Pi
- **Human-in-the-loop**: plan approval gate, decision escalation, error retry (up to 3 rounds)
- **Task lifecycle**: pause, resume, cancel — full control over background tasks
- **Pure SKILL.md**: zero scripts, uses OpenClaw platform tools

## Quick Start

### Prerequisites

- [OpenClaw](https://github.com/openclaw/openclaw) installed and configured
- At least one coding agent CLI:
  - [Claude Code](https://docs.anthropic.com/en/docs/claude-code) (`claude auth status`)
  - [Codex](https://github.com/openai/codex) / [OpenCode](https://github.com/opencode-ai/opencode) / [Pi](https://github.com/anthropics/pi)
- `git` installed

### Install

```bash
# From ClawdHub
clawdhub install coding-pm

# Or manually
cd ~/.openclaw/workspace/skills/
git clone https://github.com/horacehxw/coding-pm.git
```

### Setup

```bash
# Allow agent to access files outside workspace (for worktrees)
openclaw config set tools.fs.workspaceOnly false
openclaw gateway restart
```

### Usage

In your IM (Feishu/Slack/etc.):

```
/dev Add JWT support to the auth module
```

The agent will:
1. Explore project context and compose a structured prompt for coding-agent
2. Coding-agent researches and produces a plan → PM reviews → presents for your approval
3. Execute in a git worktree → active monitoring with progress updates
4. Run acceptance tests (automated + functional + visual) → report results
5. Merge on your approval → clean up

Task commands:

```
/task list              — Show all tasks with phase and status
/task status jwt-auth   — Show task details and recent checkpoints
/task cancel jwt-auth   — Kill and clean up
/task approve jwt-auth  — Approve pending plan
/task pause jwt-auth    — Pause task, preserve state
/task resume jwt-auth   — Resume paused task
/task progress jwt-auth — Show recent checkpoints
/task plan jwt-auth     — Show approved plan
```

## How coding-pm Differs from coding-agent

| | coding-agent | coding-pm |
|--|-------------|-----------|
| Role | Cookbook (teaches you how to use agents) | PM/QA (manages agents for you) |
| Plan review | None | PM reviews requirements + user approval gate |
| Monitoring | None | Active loop: markers, commits, anomaly detection |
| Test validation | None | 3-layer: automated + functional + visual |
| Reporting | Manual | Structured progress pushes per checkpoint |
| Error handling | User handles manually | Auto-retry (3 rounds) + smart escalation |
| Concurrency | Single task | Multiple independent tasks |
| Worktree | Manual management | Automatic create/merge/cleanup |

## Architecture

```
coding-pm/
  SKILL.md                          # PM brain — 5-phase workflow logic
  references/
    supervisor-prompt.md            # Injected into worktrees as CLAUDE.md
  CLAUDE.md                         # Developer guide
```

No custom scripts. Uses OpenClaw's built-in `bash` (pty/background/workdir) and `process` (poll/log/kill/list/write) tools.

## Requirements

| Component | Version |
|-----------|---------|
| OpenClaw | 2026.2.19+ |
| git | 2.20+ (worktree support) |
| Coding agent | Claude Code 2.1.0+ / Codex / OpenCode / Pi |

## License

[MIT](LICENSE)
