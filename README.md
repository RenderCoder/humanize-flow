# humanize-flow

**humanize-flow** is a lightweight orchestration kit for a practical multi-agent coding workflow:

```text
Codex planner → human approval → Claude Code worker → Codex reviewer
```

It is designed for developers who want Codex to understand and plan work, Claude Code to implement it, Beads (`bd`) to preserve task memory, and optional humanize/RLCR loops to improve implementation quality.

## Why this exists

AI coding tools are powerful, but complex work fails when planning, implementation, and review blur together. humanize-flow keeps the boundaries explicit:

- **Codex plans**: discusses requirements when needed, writes Markdown plans, prepares Beads tasks, and produces a handoff manifest.
- **Humans approve**: implementation does not begin until the handoff is approved.
- **Claude Code implements**: executes one approved task at a time, optionally using humanize/RLCR for iterative review.
- **Codex reviews**: checks the final diff against the approved plan and acceptance criteria.
- **The CLI orchestrates**: scripts coordinate tools, files, state, logs, and recovery.

## Components

| Component | Name | Purpose |
| --- | --- | --- |
| Codex skill | `humanize-flow-planner` | Discuss a new requirement, generate Markdown artifacts, prepare Beads tasks, write draft handoff JSON. |
| Codex skill | `humanize-flow-bd-planner` | Start from an existing Beads task ID, discuss missing details, generate Markdown artifacts, and link a draft handoff to the original task without duplicating it. |
| Claude Code skill | `humanize-flow-worker` | Implement exactly one approved Beads task and request review. |
| Codex skill | `humanize-flow-reviewer` | Review implementation against handoff, plan, acceptance criteria, tests, and git diff. |
| CLI | `humanize-flow` | Install, initialize, approve, materialize Beads tasks, run workers, run reviews, inspect status. |

## Install

From an extracted release archive:

```bash
./install.sh --user
humanize-flow doctor
```

This installs:

```text
~/.agents/skills/humanize-flow-planner
~/.agents/skills/humanize-flow-bd-planner
~/.agents/skills/humanize-flow-reviewer
~/.claude/skills/humanize-flow-worker
~/.local/bin/humanize-flow
~/.local/share/humanize-flow
```

For repository-local skills:

```bash
./install.sh --project
```

## Quick start

Inside a git repository:

```bash
humanize-flow init --with-bd
```

Then use Codex interactively:

```text
$humanize-flow-planner

I want to add undo/redo support to the editor. Please discuss any unclear requirements with me, then show the complete plan and prepare the Humanize Flow artifacts. Do not implement code.
```

After reviewing the plan:

```bash
humanize-flow approve undo-redo --materialize-bd
humanize-flow run-next
humanize-flow review <bd-id>
```

## Planning from an existing Beads task

If the requirement is already recorded in Beads, do not retype it. Invoke the dedicated skill in Codex:

```text
$humanize-flow-bd-planner

Please read Beads task bd-1234, discuss missing details with me, and create the Humanize Flow Markdown artifacts and handoff JSON. Do not create duplicate Beads tasks and do not implement code.
```

Or use the CLI path:

```bash
humanize-flow plan-from-bd bd-1234 --slug undo-redo
```

This captures `bd show bd-1234 --json` into `docs/humanize-flow/<slug>/bd-source.json`, links the original task in `.humanize-flow/handoffs/<slug>.json`, and normally leads to:

```bash
humanize-flow approve <slug>
humanize-flow run bd-1234
humanize-flow review bd-1234
```

## Non-interactive planning

```bash
humanize-flow plan --slug undo-redo --from examples/minimal-feature-request.md
humanize-flow plan-from-bd bd-1234 --slug undo-redo
```

If important ambiguity remains, the planner should write `docs/humanize-flow/<slug>/questions.md` and stop instead of inventing a high-impact decision.

## Artifact model

humanize-flow separates three interfaces:

```text
Markdown        docs/humanize-flow/<slug>/...     for humans
Beads issues    bd ready / bd show / bd dep        for agents and task state
Handoff JSON    .humanize-flow/handoffs/<slug>.json for deterministic orchestration
```

The handoff manifest is governed by `schemas/handoff.schema.json`.

## Requirements

Required for the CLI itself:

- Bash
- Git
- Python 3
- `jq` recommended

Recommended workflow tools:

- Codex CLI
- Claude Code CLI
- Beads (`bd`)
- humanize plugin or skills, optional but useful for complex execution

## Safety defaults

- The planner does not edit implementation code.
- The worker refuses unapproved handoffs.
- The reviewer does not implement fixes.
- The CLI does not default to full-access sandbox modes.
- Dangerous permissions should be used only in trusted, isolated environments.

## Documentation

- English docs: `docs/en/`
- 简体中文文档：`docs/zh-CN/`
- 中文 README：`README.zh-CN.md`

## Development

```bash
make test
make package
```

The generated release archive is `humanize-flow.zip`.

## License

MIT
