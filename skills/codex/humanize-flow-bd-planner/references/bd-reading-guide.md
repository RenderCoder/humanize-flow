# Beads Reading Guide

Use Beads as the task-memory layer. Prefer read-only inspection before writing artifacts.

## Minimum command

```bash
bd show <bd-id> --json
```

If the CLI captured the task already, read:

```text
docs/humanize-flow/<slug>/bd-source.json
```

## Useful follow-up inspection

Depending on the Beads version and project setup, these may help:

```bash
bd ready --json
bd list --json
bd info
```

If parent, child, or dependency data appears in the JSON, include it in `bd-plan.md`. Do not invent dependency relationships.

## Source traceability

Every generated plan should include a short "Source task trace" section:

- source task ID
- source title
- source status if known
- source labels if known
- source priority if known
- important fields used from the JSON

This lets a future agent understand how the existing task became a Humanize Flow handoff.
