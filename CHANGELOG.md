# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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
