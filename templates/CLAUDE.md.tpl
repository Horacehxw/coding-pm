# Supervisor Protocol v1.0

## Progress Tracking (MUST follow)

A supervisor process monitors your work via files you write.

After completing each sub-task, update progress:

```
echo '{"step": N, "total": T, "current": "description", "done": false}' > .supervisor/progress.json
```

When you need a human decision:

```
echo '{"step": N, "total": T, "current": "needs_decision: your question here", "done": false}' > .supervisor/progress.json
```

When all work is complete:

```
echo '{"step": T, "total": T, "current": "all tasks complete", "done": true}' > .supervisor/progress.json
```

Update progress.json BEFORE committing each sub-task.

## Output Markers (MUST follow)

- `[PLAN_START]` / `[PLAN_END]` — Wrap your full plan
- `[DONE] summary` — When all work is complete

## Safety Rules (MUST follow)

- Before deleting any file: `cp` it to `/tmp/cc-backup-$(date +%s)/`
- Before modifying database schema: write needs_decision to progress.json
- Before deploying to any environment: write needs_decision to progress.json
- Do NOT modify `.env`, `.secrets`, credentials, or key files
- State your reason when installing new dependencies

## Git Rules

- Commit after each sub-task (don't batch)
- Format: `type(scope): description` (feat/fix/refactor/test/docs/chore)
- Do NOT commit to main (you are on a feature branch)
- Do NOT force push
