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
humanize-flow run <bd-id> --yolo
humanize-flow review <bd-id>
humanize-flow review-feedback <bd-id>
humanize-flow commit
humanize-flow push
humanize-flow pr
```

Worker runs default to Claude Code print mode with detailed progress visible in the terminal, model `claude-sonnet-4-6`, permission mode `bypassPermissions`, and `claude.humanize=required`. Codex planner/reviewer/commit/PR runs use your normal Codex defaults unless `codex.model` or `codex.reasoning_effort` is configured with `humanize-flow config`; review and review-feedback default to yolo mode with Codex `--dangerously-bypass-approvals-and-sandbox` and can be lowered with `review.yolo=false`, `HUMANIZE_FLOW_REVIEW_YOLO=false`, `--no-yolo`, `review.sandbox`, `HUMANIZE_FLOW_REVIEW_SANDBOX`, or `--sandbox`. Lower Claude Code permissions with `--permission-mode auto`, `HUMANIZE_FLOW_CLAUDE_PERMISSION_MODE=auto`, or `humanize-flow config set claude.permission_mode auto` when you need classifier-gated execution. With `required`, the worker prompt requires Claude to start humanize/RLCR from the approved plan before editing code; if humanize is unavailable, lower the mode with `--humanize-mode auto`, `--no-humanize`, `HUMANIZE_FLOW_CLAUDE_HUMANIZE`, or `humanize-flow config set claude.humanize <mode>`. The CLI keeps the raw Claude `stream-json` events in the run directory for debugging, while showing a human-readable log by default. To supervise the work in a Claude Code UI, run:

```bash
humanize-flow run <bd-id> --interactive
```

Use `humanize-flow run <bd-id> --yolo` for an approved handoff when you want the CLI to force Claude Code permission mode `bypassPermissions`, force Codex review yolo mode, and repeat Claude correction plus Codex review until the review passes or the 3-round default limit is reached. YOLO forces `--humanize-mode off` to avoid nested review loops. When the target is a handoff slug or Beads Epic ID, YOLO re-queries `bd ready --json` before each child task, selects the next ready child that belongs to the handoff, preserving Beads' ready ordering instead of the handoff's static child order. After a child task passes review, the CLI closes that Beads task so dependencies can unblock the next ready task. Each Codex review is scoped to the completed child task; Codex must not fail it just because sibling Epic tasks remain unfinished. Override the per-task correction limit with `--max-round N`.

After review passes, `humanize-flow commit` asks Codex to select which changed files belong in the commit from the full working tree every time. Existing staged changes are treated as context only, so Codex can include unstaged paths that belong and exclude accidentally staged paths. The CLI stages the selected paths, drafts a Lore commit message, then commits only those selected paths after confirmation. `humanize-flow push` pushes the current branch; if multiple remotes exist, it prompts for the remote. `humanize-flow pr` asks Codex to draft a detailed, professional GitHub PR title/body in the configured workflow language with WHY/context prioritized over HOW/WHAT, includes passing review `Human verification guide` content as reviewer-facing validation context, saves the draft under `.humanize-flow/runs/`, prompts for the GitHub remote when multiple remotes exist, and creates the PR with `gh pr create --repo`.

Codex `pass` reviews include a human verification guide. Complete that manual checklist before commit/push/PR. If manual testing finds a problem or corrects the review scope, run `humanize-flow review-feedback <bd-id>`; the CLI opens your editor for feedback and then produces an updated combined Codex + human review verdict.

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

Human-facing generated artifacts default to English. Use `humanize-flow i18n zh` to switch the full workflow to Simplified Chinese for planning docs including `bd-plan.md`, handoff prose, materialized Beads epic/task titles, descriptions, acceptance criteria, implementation summaries, review reports, pull request text, and commit message prose. Machine-readable JSON keys, enum values, labels, paths, commands, APIs, Beads IDs, and code identifiers stay in their canonical form.

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

## Development

```bash
make test
make package
```

The generated release archive is `humanize-flow.zip`.

## License

MIT
