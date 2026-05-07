# humanize/RLCR Policy

humanize/RLCR is an optional enhancement for complex implementation work.

Use it when:

- the task spans multiple files,
- the plan has non-trivial acceptance criteria,
- refactoring risk is medium/high,
- tests or review feedback are likely to require iteration.

Do not force it when:

- humanize is not installed,
- the task is a tiny edit,
- the current Claude Code mode cannot invoke the plugin/skill safely,
- using it would require dangerous permission bypass.

## Interactive Claude Code

If the humanize plugin is available and the task is complex, prefer:

```text
/humanize:start-rlcr-loop <plan-path>
```

or the appropriate installed humanize skill command.

## Non-interactive Claude Code

In `claude -p` mode, slash-invoked skills may not be available. If you cannot invoke humanize directly, emulate the discipline:

1. implement from the approved plan,
2. run tests,
3. write a summary,
4. request `humanize-flow review <bd-id>` using the actual Beads task id,
5. fix only review blockers.
