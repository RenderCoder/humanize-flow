# Handoff-from-BD Contract

A handoff created from an existing Beads task must be valid against `assets/handoff.schema.json` and must make the source task obvious.

Follow the requested language policy for generated prose fields, including `summary`, `assumptions`, `open_questions`, `bd.tasks[].title`, `bd.tasks[].description`, and `bd.tasks[].acceptance_criteria`. Preserve original Beads text only in source-trace fields such as `source.title` and `bd-source.json`.

## Required fields for imported Beads tasks

Use these fields in addition to the normal handoff fields:

```json
{
  "source": {
    "type": "beads",
    "bd_id": "<bd-id>",
    "source_file": "docs/humanize-flow/<slug>/bd-source.json",
    "captured_at": "<ISO-8601>",
    "title": "<source task title>"
  },
  "created_by": "humanize-flow-bd-planner",
  "bd": {
    "materialized": true,
    "tasks": [
      {
        "bd_id": "<bd-id>"
      }
    ]
  },
  "execution": {
    "current_bd_id": "<bd-id>"
  }
}
```

## Approval

Default:

```json
{
  "state": "draft",
  "approval": {
    "required": true,
    "status": "pending"
  }
}
```

Only set `approval.status="approved"` when the human explicitly approves the complete plan in the same session.

## Artifacts

The handoff `artifacts` map should include:

```json
{
  "request": "docs/humanize-flow/<slug>/request.md",
  "jira_requirement": "docs/humanize-flow/<slug>/jira-requirement.md",
  "plan": "docs/humanize-flow/<slug>/plan.md",
  "acceptance": "docs/humanize-flow/<slug>/acceptance.md",
  "bd_plan": "docs/humanize-flow/<slug>/bd-plan.md",
  "bd_source": "docs/humanize-flow/<slug>/bd-source.json"
}
```
