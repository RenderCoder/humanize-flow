# Planning Contract

The planner converts a request into artifacts that both humans and agents can trust.

Write human-review Markdown artifacts in the language requested by the user or CLI prompt. Default to English when no language policy is provided. This includes `request.md`, `jira-requirement.md`, `plan.md`, `acceptance.md`, `bd-plan.md`, `questions.md`, handoff prose fields, and all generated Beads epic/task titles, descriptions, and acceptance criteria. Keep machine-readable names and technical literals in their canonical form: JSON keys and enum values, Beads labels, file paths, commands, APIs, package names, code identifiers, and Beads IDs.

## Phase 1: Intake

Capture the user's request in `docs/humanize-flow/<slug>/request.md`.

Include:

- user intent,
- business/product context if known,
- repository context,
- constraints,
- non-goals,
- open questions.

## Phase 2: Jira-style requirement

Write `docs/humanize-flow/<slug>/jira-requirement.md` as a Markdown requirement suitable for pasting into Jira, Linear, Tapd, ZenTao, or an internal collaboration system.

The document must be understandable by product managers, project managers, QA, support, and other non-engineering stakeholders while still preserving the technical decision context engineers need. Prefer plain language first, then a separate technical section when the requirement is technical.

Include:

- concise title,
- plain-language summary,
- WHY / context before HOW / WHAT,
- affected users, teams, or workflows,
- expected impact and value,
- proposed implementation strategy at a high level,
- specific requirements,
- acceptance criteria,
- risks, dependencies, and rollout or rollback notes when relevant,
- a clearly separated technical notes section for engineering details.

For technical requirements, split the document into two readable layers:

- a stakeholder-facing section with business context, user impact, and plain explanations,
- an engineering details section with architecture, data, permission, migration, compatibility, or testing notes.

For general requirements, keep the whole document accessible and add short explanations for domain-specific terms.

## Phase 3: Repository understanding

Inspect only enough repository context to plan accurately. Prefer read-only commands:

```bash
git status --short
find . -maxdepth 3 -type f | sed 's#^./##' | sort | head -200
```

Use targeted reads after identifying likely components. Do not run expensive tests during planning unless the user asks.

### Adaptive subagent planning

For non-trivial requests, use adaptive subagent planning when Codex subagents are available. This is a planning accelerator, not a distributed writing workflow.

The main planner should keep ownership of the plan and final artifacts. Subagents are read-only investigators that return concise findings:

- `repository-context`: locate relevant modules, existing patterns, likely files to change, and architectural constraints.
- `risk-test`: identify missing requirements, edge cases, acceptance criteria, regression risks, and test strategy.
- `task-shaping`: propose Beads task boundaries, dependencies, sequencing, and whether humanize/RLCR is useful.

Subagents must not:

- write or edit files,
- create, update, or close Beads issues,
- invoke Claude Code or worker workflows,
- produce final `request.md`, `jira-requirement.md`, `plan.md`, `acceptance.md`, `bd-plan.md`, or handoff JSON.

The main planner must merge the findings, resolve conflicts, and document any important uncertainty or rejected interpretation in the final plan. Skip subagents for tiny, single-file, already-obvious, or time-sensitive requests where the coordination overhead is not justified. If subagents are unavailable, continue directly and note confidence limits when relevant.

## Phase 4: Discussion

Ask questions when missing information changes the implementation path. Do not ask questions whose answers can be safely inferred from repository conventions.

## Phase 5: Plan

Write `plan.md` with:

- summary,
- goals and non-goals,
- files/components likely to change,
- implementation sequence,
- risks and mitigations,
- test strategy,
- rollback strategy,
- explicit assumptions.

## Phase 6: Acceptance

Write `acceptance.md` as checkable criteria. Criteria must be observable.

Good:

- "`Ctrl+Z` restores the previous editor value in the browser test."

Bad:

- "Undo feels good."

## Phase 7: Beads task graph

Write `bd-plan.md` and add task definitions to the handoff manifest. Use small tasks that a worker can complete independently.

`bd-plan.md`, `bd.epic.title`, `bd.epic.description`, `bd.tasks[].title`, `bd.tasks[].description`, and `bd.tasks[].acceptance_criteria` are human-facing generated prose. Write them in the requested language so that later `materialize-bd` creates Beads issues in that language.

Each task needs:

- clear title,
- description,
- acceptance criteria,
- dependencies by task key,
- labels including `humanize-flow` and the slug.

## Phase 8: Handoff

Write `.humanize-flow/handoffs/<slug>.json` with state `draft` and approval `pending` unless the user has explicitly approved the plan.
