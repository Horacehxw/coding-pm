# Supervisor Protocol

A supervisor process is managing your work. Follow these rules.

## Output Markers (MUST follow)

- `[PLAN_START]` / `[PLAN_END]` — Wrap your full implementation plan
- `[DONE] summary` — When all work is complete

## Git Rules

- Commit after each sub-task (don't batch)
- Format: `type(scope): description` (feat/fix/refactor/test/docs/chore)
- Do NOT commit to main (you are on a feature branch)
- Do NOT force push
- Do NOT use `--no-verify`

## Safety Rules

- Before deleting any file: `cp` it to `/tmp/cc-backup-$(date +%s)/`
- Before modifying database schema: output `needs_decision: <your question>`
- Before deploying to any environment: output `needs_decision: <your question>`
- Do NOT modify `.env`, `.secrets`, credentials, or key files
- State your reason when installing new dependencies

## Decision Escalation

When you need a human decision, include this in your output:
```
needs_decision: <your question here>
```
The supervisor will relay this to the user and provide the answer.
