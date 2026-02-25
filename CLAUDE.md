# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**coding-pm** is an OpenClaw Skill that turns the OpenClaw agent into a PM/QA managing coding agents (Claude Code, Codex, OpenCode, Pi) as background engineers. The agent reviews plans, gates approval, monitors progress, validates tests, and reports results — all without blocking the chat session.

```
User (IM) → OpenClaw Agent (PM/QA) → Coding Agent (Engineer, background)
```

## Architecture

**Pure SKILL.md** — All PM/QA logic lives in natural language instructions. No scripts, no custom state management.

- `SKILL.md` — The PM brain. All workflow logic and agent commands.
- `references/supervisor-prompt.md` — Injected into worktrees as CLAUDE.md. The contract between PM and Engineer.

**Platform tools as hands** — Uses OpenClaw's built-in `bash` (pty/background/workdir) and `process` (poll/log/kill/list) tools instead of custom shell scripts.

**Worktree isolation** — Each task gets a git worktree at `~/.worktrees/<task-name>/` with a feature branch.

**Flow**: `/dev <request>` → worktree setup → agent plans → PM reviews → user approves → agent executes → PM validates tests → user confirms → merge & cleanup.

## Development Commands

```bash
# Publish
clawdhub publish . --slug coding-pm --name "Coding PM" --version X.Y.Z --changelog "..."
```

## Conventions

- **Commit format**: `type(scope): description` (feat/fix/refactor/test/docs/chore)
- **Branch strategy**: Direct to main for v0.x. Feature branches when needed.
- **SKILL.md**: English instructions. Agent IM output follows user's language automatically.
- **Version tags**: SemVer `v0.1.0`, `v0.2.0`, etc. Every tag = GitHub + ClawdHub release.

## Requirements

- OpenClaw 2026.2.19+, git 2.20+
- At least one coding agent: Claude Code 2.1.0+ / Codex / OpenCode / Pi
- `tools.fs.workspaceOnly = false` in OpenClaw config (worktree paths are outside workspace)
