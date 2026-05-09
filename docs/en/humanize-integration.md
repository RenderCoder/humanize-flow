# humanize Integration

humanize/RLCR is required by default in humanize-flow worker runs. It is used during implementation, not during planning.

## Modes

- `required`: default. `humanize-flow run` checks that humanize is installed and the Claude prompt requires starting RLCR from the approved plan before code edits.
- `auto`: use humanize for complex tasks when available, but allow direct implementation when unavailable or inappropriate.
- `off`: disable humanize for this run.

Configure the default:

```bash
humanize-flow config set claude.humanize required
humanize-flow config set claude.humanize auto
humanize-flow config set claude.humanize off
```

Override one run:

```bash
humanize-flow run <bd-id> --humanize
humanize-flow run <bd-id> --humanize-mode auto
humanize-flow run <bd-id> --no-humanize
```

## When `auto` should use humanize

Use it when a worker task is complex:

- multiple files,
- non-trivial acceptance criteria,
- medium or high refactor risk,
- likely review iteration,
- architectural sensitivity.

## When `auto` may skip humanize

Skip it when:

- the task is a tiny edit,
- humanize is not installed,
- invoking it would require unsafe permissions,
- the current non-interactive mode cannot safely call slash commands.

## Fallback behavior

In `required`, there is no silent fallback: stop and report the blocker. In `auto`, if humanize is not available, the worker should emulate the discipline:

1. implement from the approved plan,
2. run targeted tests,
3. write an implementation summary,
4. request Codex review,
5. fix only review blockers.

## Important boundary

humanize should be used inside the Claude worker phase. The Codex planner should not invoke humanize, and the Codex reviewer should not implement fixes.
