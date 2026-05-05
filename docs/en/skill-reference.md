# Skill Reference

## `humanize-flow-planner`

Codex skill for **new-request planning**: requirement discussion, planning, Markdown artifact generation, Beads task preparation, and draft handoff creation.

Use it when the user is starting from a request that is not already represented as a Beads task.

Invocation:

```text
$humanize-flow-planner
```

Core output:

```text
docs/humanize-flow/<slug>/request.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

## `humanize-flow-bd-planner`

Codex skill for **existing-Beads-task planning**.

Use it when the user already has a Beads task ID and wants Codex to read that task, discuss missing details, and generate Humanize Flow Markdown and JSON artifacts without duplicating the task.

Invocation:

```text
$humanize-flow-bd-planner
```

Example prompt:

```text
Please read Beads task bd-1234, discuss any missing details with me, and create the Humanize Flow Markdown artifacts and handoff JSON. Do not create duplicate Beads tasks and do not implement code.
```

Core output:

```text
docs/humanize-flow/<slug>/bd-source.json
docs/humanize-flow/<slug>/request.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

Important handoff fields:

```json
{
  "source": {
    "type": "beads",
    "bd_id": "bd-1234"
  },
  "bd": {
    "materialized": true
  },
  "execution": {
    "current_bd_id": "bd-1234"
  }
}
```

Next command after approval:

```bash
humanize-flow approve <slug>
humanize-flow run bd-1234
```

## `humanize-flow-worker`

Claude Code skill for implementing exactly one approved Beads task.

Interactive invocation:

```text
/humanize-flow-worker
```

The CLI also passes the worker skill instructions through `claude -p`, because non-interactive slash invocation may not be available in every Claude Code context.

## `humanize-flow-reviewer`

Codex skill for final review of one implemented task.

Invocation:

```text
$humanize-flow-reviewer
```

The reviewer returns a Markdown report with verdict `pass`, `changes_requested`, or `blocked`.

## Skill installation locations

User-level install uses:

```text
~/.agents/skills/humanize-flow-planner
~/.agents/skills/humanize-flow-bd-planner
~/.agents/skills/humanize-flow-reviewer
~/.claude/skills/humanize-flow-worker
```

Project-level install uses:

```text
.agents/skills/humanize-flow-planner
.agents/skills/humanize-flow-bd-planner
.agents/skills/humanize-flow-reviewer
.claude/skills/humanize-flow-worker
```
