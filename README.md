# coding-pm

[![GitHub release](https://img.shields.io/github/v/release/horacehxw/coding-pm?include_prereleases&style=for-the-badge)](https://github.com/horacehxw/coding-pm/releases)
[![MIT License](https://img.shields.io/badge/License-MIT-blue.svg?style=for-the-badge)](LICENSE)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-8A2BE2?style=for-the-badge)](https://github.com/openclaw/openclaw)

> PM/QA skill for [OpenClaw](https://github.com/openclaw/openclaw) that manages coding agents as background engineers. Complements [coding-agent](https://github.com/openclaw/openclaw): agent executes, PM manages.

```
You (IM)  →  OpenClaw Agent (PM/QA)  →  Coding Agent (Engineer, background)
```

Your OpenClaw agent becomes a project manager: it sends tasks to coding agents, reviews plans, monitors progress, runs validation, and reports back — all without blocking your chat.

## Features

- **Plan → Approve → Execute → Validate → Merge** workflow
- **Non-blocking**: coding agent runs in background, agent stays responsive
- **Git worktree isolation**: each task gets its own branch and worktree
- **Multi-agent support**: Claude Code, Codex, OpenCode, Pi
- **Human-in-the-loop**: plan approval gate, decision escalation, error retry
- **Auto-test validation**: detects and runs project test suite
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
1. Create a plan via coding agent → present for your approval
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

## How coding-pm Differs from coding-agent

| | coding-agent | coding-pm |
|--|-------------|-----------|
| Role | Cookbook (teaches you how to use agents) | PM/QA (manages agents for you) |
| Plan review | None | Agent reviews + user approval gate |
| Test validation | None | Auto-detects and runs test suite |
| Reporting | Manual | Structured (tests/diff/cost) |
| Error handling | User handles manually | Auto-retry + smart escalation |
| Worktree | Manual management | Automatic create/merge/cleanup |

## Architecture

```
coding-pm/
  SKILL.md                          # PM brain — all workflow logic
  references/
    supervisor-prompt.md            # Injected into worktrees as CLAUDE.md
  CLAUDE.md                         # Developer guide
```

No custom scripts. Uses OpenClaw's built-in `bash` (pty/background/workdir) and `process` (poll/log/kill/list) tools.

## Requirements

| Component | Version |
|-----------|---------|
| OpenClaw | 2026.2.19+ |
| git | 2.20+ (worktree support) |
| Coding agent | Claude Code 2.1.0+ / Codex / OpenCode / Pi |

## License

[MIT](LICENSE)
