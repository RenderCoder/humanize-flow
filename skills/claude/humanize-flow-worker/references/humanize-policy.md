# humanize/RLCR Policy

The `humanize-flow run` prompt sets the active `Claude humanize mode`.

## Mode: required

This is the default. Before editing implementation code, start humanize/RLCR from inside the Claude Code session using the approved plan path from the run prompt.

Prefer:

```text
/humanize:start-rlcr-loop <plan-path> --yolo
```

If the slash command is unavailable, use the installed humanize setup script equivalent when the run prompt reports one. If humanize/RLCR cannot be started, stop without editing code and report the blocker. Do not silently emulate humanize discipline in required mode.

## Mode: auto

Use humanize/RLCR when:

- the task spans multiple files,
- the plan has non-trivial acceptance criteria,
- refactoring risk is medium/high,
- tests or review feedback are likely to require iteration.

You may implement directly when:

- humanize is not installed,
- the task is a tiny edit,
- the current Claude Code mode cannot invoke the plugin/skill safely,
- using it would require dangerous permission bypass.

When implementing directly in `auto`, emulate the discipline:

1. implement from the approved plan,
2. run tests,
3. write a summary,
4. request `humanize-flow review <bd-id>` using the actual Beads task id,
5. fix only review blockers.

## Mode: off

Do not start humanize/RLCR. Implement directly from the approved handoff, plan, and acceptance criteria, then request Codex review.
