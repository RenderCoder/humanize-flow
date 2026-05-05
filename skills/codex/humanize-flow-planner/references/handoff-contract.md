# Handoff Contract

The handoff manifest is the machine-readable boundary between planner, worker, reviewer, and CLI.

Canonical path:

```text
.humanize-flow/handoffs/<slug>.json
```

Canonical schema:

```text
schemas/handoff.schema.json
```

## Required states

- `draft`: plan is not approved.
- `approved`: human approval is recorded.
- `in_progress`: worker is implementing.
- `review_requested`: implementation is ready for review.
- `changes_requested`: reviewer found blockers.
- `complete`: reviewer passed.
- `blocked`: work cannot proceed.

## Artifact paths

Use repository-relative paths so the handoff is portable across machines.

## Approval

Never set:

```json
"approval": { "status": "approved" }
```

unless the user explicitly approved the plan in the same session or ran `humanize-flow approve`.

## Beads materialization

The planner may populate `bd.epic` and `bd.tasks` in the handoff while leaving `bd.materialized=false`.

The CLI command:

```bash
humanize-flow approve <slug> --materialize-bd
```

marks the handoff approved and creates the Beads issues.
