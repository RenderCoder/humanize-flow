# Beads Update Policy

Use Beads to preserve task memory.

## Start work

When beginning a task:

```bash
bd update <bd-id> --status in_progress --json
```

If supported by your Beads version, claim the task or set assignee.

## During work

For discovered work:

```bash
bd create "<title>" --description "<details>" --deps discovered-from:<bd-id> --json
```

Do not hide discovered scope in the current task.

## End work

Add notes with:

- summary of changes,
- tests run,
- files changed,
- known risks,
- review command.

Use the current Beads syntax supported by the installed version, for example:

```bash
bd update <bd-id> --notes "<summary>" --json
```

Do not close the task before Codex reviewer passes unless the user explicitly asks.
