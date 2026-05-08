# Planning Contract

The planner converts a request into artifacts that both humans and agents can trust.

Write human-review Markdown artifacts in the language requested by the user or CLI prompt. Default to English when no language policy is provided. This includes `request.md`, `plan.md`, `acceptance.md`, `bd-plan.md`, `questions.md`, handoff prose fields, and all generated Beads epic/task titles, descriptions, and acceptance criteria. Keep machine-readable names and technical literals in their canonical form: JSON keys and enum values, Beads labels, file paths, commands, APIs, package names, code identifiers, and Beads IDs.

## Phase 1: Intake

Capture the user's request in `docs/humanize-flow/<slug>/request.md`.

Include:

- user intent,
- business/product context if known,
- repository context,
- constraints,
- non-goals,
- open questions.

## Phase 2: Repository understanding

Inspect only enough repository context to plan accurately. Prefer read-only commands:

```bash
git status --short
find . -maxdepth 3 -type f | sed 's#^./##' | sort | head -200
```

Use targeted reads after identifying likely components. Do not run expensive tests during planning unless the user asks.

## Phase 3: Discussion

Ask questions when missing information changes the implementation path. Do not ask questions whose answers can be safely inferred from repository conventions.

## Phase 4: Plan

Write `plan.md` with:

- summary,
- goals and non-goals,
- files/components likely to change,
- implementation sequence,
- risks and mitigations,
- test strategy,
- rollback strategy,
- explicit assumptions.

## Phase 5: Acceptance

Write `acceptance.md` as checkable criteria. Criteria must be observable.

Good:

- "`Ctrl+Z` restores the previous editor value in the browser test."

Bad:

- "Undo feels good."

## Phase 6: Beads task graph

Write `bd-plan.md` and add task definitions to the handoff manifest. Use small tasks that a worker can complete independently.

`bd-plan.md`, `bd.epic.title`, `bd.epic.description`, `bd.tasks[].title`, `bd.tasks[].description`, and `bd.tasks[].acceptance_criteria` are human-facing generated prose. Write them in the requested language so that later `materialize-bd` creates Beads issues in that language.

Each task needs:

- clear title,
- description,
- acceptance criteria,
- dependencies by task key,
- labels including `humanize-flow` and the slug.

## Phase 7: Handoff

Write `.humanize-flow/handoffs/<slug>.json` with state `draft` and approval `pending` unless the user has explicitly approved the plan.
