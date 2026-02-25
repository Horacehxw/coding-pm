# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.2.0] - 2026-02-25

### Changed
- **Renamed**: claw-pilot → coding-pm (complements coding-agent: agent executes, PM manages)
- **Rewritten SKILL.md**: pure platform tools (bash/process), no custom scripts
- **Multi-agent support**: Claude Code, Codex, OpenCode, Pi (was CC-only)
- **Simplified supervisor prompt**: removed progress.json protocol, kept plan markers + safety rules

### Removed
- All 6 shell scripts (init-task, start-cc, check-cc, merge-task, cleanup-task, list-tasks)
- templates/ directory (supervisor prompt moved to references/)
- docs/design.md (archived in git history)
- tests/test-scripts.sh (no scripts to test)
- task.json / progress.json / status / session_id / cc.pid file-based IPC
- ~/.openclaw/supervisor/tasks/ runtime directory
- jq dependency

### Added
- references/supervisor-prompt.md (simplified supervisor contract)
- Multi-agent detection and command table
- Auto-notify on completion
- .clawhubignore

## [0.1.0] - 2026-02-25

### Added
- Core workflow: plan → approve → execute → report
- SKILL.md agent instructions for PM/QA role
- 5 shell scripts: init-task, start-cc, check-cc, merge-task, cleanup-task
- Supervisor Protocol v1.0 (CLAUDE.md.tpl)
- Dual progress tracking: git commits + progress.json
- Git worktree isolation per task
- Background CC execution via setsid
- JSON output mode (~1KB per invocation)
- README (English + Chinese)
