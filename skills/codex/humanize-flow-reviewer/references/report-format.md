# Review Report Format

Use this structure:

```markdown
Humanize-Flow-Verdict: pass | changes_requested | blocked

# Humanize Flow Review: <bd-id>

## Verdict

`pass | changes_requested | blocked`

## Summary

One paragraph.

## Scope reviewed

- Handoff: `<path>`
- Plan: `<path>`
- Acceptance: `<path>`
- Diff base: `<sha-or-branch>`
- Beads task: `<bd-id>`

## Findings

- `[P1] <title>`
  - Evidence: `<file/line/command>`
  - Why it matters: `<reason>`
  - Required fix: `<fix>`

Write `None` if there are no findings.

## Acceptance criteria

| Criterion | Status | Evidence |
| --- | --- | --- |
| `<criterion>` | `pass/fail/unknown` | `<evidence>` |

## Tests

- Ran or inspected:
- Result:
- Missing evidence:

## Human verification guide

Required when the verdict is `pass`; omit only when the verdict is not `pass`.

- Manual test steps:
  1. `<step>`
  2. `<step>`
- Checklist before commit/push:
  - [ ] `<observable condition>`
  - [ ] `<observable condition>`
- Stop conditions:
  - `<symptom that should return to review-feedback or worker>`

## Human correction options

Required when the verdict is `changes_requested` or `blocked`; optional when the verdict is `pass`.

- Potential scope corrections:
- Evidence that would change the verdict:
- Suggested command to merge human feedback:

```bash
humanize-flow review-feedback <bd-id> --from <feedback-file>
```

The `Humanize-Flow-Verdict:` line is the machine-readable contract for the CLI. It must be the first non-empty line in the report, remain ASCII, and use exactly one of `pass`, `changes_requested`, or `blocked`. Do not translate or localize that line; localize the human-readable Markdown sections normally.

## Next step

- If pass: `Complete the human verification checklist before commit/push.`
- If changes requested: `Return to worker with the findings above.`
- If blocked: `Resolve the blocker before review can complete.`
```
