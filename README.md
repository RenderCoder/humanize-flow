# humanize-flow

**humanize-flow** is a lightweight orchestration kit for a practical multi-agent coding workflow:

```text
Codex planner → human approval → Claude Code worker → Codex reviewer
```

It is designed for developers who want Codex to understand and plan work, Claude Code to implement it, Beads (`bd`) to preserve task memory, and required-by-default humanize/RLCR loops to improve implementation quality.

## Why this exists

AI coding tools are powerful, but complex work fails when planning, implementation, and review blur together. humanize-flow keeps the boundaries explicit:

- **Codex plans**: discusses requirements when needed, writes Markdown plans, prepares Beads tasks, and produces a handoff manifest.
- **Humans approve**: implementation does not begin until the handoff is approved.
- **Claude Code implements**: executes one approved task at a time, using humanize/RLCR by default for iterative review.
- **Codex reviews**: checks the final diff against the approved plan and acceptance criteria.
- **The CLI orchestrates**: scripts coordinate tools, files, state, logs, and recovery.

## Components

| Component | Name | Purpose |
| --- | --- | --- |
| Codex skill | `humanize-flow-planner` | Discuss a new requirement, generate Jira-style and execution Markdown artifacts, prepare Beads tasks, write draft handoff JSON. |
| Codex skill | `humanize-flow-bd-planner` | Start from an existing Beads task ID, discuss missing details, generate Jira-style and execution Markdown artifacts, and link a draft handoff to the original task without duplicating it. |
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
humanize-flow verify <bd-id>
humanize-flow commit
humanize-flow push
humanize-flow pr
```

If GitHub reports that the PR cannot merge cleanly with the target branch, run `humanize-flow pr-resolve --base main` from the PR branch. It integrates the target branch, asks Codex to resolve only those conflicts, and leaves the final commit or rebase continuation under your control.

That is the recommended daily path: plan, approve, implement one ready task, review it, complete the human verification guide, then deliver. Use explicit Beads IDs when you know the next task:

```bash
humanize-flow run <bd-id>
```

Use `run-next` when you want Humanize Flow to choose from the ready queue and prompt if multiple groups are available.

Worker runs default to Claude Code print mode with detailed progress visible in the terminal, model `claude-sonnet-4-6`, permission mode `bypassPermissions`, and `claude.humanize=required`. Codex planner/reviewer/commit/PR runs use your normal Codex defaults unless configured with `humanize-flow config`. Review and review-feedback default to Codex yolo mode so prompts do not block the review loop. To supervise the work in a Claude Code UI, run:

```bash
humanize-flow run <bd-id> --interactive
```

Use YOLO for trusted worktrees when you want Humanize Flow to keep running worker implementation plus Codex review until the handoff passes or the correction limit is reached:

```bash
humanize-flow run <handoff-slug-or-epic-id> --yolo
humanize-flow run <handoff-slug-or-epic-id> --yolo --max-round 5 --retry 5 --retry-delay 20
```

YOLO forces `--humanize-mode off`, restores progress from already closed Beads child tasks when resuming, continues handoff child tasks already marked `in_progress`, re-queries Beads ready state before each remaining Epic child task, and separates infrastructure retries from business correction rounds. By default, YOLO now implements all ready handoff children first and then runs one final full-scope Codex review/correction loop. Use `--review-each-task` when you prefer the older per-child review cadence. The default correction limit is 5 rounds and can be persisted with `humanize-flow config set yolo.max_round 5`.

To use Codex instead of Claude Code for YOLO implementation, set the worker provider once:

```bash
humanize-flow config set worker.provider codex
humanize-flow config set worker.codex.model gpt-5.5
humanize-flow config set worker.codex.reasoning_effort medium
```

Codex worker mode only supports `run --yolo`; it does not run humanize/RLCR or Claude-specific interactive/session features. YOLO still stops at the human verification gate: after a `pass` review, complete the report's `Human verification guide` and run `humanize-flow verify <bd-id>` before `commit`, `push`, or `pr`.

When a run looks stuck, start with:

```bash
humanize-flow status --ai
```

It combines a deterministic status snapshot with a plain-language Codex explanation of whether the workflow is running, blocked, completed, or waiting for you.

If manual testing finds an issue after review, or if the review needs human scope correction, run:

```bash
humanize-flow review-feedback <bd-id>
```

For fuller operational guidance, read [Best Practices](docs/en/best-practices.md).

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

Human-facing generated artifacts default to English. Use `humanize-flow i18n zh` to switch the full workflow to Simplified Chinese for planning docs including `jira-requirement.md` and `bd-plan.md`, handoff prose, materialized Beads epic/task titles, descriptions, acceptance criteria, implementation summaries, review reports, pull request text, and commit message prose. Machine-readable JSON keys, enum values, labels, paths, commands, APIs, Beads IDs, and code identifiers stay in their canonical form.

`jira-requirement.md` is a Jira-style Markdown requirement intended for internal collaboration systems. It explains WHY/context first, keeps the main sections readable for non-engineering stakeholders, and separates hard technical notes when the requirement needs them.

Beads tasks are allowed to stay concise for queue readability. The execution contract is not the short Beads text alone: Claude Code worker prompts require the approved handoff plus `plan.md` and `acceptance.md`, and Codex review blocks when those artifacts are missing.

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
- GitHub CLI (`gh`) for `humanize-flow pr`; run `gh auth login -h github.com` before creating PRs
- `jq` recommended

Recommended workflow tools:

- Codex CLI
- Claude Code CLI
- Beads (`bd`)
- humanize plugin or skills, required by default for worker execution

## Safety defaults

- The planner does not edit implementation code.
- The worker refuses unapproved handoffs.
- The reviewer does not implement fixes.
- Planner, commit, PR, and worker flows do not default to full Codex sandbox bypass.
- Codex review and review-feedback default to yolo mode with `--dangerously-bypass-approvals-and-sandbox` to avoid blocking the review loop; lower it with `review.yolo=false` or `--no-yolo` when your environment requires stricter isolation.
- Dangerous permissions should be used only in trusted, externally isolated environments.

## Documentation

- English docs: `docs/en/`
- 简体中文文档：`docs/zh-CN/`
- 中文 README：`README.zh-CN.md`
- Recommended usage: [Best Practices](docs/en/best-practices.md)

## Development

```bash
make test
make package
```

The generated release archive is `humanize-flow.zip`.

## License

MIT
