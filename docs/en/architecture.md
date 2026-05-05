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

Markdown files under `docs/humanize-flow/<slug>/` are for humans. They explain the request, plan, acceptance criteria, implementation summaries, and reviews.

### Beads layer

Beads stores the executable task graph. Agents use `bd ready --json`, `bd show --json`, and dependencies to select safe next work. Existing Beads tasks can be imported into the workflow with `humanize-flow-bd-planner` without creating duplicate issues.

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

## Optional humanize integration

humanize/RLCR is useful during implementation, especially for multi-file or high-risk changes. It is optional so the project remains usable without it.
