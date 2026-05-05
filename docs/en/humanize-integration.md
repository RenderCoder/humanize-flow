# humanize Integration

humanize/RLCR is optional in humanize-flow. It is most useful during implementation, not during planning.

## When to use humanize

Use it when a worker task is complex:

- multiple files,
- non-trivial acceptance criteria,
- medium or high refactor risk,
- likely review iteration,
- architectural sensitivity.

## When not to use humanize

Skip it when:

- the task is a tiny edit,
- humanize is not installed,
- invoking it would require unsafe permissions,
- the current non-interactive mode cannot safely call slash commands.

## Fallback behavior

If humanize is not available, the worker should emulate the discipline:

1. implement from the approved plan,
2. run targeted tests,
3. write an implementation summary,
4. request Codex review,
5. fix only review blockers.

## Important boundary

humanize should be used inside the Claude worker phase. The Codex planner should not invoke humanize, and the Codex reviewer should not implement fixes.
