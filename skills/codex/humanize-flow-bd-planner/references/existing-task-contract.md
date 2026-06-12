# Existing Beads Task Contract

This skill converts a pre-existing Beads task into a Humanize Flow handoff.

Write human-review Markdown artifacts in the language requested by the user or CLI prompt. Default to English when no language policy is provided. This includes generated `request.md`, `jira-requirement.md`, `plan.md`, `acceptance.md`, `bd-plan.md`, handoff prose, and generated `bd.tasks` title, description, and acceptance criteria fields. Preserve source task identifiers, labels, commands, paths, JSON keys, enum values, APIs, code identifiers, and Beads IDs in their canonical form.

## Source preservation

The original Beads task is the source of truth for the request. Preserve:

- task ID
- title
- description
- labels
- priority
- type
- parent/child/dependency information if present in JSON
- status and owner information if present

Do not overwrite or reinterpret those fields without saying so in the plan.

Source preservation does not override the language policy. Keep raw source text in `bd-source.json` and source metadata such as `source.title`; write generated interpretation, scope, acceptance criteria, and handoff `bd.*` prose in the requested language.

## Adaptive subagent planning

For non-trivial existing-task imports, use adaptive subagent planning when Codex subagents are available. This should speed up context gathering without weakening the single-writer handoff contract.

The main planner should keep ownership of the final interpretation and artifacts. Subagents are read-only investigators that return concise findings:

- `source-task`: source Beads task meaning, dependencies, labels, parent/child relationships, and any existing Humanize Flow artifacts.
- `repository-context`: relevant code paths, architecture, existing patterns, and likely files to change.
- `risk-test`: ambiguity, edge cases, acceptance criteria, regression risks, and verification strategy.

Subagents must not create duplicate Beads issues, update the source task, edit files, invoke Claude Code, or write final planning artifacts. The main planner must merge the findings, preserve the source task as the execution target, and document any interpretation or unresolved uncertainty in the plan.

Skip subagents for tiny, already-obvious, or time-sensitive tasks where the coordination overhead is not justified. If subagents are unavailable, continue directly and note confidence limits when relevant.

## Handoff semantics

For a direct execution task, the handoff should use:

```json
{
  "source": {
    "type": "beads",
    "bd_id": "<bd-id>",
    "source_file": "docs/humanize-flow/<slug>/bd-source.json"
  },
  "bd": {
    "materialized": true,
    "epic": {
      "key": "source",
      "title": "Existing Beads task <bd-id>",
      "type": "epic"
    },
    "tasks": [
      {
        "key": "source-task",
        "title": "<task title>",
        "bd_id": "<bd-id>",
        "acceptance_criteria": []
      }
    ]
  },
  "execution": {
    "current_bd_id": "<bd-id>"
  }
}
```

`bd.materialized=true` means there is already a Beads task to run. It does **not** mean the implementation is complete.

## No duplicate creation

Do not prepare the source task again as a new Beads issue. The normal `humanize-flow approve <slug> --materialize-bd` path is for new requirements. For this imported-task path, the next step is usually:

```bash
humanize-flow approve <slug>
humanize-flow run <bd-id>
```

## Splitting broad tasks

If the source task is too broad, ask the human whether to split it. Until they approve a split, produce a draft plan and keep the original task as the only linked execution target.
