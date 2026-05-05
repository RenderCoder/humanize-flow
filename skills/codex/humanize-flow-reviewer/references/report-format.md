# Review Report Format

Use this structure:

```markdown
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

## Next step

- If pass: `Task can be closed.`
- If changes requested: `Return to worker with the findings above.`
- If blocked: `Resolve the blocker before review can complete.`
```
