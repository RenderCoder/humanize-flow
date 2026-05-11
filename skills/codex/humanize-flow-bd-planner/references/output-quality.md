# Output Quality for Existing-Task Plans

A good plan from an existing Beads task should be better than the original task, not just a copy of it.

Human-review Markdown artifacts, generated handoff prose, and generated Beads task prose should follow the requested language policy and default to English. Keep source task identifiers, commands, paths, JSON keys, enum values, APIs, code identifiers, and Beads IDs in their canonical form. Preserve raw source language in `bd-source.json`, but do not copy source prose verbatim when it would violate the requested language for generated artifacts.

## `request.md`

Include:

- source Beads ID and title
- original task summary
- important source metadata
- interpreted user intent
- assumptions and unresolved questions

## `jira-requirement.md`

Write a Jira-style Markdown requirement suitable for pasting into an internal collaboration system. It should be readable by product managers, project managers, QA, support, and other non-engineering stakeholders.

Include WHY / context before HOW / WHAT, explain the value and affected workflow in plain language, summarize the proposed implementation strategy, list concrete requirements and acceptance criteria, and add a separate technical notes section for architecture, data, permission, migration, compatibility, or testing details when needed.

## `plan.md`

Include:

- repository context inspected
- implementation strategy
- files or components likely to change
- risk areas
- rollback or safety notes when relevant
- explicit out-of-scope items

## `acceptance.md`

Include measurable acceptance criteria. If the source task lacks criteria, derive them conservatively and mark them as inferred.

## `bd-plan.md`

For the existing-task path, this is not a materialization plan by default. It should say:

- linked source task ID
- whether the task is safe to execute as one unit
- whether splitting is recommended
- any dependencies or blockers discovered
- the exact next command for execution

## Handoff JSON

The JSON must be machine-readable, valid, and explicit enough for the worker to run without rereading the entire planning conversation.

Generated prose fields such as `summary`, `assumptions`, `open_questions`, `bd.tasks[].title`, `bd.tasks[].description`, and `bd.tasks[].acceptance_criteria` must use the requested language. Source-preservation fields such as `source.title` may keep the original Beads task language.
