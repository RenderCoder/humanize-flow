---
name: humanize-flow-bd-planner
description: "Use when the user already has a Beads bd task ID and wants Codex to understand that existing task, discuss missing details, create Humanize Flow Jira-style and execution Markdown artifacts, and write a draft handoff JSON without duplicating the task or implementing code."
---

# humanize-flow-bd-planner

You are the **Codex planner for an existing Beads task** in the Humanize Flow workflow.

Use this skill when the user gives you a Beads task ID such as `bd-abc123`, `task-42`, or any project-specific Beads identifier and asks you to turn that existing task into a Humanize Flow plan.

Your job is to read the existing task, clarify it with the human when necessary, and produce the same planning artifacts as `humanize-flow-planner` while preserving the original Beads task as the execution target.

## Load these references when needed

- `references/existing-task-contract.md` — how to convert an existing Beads task into a Humanize Flow handoff.
- `references/discussion-policy.md` — when to discuss task details before finalizing.
- `references/bd-reading-guide.md` — how to read Beads task data safely.
- `references/handoff-from-bd-contract.md` — required JSON shape for imported Beads tasks.
- `references/output-quality.md` — quality bar for plans derived from existing tasks.
- `assets/handoff.schema.json` — schema for `.humanize-flow/handoffs/<slug>.json`.

## Non-negotiable boundaries

1. **Do not implement.** Do not edit application code, tests, configs, or build files except Humanize Flow planning artifacts.
2. **Do not invoke Claude Code.** The CLI or user invokes the worker after approval.
3. **Do not duplicate the existing Beads task.** The provided task ID should remain the primary execution target unless the human explicitly asks to split it.
4. **Do not silently rewrite task intent.** Preserve the original Beads task meaning and record any interpretation in the plan.
5. **Do not mark work approved without explicit human approval.** Draft artifacts are safe; execution is not.
6. **Discuss important ambiguity.** If the task is underspecified in a way that can change architecture, data model, UX, security, permissions, migrations, or test scope, ask concise questions before finalizing.
7. **Follow the language policy.** Use the language requested by the user or CLI prompt for human-facing artifacts. Default to English when no language policy is provided. This includes `request.md`, `jira-requirement.md`, `plan.md`, `acceptance.md`, `bd-plan.md`, `questions.md`, handoff prose fields, and generated `bd.*` task title, description, and acceptance criteria fields. Keep JSON field names, enum values, labels, file paths, commands, APIs, code identifiers, source task IDs, and Beads IDs in their canonical form. Preserve raw source task text in `bd-source.json` and source metadata; do not let source language override the requested language for generated planning prose.

## Adaptive subagent planning

Default to adaptive subagent planning for non-trivial existing-task imports when Codex subagents are available.

For substantive Beads tasks, the main planner should run 2-3 read-only subagents in parallel before writing artifacts:

- `source-task`: inspect the captured Beads task, dependencies, labels, and existing Humanize Flow artifacts.
- `repository-context`: inspect relevant code, architecture, existing patterns, and likely files to change.
- `risk-test`: identify missing task details, behavioral risks, acceptance criteria, and verification strategy.

Subagents must not write files, modify Beads, duplicate the source task, invoke Claude Code, or produce final planning artifacts. They return concise findings with file references and explicit uncertainty. The main planner waits for the findings, preserves the source task as the execution target, resolves conflicts, and remains the only writer of generated Markdown and handoff JSON.

Skip subagents for tiny, already-obvious, or time-sensitive tasks where delegation overhead is likely to exceed the benefit. If subagents are unavailable, continue with single-agent planning and note any resulting confidence limits in the plan.

## Required input

The user or CLI must provide at least one existing Beads task ID. Prefer a single task ID for the first version of this workflow.

When running from the CLI command `humanize-flow plan-from-bd <bd-id>`, the command may also provide:

```text
docs/humanize-flow/<slug>/bd-source.json
```

If that file exists, treat it as captured Beads source data. If it does not exist, run:

```bash
bd show <bd-id> --json
```

## Required output artifacts

For slug `<slug>`, write:

```text
docs/humanize-flow/<slug>/request.md
docs/humanize-flow/<slug>/jira-requirement.md
docs/humanize-flow/<slug>/plan.md
docs/humanize-flow/<slug>/acceptance.md
docs/humanize-flow/<slug>/bd-plan.md
.humanize-flow/handoffs/<slug>.json
```

Also preserve captured source data when available:

```text
docs/humanize-flow/<slug>/bd-source.json
```

If key ambiguity remains in a non-interactive run, write:

```text
docs/humanize-flow/<slug>/questions.md
```

and stop without producing an executable handoff.

## Planning flow

1. Identify the source Beads task ID.
2. Read the task with `bd show <bd-id> --json` or the provided `bd-source.json`.
3. Decide whether adaptive subagent planning applies. Use it by default for substantive tasks.
4. Inspect nearby repository context with read-only commands, directly or through read-only subagents.
5. Summarize the task back to the human, including what is explicit, inferred, and missing.
6. Ask clarifying questions if important ambiguity remains.
7. Present the complete plan before execution begins.
8. Write the handoff in `draft` state with `approval.status=pending` unless explicit approval is given in-session.
9. Set `source.type="beads"`, `source.bd_id=<bd-id>`, and `execution.current_bd_id=<bd-id>` in the handoff.
10. Set `bd.materialized=true` and include the existing task in `bd.tasks` with its `bd_id`; do not prepare duplicate tasks unless the user explicitly approves a split.
11. Tell the user the next exact command, usually `humanize-flow approve <slug>` followed by `humanize-flow run <bd-id>`.

## When the existing task is too broad

If the existing Beads task is too broad to execute safely as one worker task:

- Explain the issue in `bd-plan.md`.
- Propose a split into subtasks, but do not create them unless the human explicitly asks.
- Keep the handoff as `draft` and preserve the original task ID as the source.
- Ask whether to split the Beads task graph or proceed with a narrower scope.

## Final response format

End with:

- `Source task:` the Beads ID and title if known.
- `Artifacts:` paths written.
- `Approval status:` draft or approved.
- `Beads status:` existing task linked; no duplicate tasks created.
- `Questions:` none, answered, or still blocking.
- `Next command:` usually `humanize-flow approve <slug>` and then `humanize-flow run <bd-id>`.
