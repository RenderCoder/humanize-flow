# Beads Integration

humanize-flow uses Beads as a task-memory and dependency layer.

## Why Beads

Markdown plans are easy for humans to read, but agents need a queue and dependency graph. Beads provides ready-task selection, issue details, dependencies, and JSON output.

## Labels

Humanize Flow tasks created by the new-request planner should include:

- `humanize-flow`
- the slug, for example `undo-redo`

Optional labels:

- `planner-created`
- `imported-bd-task`
- `humanize-preferred`
- area labels such as `frontend`, `backend`, `tests`, or `docs`

Existing tasks imported with `humanize-flow-bd-planner` do not need to be relabeled before execution, because the handoff records their `bd_id`. Adding `humanize-flow` and the slug labels is still helpful for queue visibility if your project policy allows it.

Generated Beads prose follows `humanize-flow i18n`: new-request epic/task titles, descriptions, and acceptance criteria use the configured workflow language. Imported Beads source text is preserved in `bd-source.json`, but generated planning and handoff task prose should still use the configured language.

## New-request materialization

The standard planner prepares Beads tasks inside the handoff manifest. After approval, run:

```bash
humanize-flow approve <slug> --materialize-bd
```

or:

```bash
humanize-flow materialize-bd <slug>
```

## Existing-task planning

When a requirement is already stored in Beads, use:

```bash
humanize-flow plan-from-bd <bd-id> --slug <slug>
```

or invoke:

```text
$humanize-flow-bd-planner
```

This path captures:

```bash
bd show <bd-id> --json
```

as:

```text
docs/humanize-flow/<slug>/bd-source.json
```

The handoff should include:

```json
{
  "source": {
    "type": "beads",
    "bd_id": "<bd-id>"
  },
  "bd": {
    "materialized": true
  },
  "execution": {
    "current_bd_id": "<bd-id>"
  }
}
```

This means the Beads task already exists and should not be created again. Approve with:

```bash
humanize-flow approve <slug>
```

Then run:

```bash
humanize-flow run <bd-id>
```

## Worker usage

The worker should read the task:

```bash
bd show <bd-id> --json
```

The Beads task is queue memory, not the whole implementation contract. Humanize Flow-created Beads descriptions include links back to the handoff, request, Jira-style requirement, plan, acceptance criteria, and Beads plan when those paths are known. The worker must read the approved handoff plus `plan.md` and `acceptance.md`; if those artifacts are missing, it should stop instead of implementing from the concise Beads text alone.

It should not silently expand scope. Discovered work should become a new Beads issue or a reviewer finding, depending on project policy.

## `run-next` behavior

`humanize-flow run-next` still ranks ready Beads tasks by approved handoff membership first, `humanize-flow` labels second, and other ready tasks last. When stdin is interactive and multiple ready tasks or Epic groups exist, it asks which group/task to run before starting Claude Code.

In non-interactive scripts, set `HUMANIZE_FLOW_NONINTERACTIVE=1` to use the deterministic fallback selection.

Use `humanize-flow run-next --worktree` to keep implementation work out of the main checkout. After selecting a ready task, the CLI checks `bd worktree info`; if the current directory is not already a Beads worktree, it creates `../feature-<bd-id>` on branch `feature/<bd-id>` with `bd worktree create` and continues the worker command there.

## Review usage

The reviewer should use Beads data as one source of truth, but it must also inspect the approved handoff, `plan.md`, `acceptance.md`, and git diff. If the approved Markdown artifacts are missing, the correct verdict is `blocked`.
