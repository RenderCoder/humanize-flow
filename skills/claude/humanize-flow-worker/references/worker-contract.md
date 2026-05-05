# Worker Contract

The worker implements one approved task.

## Preflight

Run or inspect:

```bash
git status --short
bd show <task-id> --json
```

Find the handoff manifest by checking `.humanize-flow/handoffs/*.json` for the task id. If no manifest exists, ask the user before proceeding.

## Approval gate

Do not implement if the handoff is not approved.

Required:

```json
"approval": { "status": "approved" }
```

## Implementation

- Make the smallest coherent change that satisfies the task.
- Prefer existing project patterns.
- Avoid unrelated refactors.
- Keep new dependencies out unless the plan approved them.
- If you discover additional work, create a follow-up Beads issue with a `discovered-from` dependency.

## Summary path

When slug is known, write:

```text
docs/humanize-flow/<slug>/implementation/<bd-id>.md
```

Include:

- task id,
- summary,
- files changed,
- tests run,
- acceptance status,
- follow-ups.
