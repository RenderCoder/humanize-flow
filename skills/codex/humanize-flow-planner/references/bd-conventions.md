# Beads Conventions

Humanize Flow uses Beads (`bd`) as the executable task graph.

## Labels

Every Humanize Flow issue should include:

- `humanize-flow`
- the slug, for example `undo-redo`

Optional labels:

- `planner-created`
- `humanize-preferred`
- area labels such as `frontend`, `backend`, `docs`, `tests`

## Types

Use:

- `epic` for the top-level request,
- `task` for implementation steps,
- `feature` for user-visible feature work,
- `bug` for discovered defects.

## Priorities

- `0`: urgent/blocking
- `1`: high
- `2`: normal/default
- `3`: low/follow-up
- `4`: backlog

## Dependencies

A task's `depends_on_keys` should list earlier task keys that must complete first. The CLI materializes these with `bd dep add <child> <parent>`.

## Task sizing

Each task should be small enough for one Claude worker run. If a task contains multiple unrelated changes, split it.

## Description format

Each Beads task description should include:

- purpose,
- relevant plan path,
- acceptance criteria summary,
- explicit non-goals,
- expected tests.

## Discovered work

Implementation-time discoveries should become separate Beads issues with `discovered-from:<current-task>` rather than expanding the current task silently.
