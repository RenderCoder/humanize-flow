# Discussion Policy for Existing Beads Tasks

The user has already created a task, so do not ask them to restate everything. Ask only for details that materially affect implementation or review.

## Ask before finalizing when ambiguity affects

- public API or data model
- database migrations or irreversible data changes
- authentication, authorization, privacy, or security
- user-visible UX behavior
- external service contracts
- testing strategy for risky behavior
- whether a broad task should be split
- acceptance criteria that cannot be inferred from the task

## Do not ask when

- the missing detail is low risk and can be recorded as an assumption
- the repository already answers the question clearly
- the task wording and existing code imply a standard implementation

## Interaction shape

When discussion is needed, first summarize the task in three buckets:

```text
Explicit in bd:
Inferred from repository:
Needs confirmation:
```

Then ask the smallest set of questions needed to produce a reliable plan.

## Non-interactive behavior

If running through `humanize-flow plan-from-bd` and high-impact ambiguity remains, write:

```text
docs/humanize-flow/<slug>/questions.md
```

Stop without writing an executable handoff. The summary should tell the user to rerun the skill interactively or update the Beads task with the missing details.
