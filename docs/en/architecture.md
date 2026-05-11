# Architecture

humanize-flow separates planning, execution, and review so that multi-agent coding remains auditable and recoverable.

## Role boundaries

| Role | Tool | Responsibility | Must not do |
| --- | --- | --- | --- |
| New-request planner | Codex | Discuss new requirements, write plans, prepare Beads graph, create draft handoff | Implement code or invoke Claude Code |
| Existing-task planner | Codex | Read an existing Beads task ID, clarify missing details, write plans, link a draft handoff to the original task | Duplicate the task or implement code |
| Approver | Human | Decide whether the plan is ready to execute | Rubber-stamp unclear plans |
| Worker | Claude Code | Implement one approved Beads task | Expand scope or close task before review |
| Reviewer | Codex | Review diff against plan and acceptance criteria | Implement fixes |
| Orchestrator | `humanize-flow` CLI | Coordinate files, state, prompts, and tool calls | Replace human approval |

## Artifact layers

### Markdown layer

Markdown files under `docs/humanize-flow/<slug>/` are for humans. They explain the request, Jira-style collaboration requirement, plan, acceptance criteria, implementation summaries, and reviews.

Human-facing generated artifacts default to English and can be switched with `humanize-flow i18n <lang>`. This includes Markdown artifacts such as `jira-requirement.md` and `bd-plan.md`, handoff prose, Beads titles/descriptions/acceptance criteria, implementation summaries, reviews, pull request text, and commit message prose. Technical literals that other tools consume, such as paths, commands, API names, JSON keys, enum values, labels, Beads IDs, and code identifiers, remain canonical.

### Beads layer

Beads stores the executable task graph. Agents use `bd ready --json`, `bd show --json`, and dependencies to select safe next work. Existing Beads tasks can be imported into the workflow with `humanize-flow-bd-planner` without creating duplicate issues. Imported source text is preserved as source data, while generated planning and handoff task prose follows the configured workflow language.

### Handoff layer

`.humanize-flow/handoffs/<slug>.json` is the machine-readable contract between the planner, worker, reviewer, and CLI. It contains paths, approval state, Beads task definitions, source metadata, and execution metadata.

## Handoff state machine

```text
draft
  → approved
  → in_progress
  → review_requested
  → changes_requested → in_progress
  → complete
```

`blocked` may be used when the workflow cannot safely continue.

## Why not have Codex call Claude directly?

Nested agents make permissions, logs, and failure recovery hard. humanize-flow keeps cross-agent calls in the CLI. Skills define behavior; the CLI performs orchestration.

## Required-by-default humanize integration

humanize/RLCR is the default worker path. `claude.humanize=required` makes `humanize-flow run` fail closed when no humanize integration is detected and instructs Claude to start RLCR before editing code. Teams can lower this to `auto` or `off` when a repository or environment cannot support humanize for a specific run.
